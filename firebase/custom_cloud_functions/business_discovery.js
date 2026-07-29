const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}
// See mystery_reward_engine.js for why this uses the modular import
// instead of admin.firestore.FieldValue.
const { FieldValue } = require("firebase-admin/firestore");

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

  const { businessName, address, category } = request.data || {};
  if (typeof businessName !== "string" || !businessName.trim()) {
    throw new HttpsError("invalid-argument", "businessName is required.");
  }
  if (typeof address !== "string" || !address.trim()) {
    throw new HttpsError("invalid-argument", "address is required.");
  }
  if (typeof category !== "string" || !category.trim()) {
    throw new HttpsError("invalid-argument", "category is required.");
  }

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
