const functions = require("firebase-functions");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

// -----------------------------------------------------------------------------
// KIN Marketing Engine
//
// Backend for the in-app marketing management system: referral programs,
// promotional campaigns, and per-region engagement analytics.
//
// Deliberately reuses this app's EXISTING reward rails instead of inventing a
// parallel points currency:
//   - Kindex: rewards are granted by creating `UserEngagementEvents` docs,
//     which `processUserEngagementEvent` (kindex_engine.js) already scores
//     against console-tunable weights in kindex_config/scoring_weights. Add
//     `referral_success` and `referral_signup` keys to that doc to set the
//     point values - no redeploy needed to tune them.
//   - Entitlements: an optional tier grant is written to the existing
//     `entitlements` collection, the same shape the rest of the app reads.
//
// Split mirrors the app's own generateMarketingContent (callable, fast, user-
// facing validation) + processUserEngagementEvent (Firestore trigger, idempotent
// reward fan-out) convention:
//   - redeemReferralCode / getOrCreateReferralCode / logCampaignEvent : callables
//   - processReferral                                                  : trigger
//   - expireCampaigns                                                  : scheduled
// -----------------------------------------------------------------------------

const CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // no ambiguous 0/O/1/I
const CODE_LENGTH = 6;
const CODE_MAX_ATTEMPTS = 5;

// Kindex event_type strings emitted for referral rewards. The actual point
// value for each lives in kindex_config/scoring_weights (server-tunable), NOT
// here - keeping a single source of truth for scoring, same as every other
// engagement event in the app.
const EVENT_REFERRER_REWARD = "referral_success";
const EVENT_REFEREE_REWARD = "referral_signup";

function generateCode() {
  let out = "";
  for (let i = 0; i < CODE_LENGTH; i++) {
    out += CODE_ALPHABET[Math.floor(Math.random() * CODE_ALPHABET.length)];
  }
  return out;
}

// region -> slug safe for a Firestore document id (deterministic, so the daily
// analytics doc for a given campaign+region+day is always the same id and can
// be upserted with FieldValue.increment).
function regionSlug(region) {
  return String(region || "unknown")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 40) || "unknown";
}

function ymd(date) {
  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, "0");
  const d = String(date.getUTCDate()).padStart(2, "0");
  return `${y}${m}${d}`;
}

function isCampaignLive(campaign, now) {
  if (!campaign || campaign.status !== "active") return false;
  const start = campaign.start_date;
  const end = campaign.end_date;
  if (start && start.toMillis && start.toMillis() > now.toMillis()) return false;
  if (end && end.toMillis && end.toMillis() < now.toMillis()) return false;
  return true;
}

// -----------------------------------------------------------------------------
// getOrCreateReferralCode (callable)
//
// Returns the caller's personal, shareable referral code for a campaign,
// minting one if they don't have it yet. Uniqueness is enforced the same way
// ticker_registry does it: the code IS the document id, so a create against a
// taken code fails with ALREADY_EXISTS and we simply try another - no query,
// no transaction needed.
// -----------------------------------------------------------------------------
exports.getOrCreateReferralCode = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const campaignRefPath = request.data && request.data.campaignRefPath;
  if (!campaignRefPath || typeof campaignRefPath !== "string") {
    throw new HttpsError("invalid-argument", "campaignRefPath is required.");
  }

  const db = admin.firestore();
  const campaignRef = db.doc(campaignRefPath);
  const userRef = db.doc(`users/${request.auth.uid}`);

  const campaignSnap = await campaignRef.get();
  if (!campaignSnap.exists) {
    throw new HttpsError("not-found", "Campaign not found.");
  }

  // Reuse an existing code for this (user, campaign) pair rather than minting a
  // second one.
  const existing = await db
    .collection("referral_codes")
    .where("owner_ref", "==", userRef)
    .where("campaign_ref", "==", campaignRef)
    .limit(1)
    .get();
  if (!existing.empty) {
    return { code: existing.docs[0].id, campaignRefPath };
  }

  for (let attempt = 0; attempt < CODE_MAX_ATTEMPTS; attempt++) {
    const code = generateCode();
    try {
      await db.collection("referral_codes").doc(code).create({
        owner_ref: userRef,
        campaign_ref: campaignRef,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      return { code, campaignRefPath };
    } catch (e) {
      if (e && e.code === 6) continue; // ALREADY_EXISTS -> collision, retry
      throw new HttpsError("internal", "Could not create a referral code.");
    }
  }
  throw new HttpsError("resource-exhausted", "Could not allocate a unique code. Try again.");
});

