const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

const dynamics = require("./kindex_scoring_dynamics.js");
const { applyNightlyMovement } = dynamics;

const VISITS_COLLECTION = "uservisits";
const WINDOW_DAYS = 7;

// Same tier baselines/ceilings and star deltas as
// lib/custom_code/actions/calculate_real_time_kindex.dart. Kept in sync by
// hand; business_kindex_engine.js carries the same constants.
const STANDARD_BASELINE = 500;
const PREMIUM_BASELINE = 850;
const MINIMUM_SCORE = 0;
const STANDARD_MAXIMUM_SCORE = 750;
const PREMIUM_MAXIMUM_SCORE = 900;

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

function starDelta(starRating) {
  switch (starRating) {
    case 5:
      return 15;
    case 4:
      return 5;
    case 2:
      return -5;
    case 1:
      return -15;
    default:
      return 0; // 3-star (or anything unexpected) is neutral
  }
}

/**
 * Recomputes a score from scratch for one business.
 *
 * Note this is a real semantic change from the old per-review engine: the
 * score is now a pure function of the trailing 7 days of qualifying
 * reviews, so it starts from the tier baseline every run. A business with
 * no qualifying reviews in the window sits exactly at its baseline rather
 * than retaining points earned earlier - which is what "recompute from
 * scratch" in the spec requires, but it does mean scores decay back toward
 * baseline rather than accumulating indefinitely.
 *
 * @param {Array<number>} qualifyingRatings one rating per customer -
 *   already reduced to each customer's highest in the window.
 */
function computeScore(qualifyingRatings, isPremiumBusiness) {
  const baseline = isPremiumBusiness ? PREMIUM_BASELINE : STANDARD_BASELINE;
  const maximumScore = isPremiumBusiness
    ? PREMIUM_MAXIMUM_SCORE
    : STANDARD_MAXIMUM_SCORE;

  let score = baseline;
  for (const rating of qualifyingRatings) {
    score += starDelta(rating);
  }
  return clamp(score, MINIMUM_SCORE, maximumScore);
}

/**
 * Reduces a business's reviews to one rating per customer: their highest
 * star rating in the window, counting only customers with a verified visit
 * to that business inside the same window.
 *
 * Grouping by customer also makes the result immune to duplicate review
 * documents for the same customer - which matters while older
 * auto-ID reviews coexist with the newer composite-ID scheme.
 */
function highestRatingPerVerifiedCustomer(
  reviews,
  verifiedUserIds,
  ownerUserId,
) {
  const byUser = new Map();
  for (const review of reviews) {
    const userRef = review.user_ref;
    if (!userRef || typeof review.rating !== "number") continue;
    // The owner's own review never counts toward their own score, even if
    // a verified visit exists for them - a visit predating the check in
    // recordVerifiedVisit, or one written back when the uservisits
    // collection was still client-writable, would otherwise let an owner
    // farm their own score. This is the authoritative gate: it decides
    // scoring directly, so it holds regardless of what the UI or the
    // check-in callable allowed earlier.
    if (ownerUserId && userRef.id === ownerUserId) continue;
    if (!verifiedUserIds.has(userRef.id)) continue;
    const rating = Math.round(review.rating);
    const current = byUser.get(userRef.id);
    if (current === undefined || rating > current) {
      byUser.set(userRef.id, rating);
    }
  }
  return [...byUser.values()];
}

function tierBaseline(isPremium) {
  return isPremium ? PREMIUM_BASELINE : STANDARD_BASELINE;
}

