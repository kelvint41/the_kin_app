const functions = require("firebase-functions");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

// Returns today's date string in UTC, e.g. "2026-07-13"
function todayUtc() {
  return new Date().toISOString().slice(0, 10);
}

// Returns a random 4-digit code string, never starting with 0 (1000–9999)
function randomCode() {
  return String(Math.floor(1000 + Math.random() * 9000));
}

// Scheduled: runs at midnight UTC every day.
// Iterates all published businesses in batches and writes a fresh code
// to daily_codes/{businessId}. Each doc is a full overwrite (set) so
// prior codes are atomically replaced and re-reads never see stale data.
exports.rotateDailyCodes = functions.pubsub
  .schedule("0 0 * * *")
  .timeZone("UTC")
  .onRun(async () => {
    const db = admin.firestore();
    const today = todayUtc();

    const endOfDay = new Date();
    endOfDay.setUTCHours(23, 59, 59, 999);
    const expiresAt = admin.firestore.Timestamp.fromDate(endOfDay);

    const BATCH_SIZE = 400; // Firestore batch write limit is 500; keep headroom
    let baseQuery = db
      .collection("businesses")
      .where("is_published", "==", true)
      .orderBy("__name__")
      .limit(BATCH_SIZE);

    let lastDoc = null;
    let totalRotated = 0;

    for (;;) {
      const q = lastDoc ? baseQuery.startAfter(lastDoc) : baseQuery;
      const snapshot = await q.get();
      if (snapshot.empty) break;

      const batch = db.batch();
      snapshot.docs.forEach((bizDoc) => {
        batch.set(db.collection("daily_codes").doc(bizDoc.id), {
          business_ref: bizDoc.ref,
          code: randomCode(),
          date: today,
          expires_at: expiresAt,
          generated_at: admin.firestore.FieldValue.serverTimestamp(),
          use_count: 0,
        });
      });

      await batch.commit();
      totalRotated += snapshot.docs.length;
      lastDoc = snapshot.docs[snapshot.docs.length - 1];
    }

    console.log(`[rotateDailyCodes] rotated ${totalRotated} codes for ${today}`);
    return null;
  });

// Callable: business owner fetches their own check-in code for display.
// Generates a code on demand if the scheduler hasn't run yet today
// (e.g. a newly published business or the function's first deployment day).
exports.getMyCheckinCode = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be signed in.");
  }

  const { businessId } = data || {};
  if (!businessId || typeof businessId !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "businessId required.");
  }

  const db = admin.firestore();
  const today = todayUtc();

  // Verify caller owns this business before revealing the code.
  const bizSnap = await db.collection("businesses").doc(businessId).get();
  if (!bizSnap.exists) {
    throw new functions.https.HttpsError("not-found", "Business not found.");
  }
  const bizData = bizSnap.data();
  const ownerRef = bizData.owner_ref;
  if (!ownerRef || ownerRef.id !== context.auth.uid) {
    throw new functions.https.HttpsError("permission-denied", "You do not own this business.");
  }

  const codeRef = db.collection("daily_codes").doc(businessId);
  const codeSnap = await codeRef.get();

  // Lazily generate if today's code is missing (new business or cold start).
  if (!codeSnap.exists || codeSnap.data().date !== today) {
    const endOfDay = new Date();
    endOfDay.setUTCHours(23, 59, 59, 999);
    const newCode = randomCode();
    await codeRef.set({
      business_ref: bizSnap.ref,
      code: newCode,
      date: today,
      expires_at: admin.firestore.Timestamp.fromDate(endOfDay),
      generated_at: admin.firestore.FieldValue.serverTimestamp(),
      use_count: 0,
    });
    return { code: newCode, date: today };
  }

  const { code, use_count: useCount } = codeSnap.data();
  return { code, date: today, use_count: useCount };
});