// -----------------------------------------------------------------------------
// redeemReferralCode (callable)
//
// Called by (or just after) signup when a new user enters a referral code.
// Server-authoritative: the client only submits the code string. The referrer
// is resolved from referral_codes here - a client can NEVER assert who referred
// them, which is the whole integrity point of a referral program.
//
// Creates a `referrals` doc with status 'pending'; the processReferral trigger
// grants the rewards. Fast user-facing validation lives here (invalid code,
// expired campaign, self-referral, duplicate); the heavier idempotent reward
// fan-out lives in the trigger.
// -----------------------------------------------------------------------------
exports.redeemReferralCode = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const rawCode = request.data && request.data.code;
  if (!rawCode || typeof rawCode !== "string") {
    throw new HttpsError("invalid-argument", "code is required.");
  }
  const code = rawCode.trim().toUpperCase();
  const region = typeof (request.data && request.data.region) === "string"
    ? request.data.region.slice(0, 120)
    : null;

  const db = admin.firestore();
  const refereeRef = db.doc(`users/${request.auth.uid}`);
  const now = admin.firestore.Timestamp.now();

  const codeSnap = await db.collection("referral_codes").doc(code).get();
  if (!codeSnap.exists) {
    throw new HttpsError("not-found", "That referral code isn't valid.");
  }
  const referrerRef = codeSnap.data().owner_ref;
  const campaignRef = codeSnap.data().campaign_ref;

  if (referrerRef.path === refereeRef.path) {
    throw new HttpsError("failed-precondition", "You can't refer yourself.");
  }

  const campaignSnap = await campaignRef.get();
  if (!isCampaignLive(campaignSnap.data(), now)) {
    throw new HttpsError("failed-precondition", "This campaign is no longer active.");
  }
  const campaign = campaignSnap.data();

  // One redemption per referee per campaign. Deterministic doc id makes this a
  // create-collision check rather than a query, so it's race-free.
  const referralId = `${campaignSnap.id}_${request.auth.uid}`;
  const referralRef = db.collection("referrals").doc(referralId);

  // Per-referrer cap (0/absent = unlimited).
  const cap = Number(campaign.max_referrals_per_user) || 0;
  if (cap > 0) {
    const priorCount = await db
      .collection("referrals")
      .where("campaign_ref", "==", campaignRef)
      .where("referrer_ref", "==", referrerRef)
      .count()
      .get();
    if (priorCount.data().count >= cap) {
      throw new HttpsError("resource-exhausted", "This referrer has reached the campaign limit.");
    }
  }

  try {
    await referralRef.create({
      code,
      campaign_ref: campaignRef,
      referrer_ref: referrerRef,
      referee_ref: refereeRef,
      region: region || campaign.default_region || null,
      status: "pending",
      referrer_points_awarded: 0,
      referee_points_awarded: 0,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      processed_at: null,
    });
  } catch (e) {
    if (e && e.code === 6) {
      throw new HttpsError("already-exists", "You've already used a referral code for this campaign.");
    }
    throw new HttpsError("internal", "Could not redeem this code right now.");
  }

  return { referralId, status: "pending" };
});

// -----------------------------------------------------------------------------
// processReferral (Firestore trigger)
//
// Grants referral rewards idempotently. Follows kindex_engine's at-least-once
// pattern exactly: re-read the referral inside a transaction and bail unless it
// is still 'pending', so a redelivered event can never double-grant.
//
// Everything - status flip, both Kindex engagement events, the optional
// entitlement grant, and every counter increment - happens inside ONE
// transaction, so the whole reward is atomic and guarded by the same status
// gate.
// -----------------------------------------------------------------------------
exports.processReferral = functions.firestore
  .document("referrals/{referralId}")
  .onCreate(async (snapshot) => {
    const db = admin.firestore();
    const referralRef = snapshot.ref;
    const now = admin.firestore.Timestamp.now();

    await db.runTransaction(async (tx) => {
      const refSnap = await tx.get(referralRef);
      const referral = refSnap.data();
      if (!referral || referral.status !== "pending") {
        return; // already processed (redelivery) or gone
      }

      const campaignSnap = await tx.get(referral.campaign_ref);
      const campaign = campaignSnap.exists ? campaignSnap.data() : null;

      const dailyId = `${campaignSnap.id}_${regionSlug(referral.region)}_${ymd(now.toDate())}`;
      const dailyRef = db.collection("campaign_analytics_daily").doc(dailyId);

      // Every redemption counts toward referral_count, even a rejected one, so
      // the funnel (redemptions -> qualified -> rewarded) is measurable.
      const campaignInc = { referral_count: admin.firestore.FieldValue.increment(1) };
      const dailyInc = {
        campaign_ref: referral.campaign_ref,
        region: referral.region || "unknown",
        date: ymd(now.toDate()),
        date_ts: now,
        referral_count: admin.firestore.FieldValue.increment(1),
      };

      if (!isCampaignLive(campaign, now)) {
        tx.update(referralRef, {
          status: "rejected",
          reject_reason: "campaign_not_live",
          processed_at: now,
        });
        tx.set(campaignSnap.ref, campaignInc, { merge: true });
        tx.set(dailyRef, dailyInc, { merge: true });
        return;
      }

      // Reward both sides via Kindex engagement events. points_awarded is left
      // for processUserEngagementEvent to fill from kindex_config weights - we
      // never set it here (that's the server scoring engine's job).
      const referrerEventRef = db.collection("UserEngagementEvents").doc();
      tx.set(referrerEventRef, {
        user_ref: referral.referrer_ref,
        target_ref: referral.referee_ref,
        event_type: EVENT_REFERRER_REWARD,
        status: "pending",
        source_referral_ref: referralRef,
        created_at: now,
      });
      const refereeEventRef = db.collection("UserEngagementEvents").doc();
      tx.set(refereeEventRef, {
        user_ref: referral.referee_ref,
        target_ref: referral.referrer_ref,
        event_type: EVENT_REFEREE_REWARD,
        status: "pending",
        source_referral_ref: referralRef,
        created_at: now,
      });

      // Optional entitlement grant, using the existing entitlements collection
      // shape. Only when the campaign configures one.
      const rewardTier = campaign.referral_reward_tier;
      const rewardDays = Number(campaign.referral_reward_days) || 0;
      if (rewardTier) {
        let expiresAt = null;
        if (rewardDays > 0) {
          expiresAt = admin.firestore.Timestamp.fromMillis(
            now.toMillis() + rewardDays * 24 * 60 * 60 * 1000,
          );
        }
        const entRef = db.collection("entitlements").doc();
        tx.set(entRef, {
          user_ref: referral.referrer_ref,
          tier: rewardTier,
          source: "referral_reward",
          granted_reason: `campaign:${campaignSnap.id}`,
          granted_at: now,
          expires_at: expiresAt,
        });
      }

      tx.update(referralRef, {
        status: "rewarded",
        processed_at: now,
      });

      campaignInc.qualified_referral_count = admin.firestore.FieldValue.increment(1);
      campaignInc.reward_granted_count = admin.firestore.FieldValue.increment(1);
      dailyInc.qualified_referral_count = admin.firestore.FieldValue.increment(1);
      dailyInc.reward_granted_count = admin.firestore.FieldValue.increment(1);
      tx.set(campaignSnap.ref, campaignInc, { merge: true });
      tx.set(dailyRef, dailyInc, { merge: true });
    });
  });

