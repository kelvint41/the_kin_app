const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}
const { createNotification } = require("./notifications.js");

/**
 * Community Events server side. See job_board.js for why these were ported
 * out of the never-deployed firebase/functions/src/ TypeScript.
 *
 * The original also had a notifyEventPosted that fanned out to up to 50
 * users where `lookingForCommunityEvents == true`. No screen in this app
 * ever writes that field, so it would have notified nobody; broadcasting to
 * every user instead is not a substitute for an opt-in, so that handler is
 * deliberately not ported. It needs a real audience signal first.
 */

/**
 * Tells a business owner that another business wants to partner on an event.
 *
 * Only the recipient is notified - the sender already knows they sent it,
 * and firestore.rules only lets the recipient act on it (accept/decline).
 */
exports.notifyPartnershipRequest = onDocumentCreated(
  "partnership_requests/{requestId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return null;
    const request = snap.data();
    const db = admin.firestore();

    const toBusinessRef = request.toBusinessRef;
    if (!toBusinessRef) {
      console.log(
        `partnership_requests/${event.params.requestId} has no toBusinessRef - skipping.`,
      );
      return null;
    }

    const recipientSnap = await toBusinessRef.get();
    const recipientOwnerRef = recipientSnap.exists
      ? recipientSnap.data().owner_ref
      : null;
    if (!recipientOwnerRef) {
      console.log(
        `No owner_ref on business ${toBusinessRef.id} - skipping partnership notification.`,
      );
      return null;
    }

    // Sender name is best-effort: the notification is still worth sending
    // without it, so a missing/removed sender business degrades to a
    // generic line rather than dropping the notification.
    let senderName = "Another business";
    const fromBusinessRef = request.fromBusinessRef;
    if (fromBusinessRef) {
      const senderSnap = await fromBusinessRef.get();
      if (senderSnap.exists && senderSnap.data().business_name) {
        senderName = senderSnap.data().business_name;
      }
    }

    await createNotification(db, {
      userRef: recipientOwnerRef,
      type: "partnership_request",
      title: "Partnership opportunity",
      body: `${senderName} wants to partner with you on a community event.`,
      routeName: "EventManagement",
    });

    return null;
  },
);
