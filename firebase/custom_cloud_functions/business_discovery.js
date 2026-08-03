const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}
// See mystery_reward_engine.js for why this uses the modular import
// instead of admin.firestore.FieldValue.
const { FieldValue, GeoPoint } = require("firebase-admin/firestore");
const { haversineMeters, isValidCoord } = require("./visit_verification.js")
  ._internals;
const { encodeGeohash } = require("./geohash.js");

/// Radius within which a submitted business is treated as a duplicate of an
/// existing listing or pending submission. Wider than the visit-verification
/// check-in radii (20-100m) on purpose - this is catching "someone re-adding
/// the same storefront", not confirming a precise GPS fix, and a submitter's
/// phone fix while wandering a strip mall can drift more than a stationary
/// check-in would.
const DUPLICATE_RADIUS_METERS = 200;

function normalizeName(name) {
  return name.trim().toLowerCase().replace(/\s+/g, " ");
}

/// True if `candidateName`/`candidateCoords` looks like the same business as
/// any doc in `snapshot` (read from either `businesses` or
/// `business_submissions`, both of which store `business_name` and either
/// `business_location` or a bare lat/lng under `latitude`/`longitude`).
function findsDuplicate(snapshot, candidateName, candidateCoords) {
  const normalizedCandidate = normalizeName(candidateName);
  for (const doc of snapshot.docs) {
    const data = doc.data();
    const existingName = data.business_name;
    if (typeof existingName !== "string") continue;
    if (normalizeName(existingName) !== normalizedCandidate) continue;
    if (!candidateCoords) return true;

    const loc = data.business_location;
    const coords = loc && typeof loc.latitude === "number"
      ? { lat: loc.latitude, lng: loc.longitude }
      : null;
    if (!coords) return true; // same name, no location to disprove it
    if (haversineMeters(candidateCoords, coords) <= DUPLICATE_RADIUS_METERS) {
      return true;
    }
  }
  return false;
}

/**
 * Lets a business owner submit a new listing they've found to the
 * directory. This is the "discovery" event that generateMysteryReward
 * (mystery_reward_engine.js) watches for via businesses_discovered_count.
 *
 * Deliberately split from the reward logic: this callable only records the
 * submission and bumps the counter. generateMysteryReward reacts to the
 * counter crossing a threshold, so the two stay independently testable and
 * the reward odds/logic can change without touching submission handling.
 */
exports.submitBusinessDiscovery = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const { businessName, address, category, latitude, longitude } =
    request.data || {};
  if (typeof businessName !== "string" || !businessName.trim()) {
    throw new HttpsError("invalid-argument", "businessName is required.");
  }
  if (typeof address !== "string" || !address.trim()) {
    throw new HttpsError("invalid-argument", "address is required.");
  }
  if (typeof category !== "string" || !category.trim()) {
    throw new HttpsError("invalid-argument", "category is required.");
  }
  // Optional - the owner may have typed an address by hand instead of using
  // the place picker (e.g. a business not indexed by Google Places yet).
  const hasCoords = isValidCoord(latitude, longitude);

  const db = admin.firestore();
  const userRef = db.collection("users").doc(uid);

  const ownedBusinessSnap = await db
    .collection("businesses")
    .where("owner_ref", "==", userRef)
    .limit(1)
    .get();

  if (ownedBusinessSnap.empty) {
    throw new HttpsError(
      "failed-precondition",
      "Only business owners can submit a discovery.",
    );
  }

  const ownedBusinessRef = ownedBusinessSnap.docs[0].ref;

  await db.collection("business_submissions").add({
    submitted_by_business_ref: ownedBusinessRef,
    submitted_by_user_ref: userRef,
    business_name: businessName.trim(),
    address: address.trim(),
    category: category.trim(),
    business_location: hasCoords
      ? new GeoPoint(latitude, longitude)
      : null,
    created_at: FieldValue.serverTimestamp(),
  });

  // The businesses/{businessId} onDocumentUpdated trigger in
  // mystery_reward_engine.js picks this increment up and checks it against
  // the 5/15/30 milestones.
  await ownedBusinessRef.update({
    businesses_discovered_count: FieldValue.increment(1),
  });

  await db.collection("kin_feed_events").add({
    user_ref: userRef,
    user_name: ownedBusinessSnap.docs[0].data().owner_name || "A KIN member",
    city: ownedBusinessSnap.docs[0].data().city || "",
    action_type: "NEW_DISCOVERY",
    business_ref: ownedBusinessRef,
    business_name: businessName.trim(),
    timestamp: FieldValue.serverTimestamp(),
  });

  return { success: true };
});

