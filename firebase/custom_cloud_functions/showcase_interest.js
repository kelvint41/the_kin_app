const functions = require("firebase-functions");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

// A second, independent onCreate trigger on UserEngagementEvents, alongside
// kindex_engine.js's processUserEngagementEvent. Both fire on every event;
// this one only cares about reactions whose target_ref points into
// business_items (Showcase items) - the same five react_* event types are
// also used on Exchange posts (see kQuickReactions in
// exchange_feed_item_widget.dart), so the collection check on target_ref is
// what tells the two apart, not the event_type itself. No kindex_config
// change was needed to add this: those five reaction types are already
// weighted for Exchange, and this function reuses them as-is rather than
// introducing a new event_type.
//
// Uses its own `interest_counted` marker, distinct from kindex_engine's
// `status`, so Cloud Functions' at-least-once redelivery can't
// double-increment interest_count - each trigger tracks its own
// idempotency independently on the same event doc.
// Testable core, separate from the trigger wrapper below - takes a
// document reference rather than a Firestore-provided snapshot so tests
// can call it directly against the emulator the same way an onCreate
// invocation would, without depending on firebase-functions' internal
// event-shape plumbing.
async function processEvent(eventRef) {
  const db = admin.firestore();
  await db.runTransaction(async (tx) => {
    const eventSnap = await tx.get(eventRef);
    const event = eventSnap.data();
    if (!event) return;
    if (event.interest_counted === true) return;

    const itemRef = event.target_ref;
    if (!itemRef || itemRef.parent.id !== "business_items") {
      tx.update(eventRef, { interest_counted: true });
      return;
    }

    tx.update(itemRef, {
      interest_count: admin.firestore.FieldValue.increment(1),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.update(eventRef, { interest_counted: true });
  });
}

exports.recordItemInterest = functions.firestore
  .document("UserEngagementEvents/{eventId}")
  .onCreate((snapshot) => processEvent(snapshot.ref));

exports._internals = { processEvent };
