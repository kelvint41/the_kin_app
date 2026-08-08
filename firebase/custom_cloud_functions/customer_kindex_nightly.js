const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

const dynamics = require("./kindex_scoring_dynamics.js");
const { applyNightlyMovement } = dynamics;

const WINDOW_DAYS = 7;

// Mirrors the business side's tier-baseline model (business_kindex_nightly.js
// STANDARD_BASELINE/PREMIUM_BASELINE = 500/850) rather than the old
// no-baseline-at-all customer behavior, where kindex_engine.js began a new
// customer at `scoreData.score || 0` and nothing ever floored or capped it -
// which is why customers could show single- and double-digit scores.
const CUSTOMER_BASELINE = 300;
const CUSTOMER_MAX = 850;

const WEIGHTS_DOC = { collection: "kindex_config", doc: "scoring_weights" };
const WEIGHTS_CACHE_TTL_MS = 5 * 60 * 1000;

// Community Impact & Spend Tracker feeds ranking, not the public score
// verbatim - see spendBonusForWindow's doc comment for the privacy
// constraint this shape exists to satisfy.
const SPEND_BONUS_CAP = 40;
const SPEND_BONUS_DOLLARS_PER_POINT = 25;

/**
 * Converts one customer's spend_logs total for this window into a ranking
 * bonus, folded into `qualifying.total` alongside engagement points below.
 *
 * Product requirement: a customer's spend total must never be visible to
 * anyone but themselves - not on the KINDEX leaderboard, not to another
 * customer, not to admin tooling (see firestore.rules' spend_logs match
 * block). It should still move their rank, though. Those two constraints
 * are why this can't just add the raw dollar amount as points:
 *
 * - Capped at SPEND_BONUS_CAP, so no amount of spending buys an unlimited
 *   score - it's a bounded nudge alongside engagement, the way one review
 *   or one check-in is, not a way to outright purchase rank.
 * - Bucketed into $25 increments via Math.floor, not applied continuously
 *   - so a score can never be inverted back into an exact dollar figure.
 *   Every amount in a $25 band produces the identical bonus, and the
 *   score is additionally the sum of this bonus with engagement points
 *   the observer has no way to separate out.
 *
 * Windowed the same WINDOW_DAYS as engagement events, and folded into the
 * same target-seeking/decay machinery below (applyNightlyMovement) rather
 * than written as a separate permanent addition - so a burst of spending
 * nudges this week's target exactly like a burst of engagement does, and
 * fades the same way if the customer goes quiet, instead of permanently
 * inflating the baseline off one purchase.
 */
function spendBonusForWindow(totalSpentThisWindow) {
  if (!(totalSpentThisWindow > 0)) return 0;
  return Math.min(
    SPEND_BONUS_CAP,
    Math.floor(totalSpentThisWindow / SPEND_BONUS_DOLLARS_PER_POINT),
  );
}

let cachedWeights = null;
let cachedWeightsAt = 0;

async function getScoringWeights(db) {
  const now = Date.now();
  if (cachedWeights && now - cachedWeightsAt < WEIGHTS_CACHE_TTL_MS) {
    return cachedWeights;
  }
  const snap = await db
    .collection(WEIGHTS_DOC.collection)
    .doc(WEIGHTS_DOC.doc)
    .get();
  cachedWeights = snap.exists ? snap.data() : {};
  cachedWeightsAt = now;
  return cachedWeights;
}

/** Test hook. */
function resetWeightsCache() {
  cachedWeights = null;
  cachedWeightsAt = 0;
}

/**
 * Reduces one customer's engagement events in the window to the points that
 * actually count.
 *
 * Dedup rule, per the July 26 product decision: engaging with several
 * different businesses should be worth more than repeatedly engaging with
 * one, because broad community engagement is the goal. So events carrying a
 * `business_ref` are grouped per business and only that business's
 * highest-weighted event counts - the direct mirror of the business side's
 * "highest review per customer per week".
 *
 * Events with no `business_ref` (app-level actions like `post` and
 * `share_app`) are deduped per `event_type` instead. That's an extension
 * beyond the letter of the spec, which only addresses per-business dedup:
 * without it, the highest-weighted untargeted event - `post`, at 10 points -
 * could be farmed without limit by posting repeatedly, which would reopen
 * on the customer side exactly the hole this whole redesign closes on the
 * business side.
 */