/**
 * Lets any signed-in customer submit a business they've encountered while
 * out of their usual KIN Quest radius (see selectNearby/kNearbyFeedRadiusKm
 * in lib/services/nearby_feed.dart) so it can eventually be checked into.
 *
 * Deliberately separate from submitBusinessDiscovery above rather than a
 * shared branch: that callable is gated on owning a business and drives the
 * owner mystery-reward counter, neither of which applies to a traveling
 * customer. This one only queues a business_submissions row for manual
 * review - there is no auto-promotion into the `businesses` collection, so
 * a submitted business is not immediately check-in-able. It still needs
 * duplicate-detection precisely because it has no owner-side gate keeping
 * casual re-submission of an already-listed business in check.
 */
exports.submitCustomerBusinessDiscovery = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const {
    businessName, address, category, latitude, longitude, verifiedOnSite,
  } = request.data || {};
  if (typeof businessName !== "string" || !businessName.trim()) {
    throw new HttpsError("invalid-argument", "businessName is required.");
  }
  if (typeof address !== "string" || !address.trim()) {
    throw new HttpsError("invalid-argument", "address is required.");
  }
  if (typeof category !== "string" || !category.trim()) {
    throw new HttpsError("invalid-argument", "category is required.");
  }

  const hasCoords = isValidCoord(latitude, longitude);
  const candidateCoords = hasCoords ? { lat: latitude, lng: longitude } : null;
  const trimmedName = businessName.trim();

  const db = admin.firestore();
  const userRef = db.collection("users").doc(uid);

  const [businessesSnap, submissionsSnap] = await Promise.all([
    db.collection("businesses").select("business_name", "business_location").get(),
    db.collection("business_submissions")
      .select("business_name", "business_location")
      .get(),
  ]);

  if (
    findsDuplicate(businessesSnap, trimmedName, candidateCoords) ||
    findsDuplicate(submissionsSnap, trimmedName, candidateCoords)
  ) {
    throw new HttpsError(
      "already-exists",
      "That business already looks like it's in KIN, or already submitted.",
    );
  }

  await db.collection("business_submissions").add({
    submitted_by_user_ref: userRef,
    source: "customer_quest",
    business_name: trimmedName,
    address: address.trim(),
    category: category.trim(),
    business_location: candidateCoords
      ? new GeoPoint(candidateCoords.lat, candidateCoords.lng)
      : null,
    // Whether the submitter's own GPS put them at the business, or they
    // vouched for it remotely (from a business card, a trip they took).
    // Both are worth having, but KIN lists *verified* Black-owned
    // businesses, so a review needs to be able to tell them apart - a
    // remote submission is a lead, an on-site one is ground truth.
    //
    // Coerced rather than trusted: this arrives from the client, and an
    // absent field must read as "not verified", never as verified.
    verified_on_site: verifiedOnSite === true,
    created_at: FieldValue.serverTimestamp(),
  });

  await db.collection("kin_feed_events").add({
    user_ref: userRef,
    action_type: "NEW_DISCOVERY",
    business_name: trimmedName,
    timestamp: FieldValue.serverTimestamp(),
  });

  return { success: true };
});

/**
 * Looks for a pending customer-submitted discovery (see
 * submitCustomerBusinessDiscovery above) that matches the business name (and
 * address, once geocoded) an owner is entering during business setup - the
 * "someone already found your business on KIN Quest" moment.
 *
 * Read-only and deliberately thin on what it returns: the caller isn't
 * necessarily the business's owner yet (the business doc doesn't exist until
 * they finish setup), so this only echoes back business-shaped fields
 * (name/address/category/location) an owner would already know about their
 * own business. It never returns submitted_by_user_ref - the whole point is
 * that the owner learns their business was found, not who found it.
 */
exports.findMatchingBusinessSubmission = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const { businessName, latitude, longitude } = request.data || {};
  if (typeof businessName !== "string" || !businessName.trim()) {
    throw new HttpsError("invalid-argument", "businessName is required.");
  }

  const hasCoords = isValidCoord(latitude, longitude);
  const candidateCoords = hasCoords ? { lat: latitude, lng: longitude } : null;
  const normalizedCandidate = normalizeName(businessName);

  const db = admin.firestore();
  const snap = await db.collection("business_submissions").get();

  for (const doc of snap.docs) {
    const data = doc.data();
    if (data.resolved === true) continue;
    if (typeof data.business_name !== "string") continue;
    if (normalizeName(data.business_name) !== normalizedCandidate) continue;

    const loc = data.business_location;
    const coords = loc && typeof loc.latitude === "number"
      ? { lat: loc.latitude, lng: loc.longitude }
      : null;
    // Same as findsDuplicate: no coords on one side to disprove a name
    // match still counts, since that's the common case for an early
    // submission made before the owner has geocoded an address.
    if (
      candidateCoords &&
      coords &&
      haversineMeters(candidateCoords, coords) > DUPLICATE_RADIUS_METERS
    ) {
      continue;
    }

    return {
      matched: true,
      submissionId: doc.id,
      businessName: data.business_name,
      address: data.address || "",
      category: data.category || "",
      latitude: coords ? coords.lat : null,
      longitude: coords ? coords.lng : null,
    };
  }

  return { matched: false };
});

