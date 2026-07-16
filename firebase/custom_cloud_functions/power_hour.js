const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

const WEEK_MS = 7 * 24 * 60 * 60 * 1000;

// Per-tier Power Hour limits, moved here from the client so the caps are
// enforced server-side and can't be bypassed by a modified client. Values
// match KinServices._powerHourLimitsByTier exactly (the client keeps that
// same table, but now only for display - e.g. the duration picker's max).
// weeklyLimit null means unlimited (skip the frequency check).
const POWER_HOUR_LIMITS = {
  "Community": { durationCapMinutes: 30, weeklyLimit: 1 },
  "Founding Local": { durationCapMinutes: 45, weeklyLimit: 2 },
  "Pro Growth": { durationCapMinutes: 60, weeklyLimit: 3 },
  "Elite Growth": { durationCapMinutes: 90, weeklyLimit: null },
};
const DEFAULT_LIMITS = { durationCapMinutes: 30, weeklyLimit: 1 };

function limitsForTier(tier) {
  return POWER_HOUR_LIMITS[tier] || DEFAULT_LIMITS;
}

// Same wording the client-side _powerHourLimitMessage used, so the upgrade
// prompt a merchant sees when they hit their cap is unchanged.
function limitMessage(tier) {
  switch (tier) {
    case "Community":
      return "You've reached your weekly Power Hour limit. Upgrade to " +
        "Founding Local or Pro Growth for more!";
    case "Founding Local":
      return "You've reached your weekly Power Hour limit for Founding " +
        "Local. Upgrade to Pro Growth for more!";
    case "Pro Growth":
      return "You've reached your weekly Power Hour limit for Pro Growth. " +
        "Upgrade to Elite Growth for unlimited Power Hours!";
    default:
      return "You've reached your weekly Power Hour limit. Upgrade your " +
        "plan for more!";
  }
}

async function assertOwnership(businessRef, uid, tx) {
  const snap = await tx.get(businessRef);
  if (!snap.exists) {
    throw new HttpsError("not-found", "Business not found.");
  }
  const ownerPath = snap.data().owner_ref && snap.data().owner_ref.path;
  if (ownerPath !== `users/${uid}`) {
    throw new HttpsError(
      "permission-denied",
      "You can only manage Power Hour for your own business.",
    );
  }
  return snap;
}

// Server-side startPowerHour. Replaces the direct Firestore write that
// KinServices.startPowerHour used to do - the Power Hour fields are no
// longer in mutableBusinessFields() in firestore.rules, so this callable
// (Admin SDK) is the only path that can set them.
//
// Preserves the original logic exactly: per-tier duration cap, a rolling
// 7-day usage window (usage resets to 0 once 7 days pass since
// power_hour_last_reset), and the per-tier weekly frequency limit. Runs in
// a transaction so two rapid taps can't both slip under the weekly cap.
exports.startPowerHour = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const businessRefPath = request.data && request.data.businessRefPath;
  if (!businessRefPath || typeof businessRefPath !== "string") {
    throw new HttpsError("invalid-argument", "businessRefPath is required.");
  }
  const durationMinutes = request.data.durationMinutes;
  if (!Number.isInteger(durationMinutes) || durationMinutes < 1) {
    throw new HttpsError(
      "invalid-argument",
      "durationMinutes must be a positive integer.",
    );
  }

  const db = admin.firestore();
  const businessRef = db.doc(businessRefPath);

  await db.runTransaction(async (tx) => {
    const snap = await assertOwnership(businessRef, request.auth.uid, tx);
    const business = snap.data();
    const tier = business.subscription_tier;
    const limits = limitsForTier(tier);

    const nowMs = Date.now();
    const lastReset = business.power_hour_last_reset;
    const lastResetMs = lastReset && typeof lastReset.toMillis === "function"
      ? lastReset.toMillis()
      : null;
    const windowExpired = lastResetMs === null || nowMs - lastResetMs >= WEEK_MS;
    const currentUsage = windowExpired ? 0 : (business.power_hour_usage_count || 0);

    if (limits.weeklyLimit !== null && currentUsage >= limits.weeklyLimit) {
      // resource-exhausted carries the same upgrade-prompt message the
      // client used to build itself; KinServices surfaces e.message.
      throw new HttpsError("resource-exhausted", limitMessage(tier));
    }

    const cappedDuration = Math.min(durationMinutes, limits.durationCapMinutes);
    const expiresAt = admin.firestore.Timestamp.fromMillis(
      nowMs + cappedDuration * 60 * 1000,
    );
    const resetAt = windowExpired
      ? admin.firestore.Timestamp.fromMillis(nowMs)
      : (lastReset || admin.firestore.Timestamp.fromMillis(nowMs));

    tx.update(businessRef, {
      has_flash_beacon: true,
      flash_beacon_expires_at: expiresAt,
      flash_beacon_duration_minutes: cappedDuration,
      power_hour_usage_count: currentUsage + 1,
      power_hour_last_reset: resetAt,
    });
  });

  return { ok: true };
});

// Server-side stopPowerHour. Only clears has_flash_beacon - leaves
// flash_beacon_expires_at as-is (harmless once the flag is false; every
// read already checks the flag first), matching the original behavior.
exports.stopPowerHour = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const businessRefPath = request.data && request.data.businessRefPath;
  if (!businessRefPath || typeof businessRefPath !== "string") {
    throw new HttpsError("invalid-argument", "businessRefPath is required.");
  }

  const db = admin.firestore();
  const businessRef = db.doc(businessRefPath);

  await db.runTransaction(async (tx) => {
    await assertOwnership(businessRef, request.auth.uid, tx);
    tx.update(businessRef, { has_flash_beacon: false });
  });

  return { ok: true };
});
