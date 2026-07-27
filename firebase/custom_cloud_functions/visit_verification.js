const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

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
    return { lat: geo.latitude, lng: geo.longitude };
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

  const coords = businessCoords(business);
  if (!coords) {
    // The business has no usable location on file, so proximity can't be
    // established. Fail closed - never record an unverifiable visit.
    throw new HttpsError(
      "failed-precondition",
      "This business has no location on file, so check-in isn't available yet.",
    );
  }

  const distance = haversineMeters({ lat: latitude, lng: longitude }, coords);
  if (distance > config.radiusMeters) {
    throw new HttpsError(
      "out-of-range",
      `You need to be at the business to check in. You're about ${Math.round(distance)}m away.`,
    );
  }

  const userRef = db.collection("users").doc(uid);

  // Reuse a recent visit rather than stacking duplicates for one trip.
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
    };
  }

  const visitRef = await db.collection(VISITS_COLLECTION).add({
    user_ref: userRef,
    business_ref: businessRef,
    visit_timestamp: admin.firestore.FieldValue.serverTimestamp(),
    // Recorded for audit/debugging - how close the device claimed to be.
    verified_distance_meters: Math.round(distance),
    verified_radius_meters: config.radiusMeters,
  });

  return {
    visitId: visitRef.id,
    alreadyCheckedIn: false,
    distanceMeters: Math.round(distance),
  };
});

// Exported for unit testing.
exports._internals = { haversineMeters, businessCoords, isValidCoord };