async function recomputeAll(db, now) {
  const config = await dynamics.getScoringDynamics(db);
  const windowStart = admin.firestore.Timestamp.fromMillis(
    now - WINDOW_DAYS * 24 * 60 * 60 * 1000,
  );

  // Pull the window's reviews and visits once and bucket them in memory,
  // rather than issuing two queries per business. At the current scale
  // (hundreds of businesses) that's the difference between a handful of
  // reads and a thousand-plus.
  const [reviewsSnap, visitsSnap] = await Promise.all([
    db.collection("reviews").where("timestamp", ">=", windowStart).get(),
    db
      .collection(VISITS_COLLECTION)
      .where("visit_timestamp", ">=", windowStart)
      .get(),
  ]);

  const reviewsByBusiness = new Map();
  for (const doc of reviewsSnap.docs) {
    const data = doc.data();
    if (!data.business_ref) continue;
    const key = data.business_ref.id;
    if (!reviewsByBusiness.has(key)) reviewsByBusiness.set(key, []);
    reviewsByBusiness.get(key).push(data);
  }

  const verifiedByBusiness = new Map();
  for (const doc of visitsSnap.docs) {
    const data = doc.data();
    if (!data.business_ref || !data.user_ref) continue;
    const key = data.business_ref.id;
    if (!verifiedByBusiness.has(key)) verifiedByBusiness.set(key, new Set());
    verifiedByBusiness.get(key).add(data.user_ref.id);
  }

  const businessesSnap = await db.collection("businesses").get();

  let updated = 0;
  let batch = db.batch();
  let batchCount = 0;

  for (const businessDoc of businessesSnap.docs) {
    const business = businessDoc.data();
    const reviews = reviewsByBusiness.get(businessDoc.id) || [];
    const verified = verifiedByBusiness.get(businessDoc.id) || new Set();

    const ratings = highestRatingPerVerifiedCustomer(
      reviews,
      verified,
      business.owner_ref ? business.owner_ref.id : null,
    );

    const isPremium = business.is_premium === true;
    const baseline = tierBaseline(isPremium);
    const scoreBefore =
      typeof business.kindex_score === "number" && business.kindex_score > 0
        ? business.kindex_score
        : baseline;

    const outcome = applyNightlyMovement({
      hasActivity: ratings.length > 0,
      target: computeScore(ratings, isPremium),
      scoreBefore,
      floor: baseline,
      lastActivityMs: business.kindex_last_activity_at
        ? business.kindex_last_activity_at.toMillis()
        : null,
      decayedThroughWeek: business.kindex_decayed_through_week || 0,
      now,
      config,
      prefix: "business",
    });

    const update = {
      kindex_score: outcome.scoreAfter,
      kindex_inactivity_weeks: outcome.inactivityWeeks,
      kindex_decayed_through_week: outcome.decayedThroughWeek,
      kindex_qualifying_review_count: ratings.length,
      kindex_last_recomputed_at: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (outcome.hasActivity) {
      update.kindex_last_activity_at =
        admin.firestore.Timestamp.fromMillis(now);
    } else if (!business.kindex_last_activity_at) {
      // First run for a business we've never seen active: start the clock
      // now rather than treating "no record" as infinite inactivity, which
      // would decay every pre-existing business on the first deploy.
      update.kindex_last_activity_at =
        admin.firestore.Timestamp.fromMillis(now);
    }

    // kindex_velocity remains deliberately untouched.
    batch.update(businessDoc.ref, update);
    batchCount += 1;

    batch.set(
      db
        .collection(dynamics.HISTORY_COLLECTION)
        .doc(dynamics.historyDocId("business", businessDoc.id, now)),
      {
        entity_type: "business",
        business_ref: businessDoc.ref,
        score_before: scoreBefore,
        score_after: outcome.scoreAfter,
        target_score: outcome.target,
        capped: outcome.capped,
        decay_applied: outcome.decayApplied,
        inactivity_weeks: outcome.inactivityWeeks,
        qualifying_review_count: ratings.length,
        verified_visit_count: verified.size,
        recorded_at: admin.firestore.FieldValue.serverTimestamp(),
      },
    );
    batchCount += 1;

    if (outcome.scoreAfter !== business.kindex_score) updated += 1;

    // Firestore caps a batch at 500 writes; each business costs two.
    if (batchCount >= 400) {
      await batch.commit();
      batch = db.batch();
      batchCount = 0;
    }
  }

  if (batchCount > 0) {
    await batch.commit();
  }

  return { businesses: businessesSnap.size, updated };
}

// 2:00 AM America/Chicago - the low-traffic window suggested in the spec,
// matching the San Antonio launch market. Cloud Scheduler handles DST.
exports.recomputeBusinessKindexScores = onSchedule(
  {
    schedule: "0 2 * * *",
    timeZone: "America/Chicago",
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async () => {
    const db = admin.firestore();
    const result = await recomputeAll(db, Date.now());
    console.log(
      `Kindex nightly recompute: ${result.updated} of ${result.businesses} businesses updated.`,
    );
  },
);

// Exported for tests and for manual invocation from a maintenance script.
exports._internals = {
  computeScore,
  starDelta,
  highestRatingPerVerifiedCustomer,
  recomputeAll,
  WINDOW_DAYS,
};
