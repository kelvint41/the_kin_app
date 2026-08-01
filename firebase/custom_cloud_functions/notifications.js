const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}
const { FieldValue } = require("firebase-admin/firestore");

/**
 * Writes one row to the `notifications` inbox collection for `userRef`.
 *
 * Server-side only by design - firestore.rules makes `notifications`
 * create: false for clients, so this is the single write path for every
 * notification in the app. Callers pass whatever Firestore instance/batch
 * context they already have (a plain `db`, or `tx`/`batch` if the caller is
 * already inside a transaction) via `writer`, so this can be dropped into
 * an existing transaction without a second round trip.
 */
async function createNotification(
  writer,
  { userRef, type, title, body, routeName },
) {
  if (!userRef) {
    console.log(`createNotification: no userRef for type "${type}" - skipping.`);
    return;
  }
  const db = admin.firestore();
  const ref = db.collection("notifications").doc();
  const data = {
    user_ref: userRef,
    type,
    title,
    body,
    route_name: routeName || null,
    is_read: false,
    created_at: FieldValue.serverTimestamp(),
  };
  if (typeof writer.set === "function") {
    // Transaction or WriteBatch - caller commits.
    writer.set(ref, data);
  } else {
    await ref.set(data);
  }
}

module.exports = { createNotification };
