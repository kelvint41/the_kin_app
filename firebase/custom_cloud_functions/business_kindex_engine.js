const functions = require("firebase-functions");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

// Mirrors lib/custom_code/actions/calculate_real_time_kindex.dart exactly.
// That Dart function is now dead (its only call site never persisted the
// result) - this is the live port. Business kindex tiers/deltas aren't
// config-driven like the UserEngagementEvents weights, so keep this in
// sync by hand if the Dart formula ever changes.
const STANDARD_BASELINE = 500;
const PREMIUM_BASELINE = 850;
const MINIMUM_SCORE = 0;
const STANDARD_MAXIMUM_SCORE = 750;
const PREMIUM_MAXIMUM_SCORE = 900;

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

function calculateRealTimeKindex(currentScore, starRating, isPremiumBusiness) {
  const baseline = isPremiumBusiness ? PREMIUM_BASELINE : STANDARD_BASELINE;
  const maximumScore = isPremiumBusiness
    ? PREMIUM_MAXIMUM_SCORE
    : STANDARD_MAXIMUM_SCORE;

  // Treat 0 as "no score set yet" and apply the baseline.
  const score = currentScore === 0
    ? baseline
    : clamp(currentScore, MINIMUM_SCORE, maximumScore);

  let scoreChange;
  switch (starRating) {
    case 5:
      scoreChange = 15;
      break;
    case 4:
      scoreChange = 5;
      break;
    case 2:
      scoreChange = -5;
      break;
    case 1:
      scoreChange = -15;
      break;
    default:
      scoreChange = 0; // 3-star (or anything unexpected) is neutral
  }

  return clamp(score + scoreChange, MINIMUM_SCORE, maximumScore);
}

exports.processBusinessReview = functions.firestore
  .document("reviews/{reviewId}")
  .onCreate(async (snapshot) => {
    const db = admin.firestore();
    const reviewRef = snapshot.ref;

    await db.runTransaction(async (tx) => {
      const reviewSnap = await tx.get(reviewRef);
      const review = reviewSnap.data();

      // Cloud Functions triggers are at-least-once: the same review can be
      // redelivered after a crash or timeout. `reviews` docs have no
      // client-settable `status` field (unlike UserEngagementEvents'
      // "pending"), so its mere presence - only ever written by this
      // function - is what marks a review as already handled, making
      // reprocessing a safe no-op instead of a double score adjustment.
      if (!review || review.status) {
        return;
      }

      const businessRef = review.business_ref;
      if (!businessRef) {
        tx.update(reviewRef, {
          status: "rejected",
          error: "missing business_ref",
          processed_at: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
      }

      if (typeof review.rating !== "number") {
        tx.update(reviewRef, {
          status: "rejected",
          error: `invalid rating: ${review.rating}`,
          processed_at: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
      }

      const businessSnap = await tx.get(businessRef);
      if (!businessSnap.exists) {
        tx.update(reviewRef, {
          status: "rejected",
          error: "business not found",
          processed_at: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
      }

      const business = businessSnap.data();
      const currentScore = business.kindex_score || 0;
      const starRating = Math.round(review.rating);

      const newScore = calculateRealTimeKindex(
        currentScore,
        starRating,
        business.is_premium === true,
      );

      // kindex_velocity is intentionally left untouched here - a real
      // velocity metric (e.g. EWMA over daily score deltas) is a separate,
      // not-yet-designed task; writing a placeholder sign-based value would
      // look more meaningful than it is.
      tx.update(businessRef, {
        kindex_score: newScore,
        last_kindex_review_id: reviewRef.id,
      });

      tx.update(reviewRef, {
        status: "processed",
        processed_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
  });

exports.calculateRealTimeKindex = calculateRealTimeKindex;
