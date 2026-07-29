const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}
// Modular imports rather than admin.firestore.Timestamp/FieldValue - the
// classic namespace's lazy getters don't reliably populate under the
// Functions emulator on newer Node versions (reproduced locally on Node 24;
// production is pinned to Node 20 per package.json, where the classic form
// also works, but this form works everywhere so there's no reason to keep
// the version-sensitive one).
const { Timestamp, FieldValue } = require("firebase-admin/firestore");

const MILESTONES = [5, 15, 30];
const REWARD_EXPIRY_DAYS = 30;
// Nationwide hard cap enforced via the system_counters/{year} transaction
// below - "1-2 times nationwide per year" per the reward design, we cap at 2.
const ELITE_GROWTH_ANNUAL_CAP = 2;

// Weighted odds out of 1000, evaluated in order - first match wins.
const REWARD_TABLE = [
  { max: 700, rewardType: "POWER_HOUR", tierUnlocked: "None", durationMonths: 0 },
  { max: 900, rewardType: "GLOWING_PIN", tierUnlocked: "None", durationMonths: 0 },
  { max: 970, rewardType: "TIER_FOUNDING_LOCAL", tierUnlocked: "Founding Local", durationMonths: 1 },
  { max: 999, rewardType: "TIER_PRO_GROWTH", tierUnlocked: "Pro Growth", durationMonths: 1 },
  { max: 1000, rewardType: "TIER_ELITE_GROWTH", tierUnlocked: "Elite Growth", durationMonths: 1 },
];

function rollReward() {
  const roll = Math.floor(Math.random() * 1000) + 1; // 1-1000 inclusive
  return REWARD_TABLE.find((band) => roll <= band.max);
}

function generatePromoCode() {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // no ambiguous chars
  let code = "KIN-";
  for (let i = 0; i < 6; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}

/**
 * Fires whenever a business doc updates. Only acts when
 * businesses_discovered_count crosses one of the 5/15/30 milestones -
 * compares before/after rather than checking equality, so a multi-increment
 * batch write (or a retried function invocation) can't skip a milestone or
 * double-fire one.
 */
exports.generateMysteryReward = onDocumentUpdated(
  "businesses/{businessId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    const beforeCount = before.businesses_discovered_count || 0;
    const afterCount = after.businesses_discovered_count || 0;
    if (afterCount <= beforeCount) {
      return null;
    }

    const crossedMilestone = MILESTONES.find(
      (m) => beforeCount < m && afterCount >= m,
    );
    if (!crossedMilestone) {
      return null;
    }

    const ownerRef = after.owner_ref;
    if (!ownerRef) {
      console.log(
        `businesses/${event.params.businessId} crossed milestone ${crossedMilestone} but has no owner_ref - skipping reward.`,
      );
      return null;
    }

    const db = admin.firestore();
    const businessRef = event.data.after.ref;

    let reward = rollReward();

    if (reward.rewardType === "TIER_ELITE_GROWTH") {
      const year = String(new Date().getFullYear());
      const counterRef = db.collection("system_counters").doc(year);
      const capReached = await db.runTransaction(async (tx) => {
        const snap = await tx.get(counterRef);
        const granted = (snap.exists && snap.data().elite_growth_rewards_granted) || 0;
        if (granted >= ELITE_GROWTH_ANNUAL_CAP) {
          return true;
        }
        tx.set(
          counterRef,
          { elite_growth_rewards_granted: granted + 1 },
          { merge: true },
        );
        return false;
      });

      if (capReached) {
        // Annual golden-ticket cap already hit nationwide - fall back to
        // the next tier down rather than dropping the milestone entirely.
        reward = REWARD_TABLE.find((band) => band.rewardType === "TIER_PRO_GROWTH");
      }
    }

    const now = Timestamp.now();
    const expirationDate = Timestamp.fromMillis(
      now.toMillis() + REWARD_EXPIRY_DAYS * 24 * 60 * 60 * 1000,
    );

    await db.collection("unlocked_rewards").add({
      user_ref: ownerRef,
      business_ref: businessRef,
      reward_type: reward.rewardType,
      tier_unlocked: reward.tierUnlocked,
      duration_months: reward.durationMonths,
      date_won: now,
      expiration_date: expirationDate,
      is_redeemed: false,
      date_redeemed: null,
      promo_code: generatePromoCode(),
      reveal_animation_shown: false,
    });

    await db.collection("kin_feed_events").add({
      user_ref: ownerRef,
      user_name: after.owner_name || "A KIN member",
      city: after.city || "",
      action_type: "REWARD_UNLOCKED",
      business_ref: businessRef,
      business_name: after.business_name || "",
      timestamp: FieldValue.serverTimestamp(),
    });

    return null;
  },
);

