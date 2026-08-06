const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}
const { createNotification } = require("./notifications.js");

// The collection is `uservisits` (not `user_visits`) - that's the name
// FlutterFlow generated and what UservisitsRecord binds to in the Dart
// schema.
const VISITS_COLLECTION = "uservisits";
const CONFIG_DOC = { collection: "kindex_config", doc: "visit_verification" };
const CONFIG_CACHE_TTL_MS = 5 * 60 * 1000;

const DEFAULT_RADIUS_METERS = 100;
// A second check-in inside this window is treated as the same visit and
// reuses the existing document, so tapping the button repeatedly can't
// inflate the visit count.
const DEFAULT_DEDUP_WINDOW_MS = 60 * 60 * 1000;

// Rare/Hidden Gem spots are disproportionately food trucks and pop-ups -
// mobile, often parked closer to other storefronts than a fixed location
// would be, so the standard 100m radius is too loose to confirm someone is
// actually AT the truck rather than just nearby. Tighter for both rarity
// tiers alike; the multiplier (not the geofence) is what scales with
// rarity.
const RARE_RADIUS_METERS = 20;

// Base scavenger points for a verified check-in, before the business's own
// points_multiplier is applied (1x Standard, 3x Rare, 5x Hidden Gem by
// convention - see kScavengerPointsMultiplier in lib/services/scavenger_hunt.dart).
const BASE_CHECKIN_POINTS = 10;

// A business the community hasn't verified yet renders as the amber '?'
// "mystery" pin on the map - checking in there for the first time pays a
// random amount in this range instead of the deterministic rarity formula,
// so it reads as an actual surprise. Floor matches a Standard check-in (10)
// so a mystery find is never worth less than a known business; ceiling
// (50) sits above every rarity tier's typical payout so it's a genuine
// prize, not a coin flip that might undershoot a sure thing.
const MYSTERY_MIN_POINTS = 10;
const MYSTERY_MAX_POINTS = 50;

// Paid by resolveBusinessSubmissionReview (business_discovery.js) when a
// customer-submitted business that was never on the map at all gets
// approved - the rarest, most valuable discovery a customer can make, so
// it outpays both a normal check-in and the mystery-tier range above.
// 50 guaranteed + a 25 bonus on top, kept as two named numbers rather than
// one flat 75 so the "guaranteed base + bonus" shape stays visible at a
// glance.
const UNLISTED_DISCOVERY_BASE_POINTS = 50;
const UNLISTED_DISCOVERY_BONUS_POINTS = 25;
const UNLISTED_DISCOVERY_POINTS =
  UNLISTED_DISCOVERY_BASE_POINTS + UNLISTED_DISCOVERY_BONUS_POINTS;

let cachedConfig = null;
let cachedConfigAt = 0;

// Radius lives in Firestore so it can be tuned per-market from the console
// without a redeploy - a dense downtown may need a tighter radius than a
// strip mall with a large lot. Cached per instance, same pattern as
// kindex_engine.js's scoring weights.
async function getConfig(db) {
  const now = Date.now();
  if (cachedConfig && now - cachedConfigAt < CONFIG_CACHE_TTL_MS) {
    return cachedConfig;
  }
  const snap = await db
    .collection(CONFIG_DOC.collection)
    .doc(CONFIG_DOC.doc)
    .get();
  const data = snap.exists ? snap.data() : {};
  cachedConfig = {
    radiusMeters:
      typeof data.radius_meters === "number" && data.radius_meters > 0
        ? data.radius_meters
        : DEFAULT_RADIUS_METERS,
    dedupWindowMs:
      typeof data.dedup_window_ms === "number" && data.dedup_window_ms >= 0
        ? data.dedup_window_ms
        : DEFAULT_DEDUP_WINDOW_MS,
  };
  cachedConfigAt = now;
  return cachedConfig;
}

/** Great-circle distance in metres between two {lat,lng} points. */
function haversineMeters(a, b) {
  const R = 6371000;
  const toRad = (d) => (d * Math.PI) / 180;
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.min(1, Math.sqrt(h)));
}

/**
 * Business coordinates are stored inconsistently across the collection:
 * bulk-imported records populate `business_location` (a GeoPoint), while
 * some records only carry the separate `latitude`/`longitude` numbers, and
 * `coordinates` exists as a third variant. Try them in order rather than
 * assuming one shape.
 */
