const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}
const { encodeGeohash } = require("./geohash.js");

/**
 * Business coordinates are stored inconsistently across the collection:
 * bulk-imported records populate `business_location` (a GeoPoint), while
 * some records only carry the separate `latitude`/`longitude` numbers, and
 * `coordinates` exists as a third variant. Mirrors businessCoords() in
 * visit_verification.js - try them in order rather than assuming one shape.
 */
function businessCoords(business) {
  const geo = business.business_location || business.coordinates;
  if (geo && typeof geo.latitude === "number" && typeof geo.longitude === "number") {
    if (!(geo.latitude === 0 && geo.longitude === 0)) {
      return { lat: geo.latitude, lng: geo.longitude };
    }
  }
  if (
    typeof business.latitude === "number" &&
    typeof business.longitude === "number" &&
    !(business.latitude === 0 && business.longitude === 0)
  ) {
    return { lat: business.latitude, lng: business.longitude };
  }
  return null;
}

/**
 * Only resolveBusinessSubmission (business_discovery.js) wrote a `geohash`
 * at creation time; every other creation path - most importantly
 * KinServices.registerBusiness's self-registration flow - left it unset,
 * making those businesses invisible to GoogleMapPageModel's geohash-prefix
 * query no matter how good their coordinates were. This backstops all
 * creation paths so nothing depends on remembering to set it inline.
 */
exports.setBusinessGeohashOnCreate = onDocumentCreated(
  "businesses/{businessId}",
  async (event) => {
    const data = event.data.data();
    if (data.geohash) {
      return null;
    }

    const coords = businessCoords(data);
    if (!coords) {
      console.log(
        `businesses/${event.params.businessId} created without usable coordinates - no geohash set.`,
      );
      return null;
    }

    await event.data.ref.update({ geohash: encodeGeohash(coords.lat, coords.lng) });
    return null;
  },
);
