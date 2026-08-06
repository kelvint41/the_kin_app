const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Fans out a privacy-safe copy of each new KIN Quest check-in (uservisits)
 * to `quest_activity_feed`, so the map (kin_quest_map_demo_widget.dart) can
 * show "Jasmine just found Haus of Hairess" toasts to nearby users without
 * granting broad read access to uservisits itself.
 *
 * uservisits is deliberately locked down to "read your own, the business's
 * owner, or an admin" (see firestore.rules on uservisits, and its comment:
 * "Was world-readable... while no longer showing everyone else's") - these
 * are GPS-verified visits tied to a named account, and a live "who's
 * checking in nearby" feed built directly on that collection would undo
 * that. This mirrors signup_feed_sync.js's approach instead: a Cloud
 * Function is the only thing that reads the private collection, and it
 * writes out only the minimum a public feature needs - a first name and a
 * business, not the check-in record itself or which user it belongs to.
 *
 * One feed doc per visit (same id, so a re-run/replay can't double-write),
 * kept lean since kin_quest_map_demo_widget.dart only reads the last few
 * minutes of it - see this file's own doc comment on the collection for
 * why nothing prunes it yet.
 */
exports.syncQuestActivityFeed = onDocumentCreated(
  "uservisits/{visitId}",
  async (event) => {
    const visit = event.data?.data();
    if (!visit || !visit.business_ref || !visit.user_ref) return;

    const [userSnap, businessSnap] = await Promise.all([
      visit.user_ref.get(),
      visit.business_ref.get(),
    ]);

    const displayName = userSnap.exists ? userSnap.data().display_name : null;
    const firstName =
      typeof displayName === "string" && displayName.trim()
        ? displayName.trim().split(/\s+/)[0]
        : "Someone";

    const businessName = businessSnap.exists
      ? businessSnap.data().business_name || "a business"
      : "a business";

    await admin
      .firestore()
      .collection("quest_activity_feed")
      .doc(event.params.visitId)
      .set({
        business_ref: visit.business_ref,
        business_name: businessName,
        first_name: firstName,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });
  },
);
