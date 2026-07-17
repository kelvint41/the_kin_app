const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

// Tier entitlement flags + the RevenueCat product id per tier come from the
// shared tier_config table (single source of truth, mirrored on the client).
// The server derives every flag from the tier - the client no longer supplies
// is_premium/is_priority_pinned/etc., so a modified client can't request
// premium placement on a free tier.
const { flagsForTier, revenueCatProductId } = require("./tier_config.js");
const { hasActivePurchase } = require("./revenuecat.js");

// RevenueCat secret (v1) REST API key. Server-side only - never shipped to
// the client. Set via:
//   firebase functions:secrets:set REVENUECAT_API_KEY
const revenueCatApiKey = defineSecret("REVENUECAT_API_KEY");

// Server-side replacement for the direct Firestore writes that
// KinServices.upgradeBusinessTier / downgradeToCommunity used to do -
// firestore.rules now blocks subscription_tier/is_premium/
// is_priority_pinned on client writes, so this callable (Admin SDK,
// bypasses rules) is the only path that can set them.
//
// Trust model: verified ID token, then ownership via the business's own
// owner_ref, then - for any PAID tier - independent verification with
// RevenueCat that the caller actually holds an active purchase of that tier's
// product. The client can no longer grant itself a paid tier just by calling
// this after a failed/fake purchase. Downgrades to the free Community tier
// need no purchase, so they skip verification.
exports.setBusinessSubscription = onCall(
  { secrets: [revenueCatApiKey] },
  async (request) => {
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

    // Paywall enforcement: a paid tier requires an active RevenueCat purchase
    // of its product. Community (productId null) is free, so it's skipped -
    // this is also the downgrade path. Fails CLOSED: if RevenueCat can't be
    // reached, deny rather than grant.
    const productId = revenueCatProductId(tierName);
    if (productId) {
      let entitled;
      try {
        entitled = await hasActivePurchase(
          request.auth.uid,
          productId,
          revenueCatApiKey.value(),
        );
      } catch (e) {
        throw new HttpsError(
          "unavailable",
          "Could not verify your purchase right now. Please try again.",
        );
      }
      if (!entitled) {
        throw new HttpsError(
          "failed-precondition",
          "We couldn't find an active purchase for this plan. If you just " +
            "purchased, wait a moment and try again, or restore purchases.",
        );
      }
    }

    await businessSnap.ref.update({
      subscription_tier: tierName,
      is_premium: flags.is_premium,
      is_priority_pinned: flags.is_priority_pinned,
      has_flash_beacon: flags.has_flash_beacon,
      subscription_updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { ok: true, tier: tierName };
  },
);
