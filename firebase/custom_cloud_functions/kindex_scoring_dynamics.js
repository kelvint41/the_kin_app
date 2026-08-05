const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

// Smoothing and decay parameters, shared by the business and customer
// nightly jobs. Stored in Firestore rather than as constants so they can be
// tuned post-launch without a redeploy - the same pattern as
// kindex_config/visit_verification and kindex_config/scoring_weights.
const CONFIG_DOC = { collection: "kindex_config", doc: "scoring_dynamics" };
const CONFIG_CACHE_TTL_MS = 5 * 60 * 1000;

const DAY_MS = 24 * 60 * 60 * 1000;
const WEEK_MS = 7 * DAY_MS;

// Business and customer caps are separate keys even though they default to
// the same number, because the product owner hasn't decided whether they
// should move together.
const DEFAULTS = {
  business_max_nightly_change: 20,
  customer_max_nightly_change: 20,
  business_decay_week1: 10,
  business_decay_week2: 20,
  business_decay_week3plus: 25,
  customer_decay_week1: 10,
  customer_decay_week2: 20,
  customer_decay_week3plus: 25,
  // When false, decay holds at the week-3 rate instead of continuing to
  // escalate - the spec's default for simplicity.
  business_decay_escalates: false,
  customer_decay_escalates: false,
  // Pre-launch: every customer sits at exactly CUSTOMER_BASELINE
  // (customer_kindex_nightly.js) with no movement in either direction,
  // real activity included. Flip to false in kindex_config/scoring_dynamics
  // at launch to turn normal target-seeking/decay back on - no redeploy
  // needed, same live-tunable pattern as every other value here.
  customer_scoring_frozen: true,
  // Active Poster Bonus - business-only (see business_kindex_nightly.js).
  // Customer KINDEX is frozen pre-launch (customer_scoring_frozen above),
  // so an equivalent customer-side bonus would ship invisible; businesses
  // are live today. Distinct-day dedup, not raw post count, mirrors the
  // anti-farming pattern already used for reviews (one rating per verified
  // customer) - reposting the same day repeatedly must not multiply the
  // bonus. 10 points is half of business_max_nightly_change (20) so it
  // can't monopolize a night's movement budget alongside real review
  // activity, and sits between a single 4-star (+5) and 5-star (+15)
  // delta so posting is meaningful but never outweighs real customer
  // feedback.
  business_active_poster_threshold_days: 3,
  business_active_poster_bonus: 10,
};

let cached = null;
let cachedAt = 0;

function coerceNumber(value, fallback) {
  return typeof value === "number" && Number.isFinite(value) && value >= 0
    ? value
    : fallback;
}

async function getScoringDynamics(db) {
  const now = Date.now();
  if (cached && now - cachedAt < CONFIG_CACHE_TTL_MS) {
    return cached;
  }
  const snap = await db
    .collection(CONFIG_DOC.collection)
    .doc(CONFIG_DOC.doc)
    .get();
  const data = snap.exists ? snap.data() : {};
  const merged = {};
  for (const [key, fallback] of Object.entries(DEFAULTS)) {
    merged[key] =
      typeof fallback === "boolean"
        ? typeof data[key] === "boolean"
          ? data[key]
          : fallback
        : coerceNumber(data[key], fallback);
  }
  cached = merged;
  cachedAt = now;
  return cached;
}

/** Test hook - drops the in-process config cache. */
function resetConfigCache() {
  cached = null;
  cachedAt = 0;
}

/**
 * Moves `current` toward `target` by at most `maxChange` points.
 *
 * This is what stops a single very active day from slamming a score to its
 * ceiling overnight: a grand opening with 50 verified 5-star check-ins is
 * real engagement, not manipulation, but the product wants it to read as a
 * climbing ticker rather than an instant jump.
 */
function moveToward(current, target, maxChange) {
  const delta = target - current;
  if (Math.abs(delta) <= maxChange) return target;
  return current + Math.sign(delta) * maxChange;
}

/**
 * Completed consecutive inactive weeks, given when qualifying activity was
 * last seen. 0 means "active within the last 7 days".
 */
