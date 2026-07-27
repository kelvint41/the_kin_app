const functions = require("firebase-functions");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

const WEIGHTS_DOC_PATH = { collection: "kindex_config", doc: "scoring_weights" };
const WEIGHTS_CACHE_TTL_MS = 5 * 60 * 1000;

let cachedWeights = null;
let cachedWeightsAt = 0;

// Scoring weights live in Firestore (kindex_config/scoring_weights) rather
// than as constants here, so retention strategy can be tuned from the
// console without a redeploy. Cached in-memory per function instance with
// a bounded TTL so per-event processing doesn't cost an extra Firestore
// read at scale.
async function getScoringWeights(db) {
  const now = Date.now();
  if (cachedWeights && now - cachedWeightsAt < WEIGHTS_CACHE_TTL_MS) {
    return cachedWeights;
  }
  const snap = await db
    .collection(WEIGHTS_DOC_PATH.collection)
    .doc(WEIGHTS_DOC_PATH.doc)
    .get();
  cachedWeights = snap.exists ? snap.data() : {};
  cachedWeightsAt = now;
  return cachedWeights;
}

exports.processUserEngagementEvent = functions.firestore
  .document("UserEngagementEvents/{eventId}")
  .onCreate(async (snapshot) => {
    const db = admin.firestore();
    const eventRef = snapshot.ref;
    const weights = await getScoringWeights(db);

    await db.runTransaction(async (tx) => {
      const eventSnap = await tx.get(eventRef);
      const event = eventSnap.data();

      // Cloud Functions triggers are at-least-once: the same event can be
      // redelivered after a crash or timeout. Re-checking status inside the
      // transaction makes reprocessing a safe no-op instead of a double
      // score increment.
      if (!event || event.status !== "pending") {
        return;
      }

      const userRef = event.user_ref;
      if (!userRef) {
        tx.update(eventRef, {
          status: "rejected",
          error: "missing user_ref",
          processed_at: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
      }

      const points = weights[event.event_type];
      if (typeof points !== "number") {
        tx.update(eventRef, {
          status: "rejected",
          error: `unknown event_type: ${event.event_type}`,
          processed_at: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
      }

      const scoreRef = db.collection("KindexScores").doc(userRef.id);
      const scoreSnap = await tx.get(scoreRef);
      const scoreData = scoreSnap.exists ? scoreSnap.data() : {};

      // Denormalize the user's ticker symbol onto the score doc so
      // ticker-style UI (e.g. the onboarding Kindex ticker) can read it
      // without a client-side query against the self-only `users`
      // collection. Only fetched once - skipped on later events once it's
      // already cached here, to avoid an extra read on every event.
      let tickerSymbol = scoreData.ticker_symbol || null;
      if (!tickerSymbol) {
        const userSnap = await tx.get(userRef);
        tickerSymbol = userSnap.exists ? userSnap.data().ticker_symbol || null : null;
      }

      // `score` and `is_trending_up` are deliberately NOT written here
      // any more. They are owned by recomputeCustomerKindexScores
      // (customer_kindex_nightly.js), which moves the score toward a
      // windowed target by a capped amount each night and applies
      // inactivity decay. If this trigger also incremented the score
      // per-event, that smoothing would be meaningless - the score would
      // still jump the instant an event landed, and the nightly job would
      // just be fighting it. There must be exactly one writer.
      //
      // This function remains the validator and audit trail: it rejects
      // unknown event types, stamps points_awarded, and keeps the
      // ticker_symbol denormalization the ticker UI depends on. The
      // nightly job only counts events this one marked "processed".
      tx.set(
        scoreRef,
        {
          user_ref: userRef,
          ticker_symbol: tickerSymbol,
          last_event_id: eventRef.id,
          last_updated: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      tx.update(eventRef, {
        status: "processed",
        points_awarded: points,
        weight_version: String(cachedWeightsAt),
        processed_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
  });