function businessCoords(business) {
  const geo = business.business_location || business.coordinates;
  if (geo && typeof geo.latitude === "number" && typeof geo.longitude === "number") {
    // Reject 0,0 for GeoPoints too - it indicates unset/empty coordinates
    if (!(geo.latitude === 0 && geo.longitude === 0)) {
      return { lat: geo.latitude, lng: geo.longitude };
    }
  }
  if (
    typeof business.latitude === "number" &&
    typeof business.longitude === "number" &&
    !(business.latitude === 0 && business.longitude === 0)
  ) {
    return { lat: business.latitude, lng: business.longitude };
  }
  return null;
}

function isValidCoord(lat, lng) {
  return (
    typeof lat === "number" &&
    typeof lng === "number" &&
    Number.isFinite(lat) &&
    Number.isFinite(lng) &&
    Math.abs(lat) <= 90 &&
    Math.abs(lng) <= 180 &&
    !(lat === 0 && lng === 0) // null-island: geolocator's "no fix" value
  );
}

function isRareTier(business) {
  return business.rarity_tier === "Rare" || business.rarity_tier === "Hidden Gem";
}

/** The geofence a check-in must fall within, given the business's tier. */
function effectiveRadiusMeters(business, configRadiusMeters) {
  return isRareTier(business) ? RARE_RADIUS_METERS : configRadiusMeters;
}

/**
 * True if `nowMs` falls inside the business's published active window,
 * given as minutes-since-midnight in `nowTimeZone` (the business's local
 * time - callers pass the IANA zone the business operates in; this
 * defaults to America/Chicago, the app's only market today).
 *
 * Absent start/end (the common case - a fixed storefront with no published
 * hours on file) means "always active", same as before this field existed.
 * A window that wraps past midnight (e.g. a food truck open 22:00-02:00)
 * is supported: end < start means the window spans midnight.
 */
function isWithinActiveWindow(business, nowMs, timeZone) {
  const { active_hours_start: start, active_hours_end: end } = business;
  if (typeof start !== "number" || typeof end !== "number") {
    return true;
  }
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone,
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).formatToParts(new Date(nowMs));
  const hour = Number(parts.find((p) => p.type === "hour").value);
  const minute = Number(parts.find((p) => p.type === "minute").value);
  const nowMinutes = hour * 60 + minute;

  if (start <= end) {
    return nowMinutes >= start && nowMinutes < end;
  }
  // Wraps midnight, e.g. start=1320 (22:00), end=120 (02:00).
  return nowMinutes >= start || nowMinutes < end;
}

// The 4th Thursday of November for `year` - hand-synced with
// lib/services/seasonal_theme.dart's _thanksgivingDate, since Cloud
// Functions (Node) can't import Dart code. If this window ever changes,
// change both - same reasoning geohash.js's own header comment gives for
// its hand-synced copy of the geohash algorithm.
function thanksgivingDate(year) {
  let seen = 0;
  for (let day = 1; day <= 30; day += 1) {
    const d = new Date(Date.UTC(year, 10, day)); // month 10 = November
    if (d.getUTCDay() === 4 /* Thursday */) {
      seen += 1;
      if (seen === 4) return d;
    }
  }
  throw new Error("November always has a 4th Thursday");
}

/**
 * True if `nowMs` falls on Small Business Saturday (Thanksgiving + 2 days)
 * in UTC. Using UTC rather than the business's own timezone here - unlike
 * isWithinActiveWindow's precise open/closed check, a one-day promotional
 * window doesn't need to-the-minute accuracy per market, and the app has
 * only ever operated in one US timezone anyway.
 */
function isSmallBusinessSaturday(nowMs) {
  const now = new Date(nowMs);
  const saturday = new Date(
    thanksgivingDate(now.getUTCFullYear()).getTime() + 2 * 24 * 60 * 60 * 1000,
  );
  return (
    now.getUTCFullYear() === saturday.getUTCFullYear() &&
    now.getUTCMonth() === saturday.getUTCMonth() &&
    now.getUTCDate() === saturday.getUTCDate()
  );
}

// "Amp it up, not too much" - a flat doubling on Small Business Saturday
// specifically, the one day of the year built around supporting small
// businesses, which is the entire premise of KIN Quest. Applied uniformly
// to both branches of pointsForCheckIn below, and to the unlisted-business
// discovery bonus in business_discovery.js.
const SMALL_BUSINESS_SATURDAY_MULTIPLIER = 2;

