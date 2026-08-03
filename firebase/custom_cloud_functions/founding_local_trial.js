const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}
// Modular imports rather than admin.firestore.Timestamp/FieldValue - see
// mystery_reward_engine.js for why (lazy-getter issue under the emulator
// on newer Node).
const { Timestamp } = require("firebase-admin/firestore");

const TRIAL_TIER = "Founding Local";
const TRIAL_DURATION_MS = 14 * 24 * 60 * 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;

/**
 * Copy for the two in-app trial reminders. Kept here (not duplicated
 * inline in the sweep) so tests can assert on the exact strings.
 *
 * `push` documents what a real push notification would say - there is no
 * FCM/APNs wiring anywhere in this codebase yet (same gap as the
 * RevenueCat test key in main.dart), so it is logged only, never sent.
 * `inApp`/`cta` are real: the tier card UI reads trial_reminder_stage off
 * the business doc and renders these directly.
 */
const REMINDER_COPY = {
  day10: {
    push:
      "Your Founding Local trial ends in 3 days — here's what you'd lose",
    inApp:
      "You've got 3 days left on your Founding Local trial. Right now you have your Verified Founding Member badge, 5 gallery photos, and basic analytics live on your profile. Keep them going for $19/mo — cancel anytime.",
    cta: "Keep my Founding Local tier",
  },
  day13: {
    push: "Last day: your Founding Local trial ends tomorrow",
    inApp:
      "Your trial ends tomorrow. After that, your profile drops back to the free Community tier — no trust badge, limited photos, no analytics. Lock in Founding Local now for $19/mo, or you'll automatically move to the free tier with no charge.",
    cta: "Keep my Founding Local tier",
  },
};

function daysElapsed(startMillis, nowMillis) {
  return Math.floor((nowMillis - startMillis) / DAY_MS);
}

/**
 * Starts a 14-day Founding Local trial for a business the caller owns.
 * Grants the exact same entitlement fields a real Founding Local purchase
 * would (see KinServices.upgradeBusinessTier / merchant_pricing_suite),
 * so every existing gated call site - map placement, AI marketing
 * quota, Kindex premium baseline, Power Hour limits - treats a trial
 * identically to a paid subscription. has_used_trial is permanent: once
 * true, this callable rejects, and nothing in the app ever resets it back
 * to false (not even unclaiming/reclaiming the business).
 */
exports.startFoundingLocalTrial = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const { businessRef: businessId } = request.data || {};
  if (typeof businessId !== "string" || !businessId) {
    throw new HttpsError("invalid-argument", "businessRef is required.");
  }

  const db = admin.firestore();
  const businessRef = db.collection("businesses").doc(businessId);

  const { endsAtMillis } = await db.runTransaction(async (tx) => {
    const snap = await tx.get(businessRef);
    if (!snap.exists) {
      throw new HttpsError("not-found", "Business not found.");
    }
    const business = snap.data();

    if (!business.owner_ref || business.owner_ref.id !== uid) {
      throw new HttpsError(
        "permission-denied",
        "You can only start a trial for your own business.",
      );
    }
    if (business.has_used_trial === true) {
      throw new HttpsError(
        "failed-precondition",
        "This business has already used its Founding Local trial.",
      );
    }

    const now = Timestamp.now();
    const endsAt = Timestamp.fromMillis(now.toMillis() + TRIAL_DURATION_MS);

    tx.update(businessRef, {
      trial_status: "active",
      trial_start_at: now,
      trial_end_at: endsAt,
      has_used_trial: true,
      trial_reminder_stage: "",
      subscription_tier: TRIAL_TIER,
      is_premium: true,
    });

    // Audit trail only - reuses the exact shape of the existing
    // `entitlements` collection (see the "Founding partner - permanent
    // comp" doc already in it). Nothing reads this back to gate
    // anything; the business doc fields above are the real grant.
    const entitlementRef = db.collection("entitlements").doc();
    tx.set(entitlementRef, {
      tier: TRIAL_TIER,
      source: "trial",
      granted_reason: "14-day Founding Local free trial",
      granted_at: now,
      expires_at: endsAt,
      user_ref: db.collection("users").doc(uid),
      business_ref: businessRef,
    });

    return { endsAtMillis: endsAt.toMillis() };
  });

  return { trialEndsAtMillis: endsAtMillis };
});