/**
 * One-tap redemption. Validates ownership, redemption state, and expiry
 * server-side (all three are trivially bypassable if left to the client),
 * then applies the reward directly to Firestore - no Stripe integration
 * exists in this codebase yet, so tier grants are plain field writes,
 * matching how tiers are already set today (see tier_privileges_record.dart
 * / firebase/scripts/grant_admin.js).
 */
exports.redeemReward = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const { rewardId } = request.data || {};
  if (typeof rewardId !== "string" || !rewardId) {
    throw new HttpsError("invalid-argument", "rewardId is required.");
  }

  const db = admin.firestore();
  const rewardRef = db.collection("unlocked_rewards").doc(rewardId);

  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(rewardRef);
    if (!snap.exists) {
      throw new HttpsError("not-found", "Reward not found.");
    }
    const reward = snap.data();

    if (!reward.user_ref || reward.user_ref.id !== uid) {
      throw new HttpsError(
        "permission-denied",
        "This reward doesn't belong to you.",
      );
    }
    if (reward.is_redeemed) {
      throw new HttpsError("failed-precondition", "This reward was already redeemed.");
    }
    const expiresAt = reward.expiration_date;
    if (expiresAt && expiresAt.toMillis() < Date.now()) {
      throw new HttpsError(
        "failed-precondition",
        "This reward voucher expired after 30 days.",
      );
    }

    tx.update(rewardRef, {
      is_redeemed: true,
      date_redeemed: FieldValue.serverTimestamp(),
    });

    return reward;
  });

  const businessRef = result.business_ref;
  if (businessRef) {
    if (result.reward_type === "POWER_HOUR") {
      await businessRef.update({
        has_flash_beacon: true,
        flash_beacon_expires_at: Timestamp.fromMillis(
          Date.now() + 60 * 60 * 1000,
        ),
        flash_beacon_duration_minutes: 60,
      });
    } else if (result.reward_type === "GLOWING_PIN") {
      await businessRef.update({
        is_priority_pinned: true,
        has_flash_beacon: true,
        flash_beacon_expires_at: Timestamp.fromMillis(
          Date.now() + 24 * 60 * 60 * 1000,
        ),
        flash_beacon_duration_minutes: 24 * 60,
      });
    } else if (result.tier_unlocked && result.tier_unlocked !== "None") {
      const tierPrivilegesRef = db.collection("tier_privileges").doc(businessRef.id);
      await tierPrivilegesRef.set(
        {
          subscription_tier: result.tier_unlocked,
          is_premium: true,
          owner_id: uid,
        },
        { merge: true },
      );
      await businessRef.update({
        subscription_tier: result.tier_unlocked,
      });
      // Deliberately not touching kindex_score here: business_kindex_nightly.js
      // moved scoring to a nightly recompute over verified visits specifically
      // to close manipulation vectors (see index.js comment). A manual score
      // bump on redemption would reopen that - an owner could farm cheap
      // discoveries purely to inflate their own score.
    }
  }

  return { success: true, rewardType: result.reward_type, tierUnlocked: result.tier_unlocked };
});
