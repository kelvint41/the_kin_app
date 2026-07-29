const functions = require("firebase-functions");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

// The Executive Dashboard's "Total Users" KPI reads a count against
// `signup_feed` rather than `users`, because `users` can only ever be read
// one document at a time (the security rule is auth.uid == doc), so an
// unscoped count against it is always rejected - see the comment on that
// KPI card. But nothing ever wrote to `signup_feed`, so the dashboard was
// reading an empty pipe: whatever handful of docs existed there (from
// manual seeding/testing) instead of the real signup count. This is the
// missing writer.
exports.syncSignupFeed = functions.firestore
  .document("users/{userId}")
  .onCreate(async (snapshot) => {
    const user = snapshot.data();

    await admin.firestore().collection("signup_feed").doc(snapshot.id).set({
      user_ref: snapshot.ref,
      display_name: user.display_name || "",
      subscription_status: user.subscription_status || "Free",
      timestamp: user.created_time || admin.firestore.FieldValue.serverTimestamp(),
    });
  });