/**
 * One nightly pass over every business currently on an active trial.
 * Sends (logs) the day 10-11 reminder once, the day 13 reminder once,
 * then on day 14+ downgrades anything still 'active' (i.e. never
 * converted to a real paid tier) back to the free Community tier -
 * never a charge, just a plain field reset, same shape as
 * KinServices.downgradeToCommunity.
 */
async function processTrials(db, nowMillis) {
  const activeSnap = await db
    .collection("businesses")
    .where("trial_status", "==", "active")
    .get();

  let reminded10 = 0;
  let reminded13 = 0;
  let expired = 0;
  let batch = db.batch();
  let batchCount = 0;

  for (const doc of activeSnap.docs) {
    const business = doc.data();
    // Comped accounts (the operator's own business) are never downgraded -
    // there is no subscription behind them to convert, so the day-14 branch
    // below would silently strip their tier. Belt and braces alongside
    // clearing trial_status on those docs.
    if (business.admin_comp === true) continue;
    const startAt = business.trial_start_at;
    if (!startAt) continue; // malformed doc - don't let it crash the whole sweep

    const elapsed = daysElapsed(startAt.toMillis(), nowMillis);
    const update = {};

    if (elapsed >= 14) {
      update.subscription_tier = "Community";
      update.is_premium = false;
      update.trial_status = "expired";
      update.trial_reminder_stage = "";
      expired += 1;
    } else if (elapsed === 13) {
      if (!business.trial_reminder_day13_sent_at) {
        update.trial_reminder_stage = "day13";
        update.trial_reminder_day13_sent_at = Timestamp.fromMillis(nowMillis);
        console.log(
          `Trial day-13 reminder (business ${doc.id}): ${REMINDER_COPY.day13.push}`,
        );
        reminded13 += 1;
      }
    } else if (elapsed === 10 || elapsed === 11) {
      // Guarded by a single sent-at flag covering both days, so a
      // business caught on day 10 doesn't get the same reminder again
      // on day 11, but one caught for the first time on day 11 (e.g.
      // the sweep didn't run on day 10) still gets it once.
      if (!business.trial_reminder_day10_sent_at) {
        update.trial_reminder_stage = "day10";
        update.trial_reminder_day10_sent_at = Timestamp.fromMillis(nowMillis);
        console.log(
          `Trial day-10 reminder (business ${doc.id}): ${REMINDER_COPY.day10.push}`,
        );
        reminded10 += 1;
      }
    }

    if (Object.keys(update).length > 0) {
      batch.update(doc.ref, update);
      batchCount += 1;
      // Firestore caps a batch at 500 writes.
      if (batchCount >= 400) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
      }
    }
  }

  if (batchCount > 0) {
    await batch.commit();
  }

  return { scanned: activeSnap.size, reminded10, reminded13, expired };
}

// 3:00 AM America/Chicago - right after the 2:00/2:30 Kindex nightly jobs,
// same low-traffic window and timezone.
exports.processFoundingLocalTrials = onSchedule(
  {
    schedule: "0 3 * * *",
    timeZone: "America/Chicago",
    timeoutSeconds: 300,
    memory: "256MiB",
  },
  async () => {
    const db = admin.firestore();
    const result = await processTrials(db, Date.now());
    console.log(
      `Founding Local trial sweep: ${result.scanned} active, ` +
        `${result.reminded10} day-10 reminders, ${result.reminded13} day-13 reminders, ` +
        `${result.expired} expired.`,
    );
  },
);

exports._internals = {
  TRIAL_TIER,
  TRIAL_DURATION_MS,
  DAY_MS,
  REMINDER_COPY,
  daysElapsed,
  processTrials,
};