/** Scavenger points a verified check-in at this business is worth. */
function pointsForCheckIn(business) {
  const boost = isSmallBusinessSaturday(Date.now())
    ? SMALL_BUSINESS_SATURDAY_MULTIPLIER
    : 1;

  // Mystery tier: is_verified is what colors the pin amber '?' on the map
  // (see KinQuestMapDemoWidget) - the same flag decides the payout here,
  // so the two never disagree about which businesses are "mystery" finds.
  // This is about the pin's current status, not a permanent bonus for the
  // business - once it's verified, later check-ins (by other users; see
  // the one-time-per-business rule below) use the normal formula.
  if (business.is_verified !== true) {
    const roll =
      MYSTERY_MIN_POINTS +
      Math.floor(Math.random() * (MYSTERY_MAX_POINTS - MYSTERY_MIN_POINTS + 1));
    return roll * boost;
  }
  const multiplier =
    typeof business.points_multiplier === "number" && business.points_multiplier > 0
      ? business.points_multiplier
      : 1;
  return Math.round(BASE_CHECKIN_POINTS * multiplier) * boost;
}

/**
 * Records a GPS-verified visit, which is the prerequisite for a review to
 * count toward a business's kindex_score.
 *
 * This runs server-side rather than letting the client write `uservisits`
 * directly, for two reasons: the radius check itself must not be
 * client-enforced, and the visit document carries a server timestamp the
 * caller cannot backdate. Firestore rules deny all client writes to
 * `uservisits`, so this callable is the only write path.
 *
 * IMPORTANT - what this does and does not guarantee: it verifies that the
 * *coordinates the client reported* are within the radius, and it makes
 * forging a visit require deliberately faking a location rather than just
 * POSTing a document. It cannot prove the device was physically present -
 * a mock-location provider on a rooted/jailbroken device still defeats it.
 * Unspoofable presence needs a venue-side factor (a QR code displayed
 * in-store, or a confirmed purchase). See the notes in the redesign spec.
 */
