const functions = require("firebase-functions");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

// Returns today's date string in UTC, e.g. "2026-07-13"
function todayUtc() {
  return new Date().toISOString().slice(0, 10);
}

// Callable: customer submits a 4-digit check-in code for a business.
//
// Data: { businessId: string, code: string }
// Returns: { success: true, message: string }
//
// The dedup guard is the loyalty_checkins doc keyed by
// "{userId}_{businessId}_{date}". Checking for its existence inside a
// Firestore transaction makes the check-in atomic: a second concurrent
// call by the same user for the same business on the same day will lose
// the transaction and receive an "already-exists" error rather than
// accumulating duplicate engagement events.
exports.redeemCheckinCode = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be signed in.");
  }

  const { businessId, code } = data || {};
  if (!businessId || typeof businessId !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "businessId required.");
  }
  if (!code || typeof code !== "string" || !/^\d{4}$/.test(code)) {
    throw new functions.https.HttpsError("invalid-argument", "code must be a 4-digit string.");
  }

  const db = admin.firestore();
  const userId = context.auth.uid;
  const today = todayUtc();

  const userRef = db.collection("users").doc(userId);
  const bizRef = db.collection("businesses").doc(businessId);
  const codeRef = db.collection("daily_codes").doc(businessId);

  // Composite doc ID provides an atomic uniqueness constraint without a
  // query; Firestore guarantees only one doc can exist at a given path.
  const checkinDocId = `${userId}_${businessId}_${today}`;
  const checkinRef = db.collection("loyalty_checkins").doc(checkinDocId);

  await db.runTransaction(async (tx) => {
    const [codeSnap, checkinSnap] = await Promise.all([
      tx.get(codeRef),
      tx.get(checkinRef),
    ]);

    if (!codeSnap.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "No active check-in code for this business.",
      );
    }

    const codeData = codeSnap.data();

    if (codeData.date !== today) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Code has expired. A new code is available.",
      );
    }

    if (codeData.code !== code) {
      throw new functions.https.HttpsError("invalid-argument", "Incorrect code. Please try again.");
    }

    if (checkinSnap.exists) {
      throw new functions.https.HttpsError(
        "already-exists",
        "You have already checked in at this business today.",
      );
    }

    // Record dedup guard first so concurrent calls fail cleanly.
    tx.set(checkinRef, {
      user_ref: userRef,
      business_ref: bizRef,
      date: today,
      checked_in_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Increment the usage counter on the code doc for analytics.
    tx.update(codeRef, {
      use_count: admin.firestore.FieldValue.increment(1),
    });

    // Queue a KINDEX engagement event. The kindex_engine function picks
    // this up via Firestore trigger and awards points if "checkin" is
    // defined in kindex_config/scoring_weights.
    tx.set(db.collection("UserEngagementEvents").doc(), {
      user_ref: userRef,
      business_ref: bizRef,
      event_type: "checkin",
      status: "pending",
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return {
    success: true,
    message: "Check-in successful! Your loyalty points are being calculated.",
  };
});
