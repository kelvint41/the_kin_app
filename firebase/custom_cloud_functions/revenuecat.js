// Shared RevenueCat REST helpers, used by both setBusinessSubscription
// (verify before granting a paid tier) and revenueCatWebhook (re-verify
// before auto-downgrading).

const REVENUECAT_SUBSCRIBER_URL = "https://api.revenuecat.com/v1/subscribers/";

// No expiry = lifetime/non-expiring entitlement. Otherwise must be future.
function isActiveExpiry(expiresDate) {
  if (!expiresDate) return true;
  return new Date(expiresDate).getTime() > Date.now();
}

// Whether [appUserId] holds an ACTIVE purchase of [productId], per RevenueCat.
// RevenueCat's app_user_id is the Firebase UID (the client calls
// Purchases.logIn(uid) - see revenue_cat_util.dart), so callers look a user up
// directly by their Firebase UID. Checks both the subscriptions map (keyed by
// product id) and active entitlements whose product_identifier matches, so it
// works whether the tier is modeled as a bare subscription or behind an
// entitlement.
//
// Throws on any failure to reach or parse RevenueCat (non-200, network, bad
// body). Callers decide what a failure means: setBusinessSubscription fails
// closed (deny the grant); the webhook fails to a 5xx (no downgrade, let
// RevenueCat retry) - i.e. neither side changes state when it can't verify.
async function hasActivePurchase(appUserId, productId, apiKeyValue) {
  const res = await fetch(
    REVENUECAT_SUBSCRIBER_URL + encodeURIComponent(appUserId),
    {
      method: "GET",
      headers: {
        Authorization: `Bearer ${apiKeyValue}`,
        Accept: "application/json",
      },
    },
  );
  if (!res.ok) {
    throw new Error(`RevenueCat subscriber lookup failed: ${res.status}`);
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

module.exports = { hasActivePurchase, isActiveExpiry };
