const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
  let firestore = admin.firestore();
  let userRef = firestore.doc("users/" + user.uid);
  try {
    await userRef.delete();
  } catch (error) {
    functions.logger.error("Failed to delete Firestore user document", {
      uid: user.uid,
      error: error instanceof Error ? error.message : String(error),
    });
  }
});
