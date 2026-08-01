/**
 * Backfills a `geohash` field on every `businesses` document that has a
 * usable location, so the map page can query by viewport instead of
 * reading the whole collection (see google_map_page_model.dart's
 * businessesForViewport / lib/flutter_flow/geohash_util.dart).
 *
 * Coordinate resolution mirrors businessCoords() in
 * firebase/custom_cloud_functions/visit_verification.js: geo fields are
 * inconsistent across the collection (bulk-imported rows populate
 * business_location, a GeoPoint; some only carry separate latitude/
 * longitude numbers; a few have a `coordinates` GeoPoint instead), so try
 * them in that order rather than assuming one shape. Per prior
 * investigation, business_location is the only one that's actually
 * populated on the current 500-doc set - the latitude/longitude scalars
 * read as 0,0 (empty) on all of them - but this still checks all three so
 * the script keeps working if that changes.
 *
 * Dry-run by default - prints what it would write without writing anything.
 * Pass --write to actually commit changes.
 *
 *   node backfill_business_geohashes.js            # dry run
 *   node backfill_business_geohashes.js --write     # writes geohash field
 *
 * Requires serviceAccountKey.json in this directory (see other scripts
 * here for the same convention) and NODE_PATH pointing at a node_modules
 * with firebase-admin installed, e.g.:
 *   NODE_PATH=../custom_cloud_functions/node_modules node backfill_business_geohashes.js
 */
const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const WRITE = process.argv.includes("--write");
const GEOHASH_PRECISION = 9;

// Same base32 alphabet/bit-interleaving algorithm as
// lib/flutter_flow/geohash_util.dart's encodeGeohash - kept in sync by
// hand since one is Dart and one is JS.
const BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz";

function encodeGeohash(lat, lng, precision = GEOHASH_PRECISION) {
  let latMin = -90, latMax = 90, lngMin = -180, lngMax = 180;
  let out = "";
  let bit = 0;
  let ch = 0;
  let evenBit = true;

  while (out.length < precision) {
    if (evenBit) {
      const mid = (lngMin + lngMax) / 2;
      if (lng >= mid) {
        ch |= 1 << (4 - bit);
        lngMin = mid;
      } else {
        lngMax = mid;
      }
    } else {
      const mid = (latMin + latMax) / 2;
      if (lat >= mid) {
        ch |= 1 << (4 - bit);
        latMin = mid;
      } else {
        latMax = mid;
      }
    }
    evenBit = !evenBit;
    if (bit < 4) {
      bit++;
    } else {
      out += BASE32[ch];
      bit = 0;
      ch = 0;
    }
  }
  return out;
}

function businessCoords(business) {
  const geo = business.business_location || business.coordinates;
  if (geo && typeof geo.latitude === "number" && typeof geo.longitude === "number") {
    return { lat: geo.latitude, lng: geo.longitude };
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

async function main() {
  console.log(`Running in ${WRITE ? "WRITE" : "DRY RUN"} mode.`);

  const snap = await db.collection("businesses").get();
  console.log(`Scanning ${snap.size} businesses...`);

  let toUpdate = 0;
  let alreadyHasGeohash = 0;
  let noLocation = 0;
  const results = [];

  let batch = db.batch();
  let batchCount = 0;

  for (const doc of snap.docs) {
    const business = doc.data();
    if (typeof business.geohash === "string" && business.geohash.length > 0) {
      alreadyHasGeohash++;
      continue;
    }

    const coords = businessCoords(business);
    if (!coords) {
      noLocation++;
      continue;
    }

    const geohash = encodeGeohash(coords.lat, coords.lng);
    results.push({ id: doc.id, name: business.business_name, geohash });
    toUpdate++;

    if (WRITE) {
      batch.update(doc.ref, { geohash });
      batchCount++;
      if (batchCount >= 400) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
      }
    }
  }

  if (WRITE && batchCount > 0) {
    await batch.commit();
  }

  const fs = require("fs");
  fs.writeFileSync(
    "backfill_geohash_results.json",
    JSON.stringify({ toUpdate, alreadyHasGeohash, noLocation, results }, null, 2),
  );

  console.log(`\nDone.`);
  console.log(`  Already had a geohash: ${alreadyHasGeohash}`);
  console.log(`  No usable location (skipped): ${noLocation}`);
  console.log(`  ${WRITE ? "Updated" : "Would update"}: ${toUpdate}`);
  console.log(`Full results in backfill_geohash_results.json`);
  if (!WRITE) {
    console.log(`\nThis was a dry run - re-run with --write to actually commit.`);
  }
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
