const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

// Tier entitlement flags come from the shared tier_config table (single
// source of truth, mirrored on the client). The server derives every flag
// from the tier - the client no longer supplies is_premium/
// is_priority_pinned/etc., so a modified client can't request premium
// placement on a free tier.
const { flagsForTier } = require("./tier_config.js");

// Server-side replacement for the direct Firestore writes that
// KinServices.upgradeBusinessTier / downgradeToCommunity used to do -
// firestore.rules now blocks subscription_tier/is_premium/
// is_priority_pinned on client writes, so this callable (Admin SDK,
// bypasses rules) is the only path that can set them.
//
// Trust model: same gates as generateMarketingContent - verified ID token,
// then ownership via the business's own owner_ref. The tier itself is
// validated against tier_config, and all flags are derived server-side.
// LIMITATION (follow-up): this still trusts that the client completed the
// RevenueCat purchase before calling. Full closure is a RevenueCat webhook
// (or server-side subscriber lookup with a REVENUECAT_API_KEY secret)
// asserting the entitlement before any paid tier is written. Today's change
// removes the direct-write bypass; it does not yet independently verify
// payment.
exports.setBusinessSubscription = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const businessRefPath = request.data && request.data.businessRefPath;
  if (!businessRefPath || typeof businessRefPath !== "string") {
    throw new HttpsError("invalid-argument", "businessRefPath is required.");
  }

  const tierName = request.data.tierName;
  const flags = flagsForTier(tierName);
  if (!flags) {
    throw new HttpsError(
      "invalid-argument",
      `Unknown subscription tier: ${tierName}`,
    );
  }

  const db = admin.firestore();
  const businessSnap = await db.doc(businessRefPath).get();
  if (!businessSnap.exists) {
    throw new HttpsError("not-found", "Business not found.");
  }

  const ownerPath =
    businessSnap.data().owner_ref && businessSnap.data().owner_ref.path;
  if (ownerPath !== `users/${request.auth.uid}`) {
    throw new HttpsError(
      "permission-denied",
      "You can only change the subscription for your own business.",
    );
  }

  await businessSnap.ref.update({
    subscription_tier: tierName,
    is_premium: flags.is_premium,
    is_priority_pinned: flags.is_priority_pinned,
    has_flash_beacon: flags.has_flash_beacon,
    subscription_updated_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { ok: true, tier: tierName };
});
