const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

const dynamics = require("./kindex_scoring_dynamics.js");
const { applyNightlyMovement } = dynamics;

const WINDOW_DAYS = 7;

// Customers have no tier system and no starting baseline - kindex_engine.js
// has always begun a new customer at `scoreData.score || 0` - so the decay
// floor is 0, not the business side's 500/850.
const CUSTOMER_BASELINE = 0;

const WEIGHTS_DOC = { collection: "kindex_config", doc: "scoring_weights" };
const WEIGHTS_CACHE_TTL_MS = 5 * 60 * 1000;

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

  // Every customer who already has a score doc must be visited, not just
  // those active this window - otherwise inactive customers would never
  // decay.
  const scoresSnap = await db.collection("KindexScores").get();

  let updated = 0;
  let batch = db.batch();
  let batchCount = 0;

  for (const scoreDoc of scoresSnap.docs) {
    const scoreData = scoreDoc.data();
    const events = eventsByUser.get(scoreDoc.id) || [];
    const qualifying = qualifyingPointsForCustomer(events, weights);

    const scoreBefore =
      typeof scoreData.score === "number" ? scoreData.score : CUSTOMER_BASELINE;

    const outcome = applyNightlyMovement({
      hasActivity: qualifying.countedEvents > 0,
      target: Math.max(CUSTOMER_BASELINE, qualifying.total),
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
  WINDOW_DAYS,
};