function qualifyingPointsForCustomer(events, weights) {
  const bestPerBusiness = new Map();
  const bestPerUntargetedType = new Map();

  for (const event of events) {
    const points = weights[event.event_type];
    if (typeof points !== "number") continue;

    if (event.business_ref) {
      const key = event.business_ref.id;
      const current = bestPerBusiness.get(key);
      if (current === undefined || points > current) {
        bestPerBusiness.set(key, points);
      }
    } else {
      const key = event.event_type;
      const current = bestPerUntargetedType.get(key);
      if (current === undefined || points > current) {
        bestPerUntargetedType.set(key, points);
      }
    }
  }

  let total = 0;
  for (const points of bestPerBusiness.values()) total += points;
  for (const points of bestPerUntargetedType.values()) total += points;
  return {
    total,
    distinctBusinesses: bestPerBusiness.size,
    countedEvents: bestPerBusiness.size + bestPerUntargetedType.size,
  };
}

async function recomputeAll(db, now) {
  const [config, weights] = await Promise.all([
    dynamics.getScoringDynamics(db),
    getScoringWeights(db),
  ]);

  const windowStart = admin.firestore.Timestamp.fromMillis(
    now - WINDOW_DAYS * 24 * 60 * 60 * 1000,
  );

  // Only events the reactive engine already accepted count - it remains the
  // validator (rejecting unknown event types, stamping points_awarded);
  // this job just owns the score.
  const eventsSnap = await db
    .collection("UserEngagementEvents")
    .where("created_at", ">=", windowStart)
    .get();

  const eventsByUser = new Map();
  for (const doc of eventsSnap.docs) {
    const data = doc.data();
    if (!data.user_ref || data.status !== "processed") continue;
    const key = data.user_ref.id;
    if (!eventsByUser.has(key)) eventsByUser.set(key, []);
    eventsByUser.get(key).push(data);
  }

  // Admin SDK read - bypasses firestore.rules' owner-only restriction on
  // spend_logs by design, the same way this whole job already reads every
  // customer's UserEngagementEvents. Nothing derived from this leaves the
  // function except the bucketed, capped bonus computed below; the raw
  // per-user totals here never get written anywhere.
  const spendSnap = await db
    .collection("spend_logs")
    .where("spent_at", ">=", windowStart)
    .get();

  const spendTotalByUser = new Map();
  for (const doc of spendSnap.docs) {
    const data = doc.data();
    if (!data.user_ref || typeof data.amount !== "number") continue;
    const key = data.user_ref.id;
    spendTotalByUser.set(key, (spendTotalByUser.get(key) || 0) + data.amount);
  }

  // Every customer who already has a score doc must be visited, not just
  // those active this window - otherwise inactive customers would never
  // decay.
  const scoresSnap = await db.collection("KindexScores").get();

  let updated = 0;
  let batch = db.batch();
  let batchCount = 0;

  const frozen = config.customer_scoring_frozen;

  for (const scoreDoc of scoresSnap.docs) {
    const scoreData = scoreDoc.data();
    const events = eventsByUser.get(scoreDoc.id) || [];
    const qualifying = qualifyingPointsForCustomer(events, weights);
    const spendBonus = spendBonusForWindow(spendTotalByUser.get(scoreDoc.id) || 0);
    // Folded straight into the same total that seeds the target below -
    // see spendBonusForWindow's doc comment. hasActivity/countedEvents
    // deliberately does NOT include spend: a spend-only week still moves
    // the target upward, but it isn't "activity" for the
    // inactivity-decay clock, which stays keyed to engagement events the
    // same as before this change.
    qualifying.total += spendBonus;

    const scoreBefore =
      typeof scoreData.score === "number" ? scoreData.score : CUSTOMER_BASELINE;

    if (frozen) {
      // Every customer sits at exactly CUSTOMER_BASELINE, real activity
      // this window included - not just floored, held. No history row: a
      // reset to a fixed point isn't a movement worth charting alongside
      // real target-seeking/decay once unfrozen.
      if (scoreBefore !== CUSTOMER_BASELINE) {
        batch.update(scoreDoc.ref, {
          score: CUSTOMER_BASELINE,
          is_trending_up: null,
          last_recomputed_at: admin.firestore.FieldValue.serverTimestamp(),
        });
        batchCount += 1;
        updated += 1;
        if (batchCount >= 400) {
          await batch.commit();
          batch = db.batch();
          batchCount = 0;
        }
      }
      continue;
    }

    const outcome = applyNightlyMovement({
      hasActivity: qualifying.countedEvents > 0,
      target: Math.min(
        CUSTOMER_MAX,
        Math.max(CUSTOMER_BASELINE, qualifying.total),
      ),
      scoreBefore,
      floor: CUSTOMER_BASELINE,
      lastActivityMs: scoreData.last_activity_at
        ? scoreData.last_activity_at.toMillis()
        : null,
      decayedThroughWeek: scoreData.decayed_through_week || 0,
      now,
      config,
      prefix: "customer",
    });

    const update = {
      score: outcome.scoreAfter,
      // Now reflects real score movement rather than the sign of whichever
      // event happened to be processed last, which is what the reactive
      // engine used to set.
      is_trending_up: outcome.scoreAfter >= scoreBefore,
      inactivity_weeks: outcome.inactivityWeeks,
      decayed_through_week: outcome.decayedThroughWeek,
      qualifying_event_count: qualifying.countedEvents,
      distinct_businesses_engaged: qualifying.distinctBusinesses,
      last_recomputed_at: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (outcome.hasActivity || !scoreData.last_activity_at) {
      update.last_activity_at = admin.firestore.Timestamp.fromMillis(now);
    }

    batch.update(scoreDoc.ref, update);
    batchCount += 1;

    batch.set(
      db
        .collection(dynamics.HISTORY_COLLECTION)
        .doc(dynamics.historyDocId("customer", scoreDoc.id, now)),
      {
        entity_type: "customer",
        user_ref: scoreData.user_ref || null,
        score_before: scoreBefore,
        score_after: outcome.scoreAfter,
        target_score: outcome.target,
        capped: outcome.capped,
        decay_applied: outcome.decayApplied,
        inactivity_weeks: outcome.inactivityWeeks,
        qualifying_event_count: qualifying.countedEvents,
        distinct_businesses_engaged: qualifying.distinctBusinesses,
        recorded_at: admin.firestore.FieldValue.serverTimestamp(),
      },
    );
    batchCount += 1;

    if (outcome.scoreAfter !== scoreData.score) updated += 1;

    if (batchCount >= 400) {
      await batch.commit();
      batch = db.batch();
      batchCount = 0;
    }
  }

  if (batchCount > 0) {
    await batch.commit();
  }

  return { customers: scoresSnap.size, updated };
}

// 2:30am America/Chicago - half an hour after the business job, so the two
// don't contend for Firestore throughput on the same instant.
exports.recomputeCustomerKindexScores = onSchedule(
  {
    schedule: "30 2 * * *",
    timeZone: "America/Chicago",
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async () => {
    const db = admin.firestore();
    const result = await recomputeAll(db, Date.now());
    console.log(
      `Customer Kindex nightly recompute: ${result.updated} of ${result.customers} customers updated.`,
    );
  },
);

exports._internals = {
  qualifyingPointsForCustomer,
  recomputeAll,
  resetWeightsCache,
  CUSTOMER_BASELINE,
  CUSTOMER_MAX,
  WINDOW_DAYS,
};
