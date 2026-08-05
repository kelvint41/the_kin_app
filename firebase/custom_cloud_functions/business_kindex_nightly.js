const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

const dynamics = require("./kindex_scoring_dynamics.js");
const { applyNightlyMovement } = dynamics;

const VISITS_COLLECTION = "uservisits";
const POSTS_COLLECTION = "exchange_posts";
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

function tierMaximum(isPremium) {
  return isPremium ? PREMIUM_MAXIMUM_SCORE : STANDARD_MAXIMUM_SCORE;
}

/**
 * Buckets exchange_posts by author into the distinct calendar days they
 * posted, within whatever window the caller already filtered to. Grouped
 * by author (user_ref), not by business_ref, because Active Poster rewards
 * a business owner's own marketing activity in the Exchange, not being
 * tagged in someone else's post - so a post counts even if the owner
 * didn't tag this business on it.
 *
 * Day boundaries are UTC calendar days (same convention as historyDocId),
 * not America/Chicago - acceptable skew for a 3-day/7-day threshold,
 * consistent with the rest of this file's date handling.
 */
function distinctPostDaysByAuthor(posts) {
  const byAuthor = new Map();
  for (const post of posts) {
    const userRef = post.user_ref;
    if (!userRef || !post.timestamp) continue;
    const day = post.timestamp.toDate().toISOString().slice(0, 10);
    if (!byAuthor.has(userRef.id)) byAuthor.set(userRef.id, new Set());
    byAuthor.get(userRef.id).add(day);
  }
  return byAuthor;
}

/**
 * Adds the active-poster bonus to a computed target score, re-clamped to
 * the same tier ceiling computeScore() uses. Kept separate from
 * computeScore() so the two stay independently testable: one is "what do
 * qualifying reviews alone produce", the other is "what does that become
 * once posting activity is folded in".
 */
function applyActivePosterBonus(score, isActivePoster, bonusAmount, maximumScore) {
  if (!isActivePoster) return score;
  return clamp(score + bonusAmount, MINIMUM_SCORE, maximumScore);
}

async function recomputeAll(db, now) {
  const config = await dynamics.getScoringDynamics(db);
  const windowStart = admin.firestore.Timestamp.fromMillis(
    now - WINDOW_DAYS * 24 * 60 * 60 * 1000,
  );

  // Pull the window's reviews, visits, and posts once and bucket them in
  // memory, rather than issuing per-business queries. At the current scale
  // (hundreds of businesses) that's the difference between a handful of
  // reads and a thousand-plus.
  const [reviewsSnap, visitsSnap, postsSnap] = await Promise.all([
    db.collection("reviews").where("timestamp", ">=", windowStart).get(),
    db
      .collection(VISITS_COLLECTION)
      .where("visit_timestamp", ">=", windowStart)
      .get(),
    db
      .collection(POSTS_COLLECTION)
      .where("timestamp", ">=", windowStart)
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

  const postDaysByAuthor = distinctPostDaysByAuthor(
    postsSnap.docs.map((doc) => doc.data()),
  );

  const businessesSnap = await db.collection("businesses").get();

  let updated = 0;
  let batch = db.batch();
  let batchCount = 0;

  for (const businessDoc of businessesSnap.docs) {
    // Opt-out for businesses that shouldn't carry a Kindex at all - the
    // operator's own business, which isn't competing in the Quest and whose
    // score would just be noise on a leaderboard it shouldn't be on. Only an
    // explicit `false` opts out, so every existing business is unaffected.
    if (businessDoc.data().kindex_enabled === false) continue;
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

    // Active Poster Bonus - see kindex_scoring_dynamics.js DEFAULTS for the
    // threshold/amount rationale. Counted against the owner's own posts
    // only (not posts merely tagged to this business by someone else), so
    // this rewards the owner's own marketing activity in the Exchange.
    const ownerId = business.owner_ref ? business.owner_ref.id : null;
    const postDays = ownerId ? postDaysByAuthor.get(ownerId)?.size || 0 : 0;
    const activePoster = postDays >= config.business_active_poster_threshold_days;
    const target = applyActivePosterBonus(
      computeScore(ratings, isPremium),
      activePoster,
      config.business_active_poster_bonus,
      tierMaximum(isPremium),
    );

    const outcome = applyNightlyMovement({
      // A business with zero qualifying reviews but a genuine posting
      // streak must still count as active, or the bonus gets defeated by
      // the decay branch the same night it applies - decay and
      // move-toward are deliberately exclusive (see
      // applyNightlyMovement's doc comment).
      hasActivity: ratings.length > 0 || activePoster,
      target,
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
      // Audit/debug fields only - recomputed fresh from exchange_posts
      // every run, never read back in as an input.
      kindex_active_poster_bonus_applied: activePoster,
      kindex_active_poster_days: postDays,
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
        active_poster_bonus_applied: activePoster,
        active_poster_days: postDays,
        active_poster_bonus_points: activePoster
          ? config.business_active_poster_bonus
          : 0,
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
  distinctPostDaysByAuthor,
  applyActivePosterBonus,
  recomputeAll,
  WINDOW_DAYS,
};