// -----------------------------------------------------------------------------
// logCampaignEvent (callable)
//
// Lightweight per-region engagement logger for impressions and clicks on a
// campaign (e.g. a promo banner shown / tapped). Increments the campaign's live
// counters and the campaign+region daily rollup. Auth-gated to keep bots out.
//
// Note: at very high impression volume, prefer batching several impressions
// into one call from the client (pass `count`) rather than one call per view.
// -----------------------------------------------------------------------------
const VALID_LOG_EVENTS = new Set(["impression", "click"]);
exports.logCampaignEvent = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const { campaignRefPath, eventType } = request.data || {};
  const region = typeof (request.data && request.data.region) === "string"
    ? request.data.region.slice(0, 120)
    : "unknown";
  const count = Math.min(Math.max(Number(request.data && request.data.count) || 1, 1), 100);

  if (!campaignRefPath || typeof campaignRefPath !== "string") {
    throw new HttpsError("invalid-argument", "campaignRefPath is required.");
  }
  if (!VALID_LOG_EVENTS.has(eventType)) {
    throw new HttpsError("invalid-argument", "eventType must be 'impression' or 'click'.");
  }

  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();
  const campaignRef = db.doc(campaignRefPath);
  const field = eventType === "impression" ? "impression_count" : "click_count";
  const dailyId = `${campaignRef.id}_${regionSlug(region)}_${ymd(now.toDate())}`;

  const batch = db.batch();
  batch.set(campaignRef, { [field]: admin.firestore.FieldValue.increment(count) }, { merge: true });
  batch.set(
    db.collection("campaign_analytics_daily").doc(dailyId),
    {
      campaign_ref: campaignRef,
      region,
      date: ymd(now.toDate()),
      date_ts: now,
      [field]: admin.firestore.FieldValue.increment(count),
    },
    { merge: true },
  );
  await batch.commit();
  return { ok: true };
});

// -----------------------------------------------------------------------------
// expireCampaigns (scheduled)
//
// Flips active campaigns to 'ended' once end_date passes - the campaign
// equivalent of checkAndExpireBeacons, and the same 5-minute cadence.
// -----------------------------------------------------------------------------
exports.expireCampaigns = functions.pubsub
  .schedule("*/5 * * * *")
  .onRun(async () => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    const expired = await db
      .collection("marketing_campaigns")
      .where("status", "==", "active")
      .where("end_date", "<", now)
      .get();

    if (expired.empty) {
      console.log("No campaigns to expire.");
      return null;
    }

    const batch = db.batch();
    expired.docs.forEach((doc) => {
      batch.update(doc.ref, { status: "ended", updated_at: now });
    });
    await batch.commit();
    console.log(`Ended ${expired.size} expired campaigns.`);
    return null;
  });