/**
 * Marks a business_submissions row as resolved once the owner it matched has
 * confirmed the claim and finished registering their business - see
 * findMatchingBusinessSubmission. Keeps the submission document (rather than
 * deleting it) as an audit trail of what got claimed and by which business,
 * same reasoning as the rest of business_submissions being an admin-only
 * audit collection.
 */
exports.resolveBusinessSubmission = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const { submissionId, businessRefPath } = request.data || {};
  if (typeof submissionId !== "string" || !submissionId.trim()) {
    throw new HttpsError("invalid-argument", "submissionId is required.");
  }
  if (
    typeof businessRefPath !== "string" ||
    !businessRefPath.startsWith("businesses/")
  ) {
    throw new HttpsError(
      "invalid-argument",
      "A valid businessRefPath is required.",
    );
  }

  const db = admin.firestore();
  const businessRef = db.doc(businessRefPath);
  const businessSnap = await businessRef.get();
  // Only the owner of the business being claimed against can resolve the
  // submission it matched - otherwise anyone signed in could mark arbitrary
  // submissions resolved.
  if (
    !businessSnap.exists ||
    !businessSnap.data().owner_ref ||
    businessSnap.data().owner_ref.id !== uid
  ) {
    throw new HttpsError(
      "permission-denied",
      "You can only resolve a submission against a business you own.",
    );
  }

  await db.collection("business_submissions").doc(submissionId).update({
    resolved: true,
    resolved_business_ref: businessRef,
    resolved_at: FieldValue.serverTimestamp(),
  });

  return { success: true };
});

exports._internals = { findsDuplicate, normalizeName };

/**
 * Approves or dismisses a queued business submission. Admin only.
 *
 * business_submissions was a queue with no exit: customers could drop a pin
 * from KIN Quest search and the row landed here, but nothing in the app or
 * the functions could ever promote one into `businesses`. Submissions
 * accumulated and no submitted business could reach the map.
 *
 * On approve this creates the live listing itself rather than handing the
 * client a payload to write, so the fields that matter can't be tampered
 * with in transit - and so `geohash` is computed here. Without it the new
 * business is invisible on the map (see geohash.js).
 *
 * `owner_ref` is deliberately left null: approving means "this is a real
 * Black-owned business", not "this person owns it". Ownership is still
 * settled by the claim flow.
 */
exports.resolveBusinessSubmissionReview = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const db = admin.firestore();
  const callerSnap = await db.doc(`users/${uid}`).get();
  if (!callerSnap.exists || callerSnap.data().is_admin !== true) {
    throw new HttpsError("permission-denied", "Admin access required.");
  }

  const { submissionId, action } = request.data || {};
  if (typeof submissionId !== "string" || !submissionId.trim()) {
    throw new HttpsError("invalid-argument", "submissionId is required.");
  }
  if (action !== "approve" && action !== "dismiss") {
    throw new HttpsError("invalid-argument", "action must be approve or dismiss.");
  }

  const subRef = db.collection("business_submissions").doc(submissionId);
  const subSnap = await subRef.get();
  if (!subSnap.exists) {
    throw new HttpsError("not-found", "That submission no longer exists.");
  }
  const sub = subSnap.data();

  // Kept rather than deleted, same audit-trail reasoning as the rest of
  // business_submissions.
  if (action === "dismiss") {
    await subRef.update({
      review_status: "dismissed",
      reviewed_by: db.doc(`users/${uid}`),
      reviewed_at: FieldValue.serverTimestamp(),
    });
    return { success: true, action: "dismissed" };
  }

  if (sub.review_status === "approved" && sub.published_business_ref) {
    // Idempotent: a double-tap shouldn't create a second listing.
    return { success: true, action: "approved", businessId: sub.published_business_ref.id };
  }

  const loc = sub.business_location;
  if (!loc || typeof loc.latitude !== "number") {
    throw new HttpsError(
      "failed-precondition",
      "That submission has no coordinates, so it can't be placed on the map.",
    );
  }

  const businessRef = await db.collection("businesses").add({
    business_name: sub.business_name,
    address: sub.address || "",
    category: sub.category || "",
    business_location: loc,
    geohash: encodeGeohash(loc.latitude, loc.longitude),
    is_verified: true,
    owner_ref: null,
    subscription_tier: "Community",
    is_premium: false,
    created_at: FieldValue.serverTimestamp(),
    approved_from_submission: subRef,
  });

  await subRef.update({
    review_status: "approved",
    published_business_ref: businessRef,
    reviewed_by: db.doc(`users/${uid}`),
    reviewed_at: FieldValue.serverTimestamp(),
  });

  return { success: true, action: "approved", businessId: businessRef.id };
});
