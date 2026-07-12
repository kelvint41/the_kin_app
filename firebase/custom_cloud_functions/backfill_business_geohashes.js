/**
 * One-time migration: computes and writes the `geohash` field for any
 * business document that already has `business_location` but no `geohash`.
 *
 * Run once after deploying the generateBusinessGeohash Cloud Function:
 *   cd firebase/custom_cloud_functions
 *   npm install
 *   node backfill_business_geohashes.js
 *
 * Safe to re-run — documents that already have a geohash are skipped.
 * New businesses registered after deploying kin_services.dart get their
 * geohash at write time and don't need this script.
 */

const admin = require("firebase-admin");
const geofire = require("geofire-common");

const serviceAccount = require("../../firebase-service-account.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function main() {
  const snap = await db
    .collection("businesses")
    .where("business_location", "!=", null)
    .get();

  if (snap.empty) {
    console.log("No businesses found.");
    return;
  }

  const batch = db.batch();
  let count = 0;

  snap.docs.forEach((doc) => {
    const data = doc.data();
    if (data.geohash) return; // already migrated

    const loc = data.business_location;
    if (!loc || typeof loc.latitude !== "number") return;

    const geohash = geofire.geohashForLocation([loc.latitude, loc.longitude]);
    batch.update(doc.ref, { geohash });
    count++;

    // Firestore batches are capped at 500 writes — for large datasets
    // you'd need to commit and start a new batch here. For MVP scale
    // (< 500 SA businesses) a single batch is sufficient.
  });

  if (count === 0) {
    console.log("All businesses already have a geohash. Nothing to do.");
    return;
  }

  await batch.commit();
  console.log(`Backfilled geohash on ${count} business document(s).`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
