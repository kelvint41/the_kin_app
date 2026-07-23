const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

const { flagsForTier, revenueCatProductId } = require("./tier_config.js");
const { hasActivePurchase } = require("./revenuecat.js");

// v1 REST key, to re-verify the subscriber (same secret setBusinessSubscription
// uses). Set via: firebase functions:secrets:set REVENUECAT_API_KEY
const revenueCatApiKey = defineSecret("REVENUECAT_API_KEY");

// Shared secret RevenueCat sends in the Authorization header of every webhook,
// configured in the RevenueCat dashboard (Project -> Webhooks -> Authorization
// header value). Must equal this secret. Set via:
//   firebase functions:secrets:set REVENUECAT_WEBHOOK_AUTH
const webhookAuth = defineSecret("REVENUECAT_WEBHOOK_AUTH");

// Event types that can mean access was (or may have been) lost. We don't act
// on the event type alone - a plain CANCELLATION just means auto-renew was
// turned off and access continues to period end - so instead these events
// TRIGGER a re-verification against RevenueCat, and we downgrade only if the
// business's current paid tier is genuinely no longer active. Types that only
// ever mean "still/newly active" (INITIAL_PURCHASE, RENEWAL, UNCANCELLATION,
// TEST, ...) are ignored.
const POSSIBLE_LOSS_EVENTS = new Set([
  "EXPIRATION",
  "CANCELLATION",
  "BILLING_ISSUE",
  "REFUND",
  "SUBSCRIPTION_PAUSED",
]);

// Auto-downgrade a business to the free Community tier when its RevenueCat
// subscription lapses (expiry, refund, billing failure). RevenueCat's
// app_user_id is the Firebase UID, so the affected user is users/{app_user_id}
// and their business is that user's owned_business.
//
// This is defense-in-depth on top of setBusinessSubscription's grant-time
// verification: that stops a client self-granting a paid tier; this reacts to
// a paid tier ending after the fact. The tier fields are server-controlled
// (firestore.rules), so the Admin SDK write here is the authoritative path.
exports.revenueCatWebhook = onRequest(
  { secrets: [revenueCatApiKey, webhookAuth] },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    // Authenticate the caller: RevenueCat sends the configured value verbatim
    // in the Authorization header. Reject anything that doesn't match, so a
    // random POST can't force downgrades.
    const expected = webhookAuth.value();
    if (!expected || req.header("authorization") !== expected) {
      res.status(401).send("Unauthorized");
      return;
    }

    const event = req.body && req.body.event;
    if (!event || typeof event !== "object") {
      res.status(400).send("Bad Request");
      return;
    }

    if (!POSSIBLE_LOSS_EVENTS.has(event.type)) {
      res.status(200).json({ ok: true, ignored: event.type });
      return;
    }

    const appUserId = event.app_user_id;
    if (!appUserId) {
      res.status(200).json({ ok: true, note: "no app_user_id" });
      return;
    }

    try {
      const db = admin.firestore();

      const userSnap = await db.doc(`users/${appUserId}`).get();
      if (!userSnap.exists) {
        res.status(200).json({ ok: true, note: "no user" });
        return;
      }
      const ownedBusiness = userSnap.data().owned_business;
      if (!ownedBusiness) {
        res.status(200).json({ ok: true, note: "no business" });
        return;
      }

      const bizSnap = await ownedBusiness.get();
      if (!bizSnap.exists) {
        res.status(200).json({ ok: true, note: "business missing" });
        return;
      }

      const currentTier = bizSnap.data().subscription_tier;
      const productId = revenueCatProductId(currentTier);
      if (!productId) {
        // Already on a free/unknown tier - nothing to downgrade. (Idempotent:
        // a redelivered event after a downgrade lands here and no-ops.)
        res.status(200).json({ ok: true, note: "not on a paid tier" });
        return;
      }

      // Re-verify the CURRENT tier's product against RevenueCat. Only downgrade
      // if it's genuinely inactive - so auto-renew-off (still active until
      // expiry) doesn't trigger a premature downgrade, and a business that has
      // since upgraded to a different active tier isn't clobbered.
      const stillActive = await hasActivePurchase(
        appUserId,
        productId,
        revenueCatApiKey.value(),
      );
      if (stillActive) {
        res.status(200).json({ ok: true, note: "still active" });
        return;
      }

      const community = flagsForTier("Community");
      await bizSnap.ref.update({
        subscription_tier: "Community",
        is_premium: community.is_premium,
        is_priority_pinned: community.is_priority_pinned,
        has_flash_beacon: community.has_flash_beacon,
        subscription_updated_at: admin.firestore.FieldValue.serverTimestamp(),
        subscription_downgrade_reason: event.type,
      });
      res
        .status(200)
        .json({ ok: true, downgraded: bizSnap.ref.id, from: currentTier });
    } catch (e) {
      // 5xx so RevenueCat retries (its webhooks retry on failure) rather than
      // dropping a genuine downgrade. Includes the case where re-verification
      // couldn't reach RevenueCat - we don't downgrade on uncertainty.
      console.error("revenueCatWebhook error:", e);
      res.status(500).send("Internal error");
    }
  },
);
