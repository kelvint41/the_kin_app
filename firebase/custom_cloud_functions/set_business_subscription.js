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

// RevenueCat secret (v1) REST API key. Server-side only - never shipped to
// the client. Set via:
//   firebase functions:secrets:set REVENUECAT_API_KEY
const revenueCatApiKey = defineSecret("REVENUECAT_API_KEY");

const REVENUECAT_SUBSCRIBER_URL = "https://api.revenuecat.com/v1/subscribers/";

function isActiveExpiry(expiresDate) {
  // No expiry = lifetime/non-expiring entitlement. Otherwise must be future.
  if (!expiresDate) return true;
  return new Date(expiresDate).getTime() > Date.now();
}

// Confirms with RevenueCat that [appUserId] holds an ACTIVE purchase of
// [productId]. RevenueCat's app_user_id is the Firebase UID (the client calls
// Purchases.logIn(uid) - see revenue_cat_util.dart), so we can look the caller
// up directly by request.auth.uid. Checks both the subscriptions map (keyed by
// product id) and active entitlements whose product_identifier matches, so it
// works whether the tier is modeled as a bare subscription or behind an
// entitlement. Fails CLOSED: any error verifying (network, non-200, bad body)
// throws rather than granting, since this gates a paywall.
async function hasActivePurchase(appUserId, productId) {
  let res;
  try {
    res = await fetch(
      REVENUECAT_SUBSCRIBER_URL + encodeURIComponent(appUserId),
      {
        method: "GET",
        headers: {
          Authorization: `Bearer ${revenueCatApiKey.value()}`,
          Accept: "application/json",
        },
      },
    );
  } catch (e) {
    throw new HttpsError(
      "unavailable",
      "Could not verify your purchase right now. Please try again.",
    );
  }
  if (!res.ok) {
    throw new HttpsError(
      "unavailable",
      "Could not verify your purchase right now. Please try again.",
    );
  }

  const body = await res.json();
  const subscriber = (body && body.subscriber) || {};

  const subs = subscriber.subscriptions || {};
  if (subs[productId] && isActiveExpiry(subs[productId].expires_date)) {
    return true;
  }

  const entitlements = subscriber.entitlements || {};
  for (const ent of Object.values(entitlements)) {
    if (
      ent &&
      ent.product_identifier === productId &&
      isActiveExpiry(ent.expires_date)
    ) {
      return true;
    }
  }
  return false;
}

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
    // this is also the downgrade path.
    const productId = revenueCatProductId(tierName);
    if (productId) {
      const entitled = await hasActivePurchase(request.auth.uid, productId);
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
