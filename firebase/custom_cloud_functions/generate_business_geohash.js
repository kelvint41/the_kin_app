const functions = require("firebase-functions");
const admin = require("firebase-admin");
const geofire = require("geofire-common");

if (!admin.apps.length) {
  admin.initializeApp();
}

// Writes a `geohash` string (precision 9, ≈ 5 m accuracy) to every business
// document whenever `business_location` is created or changed. The Flutter
// map page uses this field to query businesses within a geographic prefix
// rather than loading the entire collection.
//
// Guard: if the location hasn't changed AND geohash is already set, we skip
// the update entirely — this prevents the update() call below from
// re-triggering the function in an infinite loop.
exports.generateBusinessGeohash = functions.firestore
  .document("businesses/{docId}")
  .onWrite(async (change, context) => {
    if (!change.after.exists) return null;

    const after = change.after.data();
    const location = after.business_location;

    if (!location || typeof location.latitude !== "number") return null;

    if (change.before.exists) {
      const before = change.before.data();
      const prevLoc = before.business_location;
      if (
        after.geohash &&
        prevLoc &&
        prevLoc.latitude === location.latitude &&
        prevLoc.longitude === location.longitude
      ) {
        return null;
      }
    }

    const geohash = geofire.geohashForLocation([
      location.latitude,
      location.longitude,
    ]);

    return change.after.ref.update({ geohash });
  });