function inactiveWeeks(lastActivityMs, nowMs) {
  if (!lastActivityMs) return 0;
  const elapsed = nowMs - lastActivityMs;
  if (elapsed < WEEK_MS) return 0;
  return Math.floor(elapsed / WEEK_MS);
}

/**
 * The decay charged for entering week `week` of inactivity (1-indexed).
 *
 * Note this is a per-week charge, not per-night. The job runs nightly but
 * the spec's amounts are weekly, so callers apply this only on the run
 * where the week counter advances - see `decayForNewWeeks`.
 */
function decayForWeek(week, config, prefix) {
  if (week <= 0) return 0;
  if (week === 1) return config[`${prefix}_decay_week1`];
  if (week === 2) return config[`${prefix}_decay_week2`];
  const base = config[`${prefix}_decay_week3plus`];
  if (!config[`${prefix}_decay_escalates`]) return base;
  // Escalating variant: keep stepping by the same increment used between
  // weeks 2 and 3, rather than inventing a new curve.
  const step = base - config[`${prefix}_decay_week2`];
  return base + step * (week - 3);
}

/**
 * Total decay owed for weeks (decayedThroughWeek, currentWeek].
 *
 * Charging per-week-crossing rather than per-night is what keeps the
 * nightly job idempotent: a second run on the same night sees
 * decayedThroughWeek === currentWeek and charges nothing.
 */
function decayForNewWeeks(decayedThroughWeek, currentWeek, config, prefix) {
  let total = 0;
  for (let week = decayedThroughWeek + 1; week <= currentWeek; week += 1) {
    total += decayForWeek(week, config, prefix);
  }
  return total;
}

/**
 * The one nightly decision, shared by the business and customer jobs:
 * either the entity had qualifying activity this window and its score moves
 * toward the computed target (capped), or it didn't and the score decays on
 * an escalating weekly schedule.
 *
 * The two branches are deliberately exclusive rather than combined - decay
 * is not folded into "move toward target" - so each is independently
 * testable and an inactive entity can't be nudged upward by a stale target.
 *
 * Floor semantics are worth being precise about: `floor` bounds *decay*
 * only. Movement toward a target may legitimately land below it, because a
 * genuinely badly-reviewed business should be able to score under its tier
 * baseline. Mere inactivity should not.
 */
function applyNightlyMovement({
  hasActivity,
  target,
  scoreBefore,
  floor,
  lastActivityMs,
  decayedThroughWeek,
  now,
  config,
  prefix,
}) {
  if (hasActivity) {
    const maxChange = config[`${prefix}_max_nightly_change`];
    const scoreAfter = moveToward(scoreBefore, target, maxChange);
    return {
      hasActivity: true,
      scoreAfter,
      target,
      capped: scoreAfter !== target,
      decayApplied: 0,
      // Any qualifying activity resets the streak immediately, and clears
      // the decay ledger so a later dry spell starts again at week 1.
      inactivityWeeks: 0,
      decayedThroughWeek: 0,
    };
  }

  const weeks = inactiveWeeks(lastActivityMs, now);
  const owed = decayForNewWeeks(decayedThroughWeek, weeks, config, prefix);
  const scoreAfter = Math.max(scoreBefore - owed, floor);
  return {
    hasActivity: false,
    scoreAfter,
    target,
    capped: false,
    decayApplied: scoreBefore - scoreAfter,
    inactivityWeeks: weeks,
    decayedThroughWeek: Math.max(decayedThroughWeek, weeks),
  };
}

/** Deterministic per-entity-per-day id, so a re-run overwrites that day's
 * row instead of appending a duplicate while still preserving prior days. */
function historyDocId(entityType, entityId, nowMs) {
  const date = new Date(nowMs).toISOString().slice(0, 10);
  return `${entityType}_${entityId}_${date}`;
}

module.exports = {
  getScoringDynamics,
  applyNightlyMovement,
  resetConfigCache,
  moveToward,
  inactiveWeeks,
  decayForWeek,
  decayForNewWeeks,
  historyDocId,
  DEFAULTS,
  DAY_MS,
  WEEK_MS,
  HISTORY_COLLECTION: "kindex_score_history",
};
