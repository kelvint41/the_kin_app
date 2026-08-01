// One-off backfill for the 4 businesses.address / businesses.business_location
// documents that came from the BOB certification list (no address, no
// GeoPoint) and were therefore invisible on GoogleMapPage and in NearbyFeed.
//
// Addresses below were sourced by hand (business website footers, a Dallas
// City Hall MWBE PDF cross-matched by email address, BBB/AIA listings) - see
// the accompanying task notes. Two of the four had no discoverable street
// address anywhere and are intentionally left untouched: this script must
// NOT fall back to a zip or city centroid for them. A pin a mile off is
// worse than no pin - see the rejected "nudge co-located pins apart" idea
// and the removed hardcoded 'San Antonio' stamp in GoogleMapPage.
//
// Usage:
//   node backfill_missing_locations.js            # dry run - writes nothing
//   node backfill_missing_locations.js --commit    # applies the writes

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS
  || path.join(__dirname, 'serviceAccountKey.json');
const BUSINESSES = 'businesses';

const isCommit = process.argv.includes('--commit');

function loadServiceAccount() {
  if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error(`Missing service account key at ${SERVICE_ACCOUNT_PATH}.`);
    process.exit(1);
  }
  return require(SERVICE_ACCOUNT_PATH);
}

// Geocoded with the Maps Geocoding API using the same key the app's place
// picker already ships client-side (lib/pages/business_setup_page). Both
// resolved location_type: ROOFTOP.
const UPDATES = [
  {
    id: 'cNAvN5kHySHhOJ5Nhzjh',
    name: 'Sol Studio Architects, LLC',
    address: '1438 S Presa St, San Antonio, TX 78210',
    source: "solstudioarchitects.us homepage footer (business's own current site)",
    lat: 29.4061075,
    lng: -98.4843506,
    // Was 78215, from the BOB certification list. Three addresses were in
    // circulation for this business: the site footer (S Presa, 78210), a
    // BBB listing (824 Broadway St), and whatever 78215 implied. The
    // business's own current site wins over a 2020-vintage certification
    // roll, so the zip is reconciled to the address rather than the other
    // way round. EJ Smith's stored zip already agreed with its address.
    zip: '78210',
  },
  {
    id: 'xeyb8KXtibst9ZlRqCzh',
    name: 'EJ Smith Construction Company, LLC',
    address: '1707 N PanAm Expy, San Antonio, TX 78208',
    source: 'Dallas City Hall MWBE directory PDF, row matched on email ewalker@ejsmithind.com',
    lat: 29.4392086,
    lng: -98.469864,
    zip: '78208',
  },
];

// Left untouched - no discoverable street address:
//   1ITbZVcRERKyG1HX3tKt  R. Smith Consulting & Design, LLC (Live Oak, 78233)
//   uFZdHVPYecPLv867B5hA  Sparkling Clean House Cleaning Source (San Antonio, 78254)

async function main() {
  const serviceAccount = loadServiceAccount();
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  const db = admin.firestore();

  console.log(`Project: ${serviceAccount.project_id}`);
  console.log(`Mode: ${isCommit ? 'COMMIT (will write to Firestore)' : 'DRY RUN (no writes)'}`);
  console.log();

  for (const u of UPDATES) {
    const ref = db.collection(BUSINESSES).doc(u.id);
    const snap = await ref.get();
    if (!snap.exists) {
      console.log(`SKIP ${u.id} - document no longer exists`);
      continue;
    }
    const data = snap.data();
    const patch = {};

    // Location is written only into an empty slot. If something already
    // put a GeoPoint here - a claim, a later correction, a rerun of this
    // script - it knows something this file doesn't, so leave it.
    if (data.business_location) {
      console.log(`SKIP location for ${u.id} (${data.business_name}) - business_location already set, not overwriting`);
    } else {
      patch.address = u.address;
      patch.business_location = new admin.firestore.GeoPoint(u.lat, u.lng);
    }

    // The zip is reconciled separately, and only once the stored address is
    // the one sourced here - that's what makes it this script's record to
    // correct rather than someone else's. Nothing in lib/ renders the zip
    // today, so this is about the document not contradicting itself before
    // something does read it.
    const addressIsOurs = (patch.address ?? data.address) === u.address;
    if (addressIsOurs && data.zip_code_postcode !== u.zip) {
      patch.zip_code_postcode = u.zip;
    }

    if (Object.keys(patch).length === 0) {
      console.log(`  ${u.id} (${u.name}) already up to date.\n`);
      continue;
    }

    console.log(`${u.id} - ${u.name}`);
    for (const [field, value] of Object.entries(patch)) {
      const before = field === 'business_location'
        ? (data[field] ? `GeoPoint(${data[field].latitude}, ${data[field].longitude})` : 'unset')
        : (data[field] ?? 'unset');
      const after = field === 'business_location'
        ? `GeoPoint(${value.latitude}, ${value.longitude})`
        : `"${value}"`;
      console.log(`  ${field}: ${before} -> ${after}`);
    }
    console.log(`  source: ${u.source}`);

    if (isCommit) {
      await ref.update(patch);
      console.log('  written.');
    }
    console.log();
  }

  console.log(isCommit ? 'Done.' : 'Dry run complete. Re-run with --commit to write.');
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