exports.recordVerifiedVisit = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const { businessRefPath, latitude, longitude } = request.data || {};
  if (typeof businessRefPath !== "string" || !businessRefPath.startsWith("businesses/")) {
    throw new HttpsError("invalid-argument", "A valid businessRefPath is required.");
  }
  if (!isValidCoord(latitude, longitude)) {
    throw new HttpsError("invalid-argument", "Valid coordinates are required.");
  }

  const db = admin.firestore();
  const config = await getConfig(db);

  const businessRef = db.doc(businessRefPath);
  const businessSnap = await businessRef.get();
  if (!businessSnap.exists) {
    throw new HttpsError("not-found", "Business not found.");
  }

  const business = businessSnap.data();

  // An owner must not be able to verify a visit to their own business:
  // that would let them self-farm, since a verified visit is exactly what
  // makes their own review count toward their own score. Enforced here as
  // well as in the UI because the UI gate is trivially bypassed by calling
  // this function directly, and again in the nightly recompute in case a
  // visit predating this check already exists.
  if (business.owner_ref && business.owner_ref.id === uid) {
    throw new HttpsError(
      "permission-denied",
      "You can't check in to your own business.",
    );
  }

  // Mobile/pop-up spots (mainly Rare and Hidden Gem food trucks) publish an
  // active window because they aren't physically present all day, unlike a
  // fixed storefront. Checked before distance: if the truck isn't there
  // right now, telling the customer how far away its parked location is
  // would be actively misleading.
  if (!isWithinActiveWindow(business, Date.now(), "America/Chicago")) {
    throw new HttpsError(
      "failed-precondition",
      "This spot isn't active right now - check back during its posted hours.",
    );
  }

  const coords = businessCoords(business);
  if (!coords) {
    // The business has no usable location on file, so proximity can't be
    // established. Fail closed - never record an unverifiable visit.
    throw new HttpsError(
      "failed-precondition",
      "This business has no location on file, so check-in isn't available yet.",
    );
  }

  const radiusMeters = effectiveRadiusMeters(business, config.radiusMeters);
  const distance = haversineMeters({ lat: latitude, lng: longitude }, coords);
  if (distance > radiusMeters) {
    throw new HttpsError(
      "out-of-range",
      `You need to be at the business to check in. You're about ${Math.round(distance)}m away.`,
    );
  }

  const userRef = db.collection("users").doc(uid);

  // Reuse a recent visit rather than stacking duplicates for one trip - and
  // deliberately award no points for it, so tapping check-in repeatedly on
  // the same trip can't farm points any more than it could already farm a
  // Kindex-eligible review.
  const cutoff = admin.firestore.Timestamp.fromMillis(
    Date.now() - config.dedupWindowMs,
  );
  const recent = await db
    .collection(VISITS_COLLECTION)
    .where("user_ref", "==", userRef)
    .where("business_ref", "==", businessRef)
    .where("visit_timestamp", ">=", cutoff)
    .limit(1)
    .get();

  if (!recent.empty) {
    return {
      visitId: recent.docs[0].id,
      alreadyCheckedIn: true,
      distanceMeters: Math.round(distance),
      rarityTier: business.rarity_tier || "Standard",
      pointsAwarded: 0,
    };
  }

  // Points are a one-time discovery bonus per business, not a per-visit
  // reward: with the Quest going national, a heavy traveler checking into
  // the same handful of businesses repeatedly (their regular coffee shop on
  // a trip they take every month, say) shouldn't out-earn someone finding
  // new businesses. Unlike the dedup check above, this has no time window -
  // any prior visit to this business at all, however old, means points were
  // already paid out once. The visit itself is still recorded every time
  // (it's still what makes a review Kindex-eligible), just with 0 points.
  const priorVisit = await db
    .collection(VISITS_COLLECTION)
    .where("user_ref", "==", userRef)
    .where("business_ref", "==", businessRef)
    .limit(1)
    .get();

  const pointsAwarded = priorVisit.empty ? pointsForCheckIn(business) : 0;
  const wasMysteryFind = priorVisit.empty && business.is_verified !== true;
  const visitRef = db.collection(VISITS_COLLECTION).doc();
  // Singleton running-totals doc, read by getOperationsStats
  // (operations_stats.js) for the Executive Dashboard's KIN Quest
  // Activity card. A maintained counter rather than summing
  // points_awarded across every uservisits row at read time - that
  // collection grows one row per check-in with no bound, same reasoning
  // kindex_score_history's own unbounded growth gets in that file's
  // header comment.
  const questStatsRef = db.collection("quest_stats").doc("totals");

  // One transaction: the visit document and the point award land together,
  // or neither does - a partial write here would either lose points a
  // customer earned or credit points for a visit that doesn't exist.
  const totalPoints = await db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    const currentPoints =
      (userSnap.exists && userSnap.data().scavenger_points) || 0;
    const newTotal = currentPoints + pointsAwarded;

    tx.set(
      visitRef,
      {
        user_ref: userRef,
        business_ref: businessRef,
        visit_timestamp: admin.firestore.FieldValue.serverTimestamp(),
        // Recorded for audit/debugging - how close the device claimed to be.
        verified_distance_meters: Math.round(distance),
        verified_radius_meters: radiusMeters,
        rarity_tier: business.rarity_tier || "Standard",
        points_awarded: pointsAwarded,
        // Whether this payout came from the mystery-tier random range
        // (is_verified was false at check-in time) rather than the
        // deterministic rarity formula - see pointsForCheckIn above.
        was_mystery_find: wasMysteryFind,
      },
    );
    tx.set(userRef, { scavenger_points: newTotal }, { merge: true });
    if (pointsAwarded > 0) {
      // Recomputed rather than threaded through pointsForCheckIn's return
      // value - pure and free to call twice, and keeps that function's
      // signature a plain number for every other caller.
      const onSmallBusinessSaturday = isSmallBusinessSaturday(Date.now());
      tx.set(
        questStatsRef,
        {
          checkin_points_total: admin.firestore.FieldValue.increment(pointsAwarded),
          checkin_count: admin.firestore.FieldValue.increment(1),
          mystery_checkin_count: admin.firestore.FieldValue.increment(
            wasMysteryFind ? 1 : 0,
          ),
          small_business_saturday_points_total: admin.firestore.FieldValue.increment(
            onSmallBusinessSaturday ? pointsAwarded : 0,
          ),
        },
        { merge: true },
      );
    }

    await createNotification(tx, {
      userRef,
      type: "check_in_confirmed",
      title: "Check-in confirmed",
      body: pointsAwarded > 0
        ? `You checked in at ${business.business_name || "a business"} and earned ${pointsAwarded} points.`
        : `You checked in at ${business.business_name || "a business"}.`,
      routeName: "KinQuest",
    });

    return newTotal;
  });

  return {
    visitId: visitRef.id,
    alreadyCheckedIn: false,
    distanceMeters: Math.round(distance),
    rarityTier: business.rarity_tier || "Standard",
    pointsAwarded,
    totalPoints,
  };
});

// Exported for unit testing.
exports._internals = {
  haversineMeters,
  businessCoords,
  isValidCoord,
  isRareTier,
  effectiveRadiusMeters,
  isWithinActiveWindow,
  pointsForCheckIn,
  RARE_RADIUS_METERS,
  BASE_CHECKIN_POINTS,
  MYSTERY_MIN_POINTS,
  MYSTERY_MAX_POINTS,
  UNLISTED_DISCOVERY_POINTS,
  thanksgivingDate,
  isSmallBusinessSaturday,
  SMALL_BUSINESS_SATURDAY_MULTIPLIER,
};
