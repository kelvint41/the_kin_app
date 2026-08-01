const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}
const { createNotification } = require("./notifications.js");

/**
 * Notifies a claimant once their business claim is approved.
 *
 * claim_requests.status only ever moves 'pending' -> 'approved'/'rejected'
 * via an Admin SDK write (firestore.rules makes the collection write:
 * false for clients - see claim_requests_record.dart) - today that's a
 * manual review, not another Cloud Function, so this fires on whatever
 * touches the doc next, console edit included.
 */
exports.notifyClaimApproved = onDocumentUpdated(
  "claim_requests/{requestId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (before.status === after.status || after.status !== "approved") {
      return null;
    }

    const applicantUserId = after.applicant_user_id;
    if (!applicantUserId) {
      console.log(
        `claim_requests/${event.params.requestId} approved but has no applicant_user_id - skipping notification.`,
      );
      return null;
    }

    const db = admin.firestore();
    await createNotification(db, {
      userRef: db.collection("users").doc(applicantUserId),
      type: "claim_approved",
      title: "Business claim approved",
      body: `${after.business_name || "Your business"} is now verified. You can manage its profile from Owner Profile.`,
      routeName: "OwnerProfile",
    });

    return null;
  },
);
