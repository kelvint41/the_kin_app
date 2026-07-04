const functions = require("firebase-functions");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

exports.checkAndExpireBeacons = functions.pubsub
  .schedule("*/5 * * * *")
  .onRun(async (context) => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    // Query for businesses where a beacon is active but expired
    const expiredQuery = await db
      .collection("businesses")
      .where("has_flash_beacon", "==", true)
      .where("flash_beacon_expires_at", "<", now)
      .get();

    if (expiredQuery.empty) {
      console.log("No expired beacons found.");
      return null;
    }

    const batch = db.batch();

    // Automatically toggle active status off
    expiredQuery.docs.forEach((doc) => {
      batch.update(doc.ref, { has_flash_beacon: false });
    });

    await batch.commit();
    console.log(`Successfully expired ${expiredQuery.size} flash beacons.`);
    return null;
  });
