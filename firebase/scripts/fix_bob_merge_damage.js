// Repairs two defects the BOB-list merge left in the `businesses`
// collection. Run manually with a service account key.
//
// 1. Shuffled categories.
//    On the records that came in via the BOB Bexar merge, `category` is
//    misaligned against the row it belongs to - the values are a permutation
//    of the correct set rather than random noise. "BBQ restaurant" landed on
//    a janitorial company while the actual BBQ restaurant got "Office
//    Supplies Wholesaler", and "Janitorial Services" landed on a
//    construction company. Every other record in the collection has a
//    category consistent with its description, so the damage is confined to
//    this merge.
//
//    This matters beyond the profile page: `category` drives the map's
//    filter chips (lib/services/business_category_filter.dart), so
//    Smith's Sanitation Services currently appears under "Restaurants".
//
//    The corrections below are taken from each business's own
//    `description`, which came from the certification listing and is
//    accurate. Records whose existing category already matches their
//    description are left alone, as are the two with no description
//    (MFAD Creative Group, Rylet Industries) - there is nothing to correct
//    them against, and guessing would be inventing data.
//
// 2. A coordinate outside Texas.
//    R. Smith Consulting & Design carries longitude +29.53. Longitude in
//    Texas is negative; a positive value puts the pin in Egypt, and
//    "Directions" would route a shopper across the Atlantic. The true
//    longitude is not recoverable - the value looks like a duplicated
//    latitude, and the record has no street address to geocode from - so
//    the coordinate is cleared rather than guessed. The business stays in
//    the directory and drops off the map, which is the honest outcome.
//    Both the map and the nearby feed already null-guard this.
//
// Usage:
//   node fix_bob_merge_damage.js            # dry run - writes nothing
//   node fix_bob_merge_damage.js --commit   # applies the corrections
//
// Safety:
//   - Defaults to dry run; --commit is required to write.
//   - Each correction is keyed by document ID *and* re-checked against the
//     business name before it is applied, so a stale ID cannot silently
//     rewrite the wrong business.
//   - Refuses to apply a category correction if the record's current
//     category is not the one recorded as wrong here - that would mean the
//     data moved under the script since this was written.

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS
  || path.join(__dirname, 'serviceAccountKey.json');
const RESULTS_LOG_PATH = path.join(__dirname, 'fix_bob_merge_results.json');
const COLLECTION = 'businesses';

const isCommit = process.argv.includes('--commit');

/// docId -> the correction. `was` is asserted before writing.
const CATEGORY_FIXES = {
  '1ITbZVcRERKyG1HX3tKt': {
    name: 'R. Smith Consulting & Design, LLC',
    was: 'Construction Services',
    now: 'Interior designer',
    because: 'Interior decorating, furniture refinishing, home staging',
  },
  '61bIkqgoVoLhOw3tMjJL': {
    name: 'Williams Tunneling Industries, Inc.',
    was: 'Environmental Consulting Services',
    now: 'Construction company',
    because: 'Sewer tunnels, shafts and drainage tunnels',
  },
  '70KCKcsAYHO9NzexXGS9': {
    name: 'The Big Bib, LLC',
    was: 'Office Supplies Wholesaler',
    now: 'Barbecue restaurant',
    because: 'BBQ restaurant - dine in, carry out and catering',
  },
  'D9a5AqGkZhvoVAkF6cmc': {
    name: 'SMR Security Services, LLC',
    was: 'Environmental Consulting Services',
    now: 'Security service',
    because: 'Guard and patrol security services',
  },
  'DJDdnOQPGfvHVMiD3ueE': {
    name: 'Techesive, LLC',
    was: 'Office Supplies Wholesaler',
    now: 'Computer consultant',
    because: 'Enterprise application integration, software/hardware engineering',
  },
  'HMbxYi45y6eFPpC2E6VE': {
    name: "Smith's Sanitation Services",
    was: 'BBQ restaurant',
    now: 'Janitorial service',
    because: 'Janitorial, carpet and upholstery cleaning, automotive detailing',
  },
  'cNAvN5kHySHhOJ5Nhzjh': {
    name: 'Sol Studio Architects, LLC',
    was: 'Health Care Services',
    now: 'Architect',
    because: 'Architectural services',
  },
  'cn0C2YAPFF5gocEB8BAl': {
    name: 'Gwendolen Wilder Author',
    was: 'Health Care Services',
    now: 'Author',
    because: 'Self-awareness and management training, books, journals',
  },
  'xeyb8KXtibst9ZlRqCzh': {
    name: 'EJ Smith Construction Company, LLC',
    was: 'Janitorial Services',
    now: 'Construction company',
    because: 'Commercial and institutional building construction',
  },
  'yz2XNZWJ2sovKbKr7naj': {
    name: 'Digital Information Security Solutions',
    was: 'Security Services',
    now: 'Computer consultant',
    because: 'Custom computer programming and related services',
  },
};

/// Coordinates to clear, with the value that makes them invalid.
const COORDINATE_FIXES = {
  '1ITbZVcRERKyG1HX3tKt': {
    name: 'R. Smith Consulting & Design, LLC',
    because: 'longitude +29.53 is positive - that is Egypt, not Texas',
  },
};

function loadServiceAccount() {
  if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error(
      `Missing service account key at ${SERVICE_ACCOUNT_PATH}.\n`
      + 'Generate one from Firebase Console -> Project Settings -> Service Accounts,\n'
      + 'save it as serviceAccountKey.json in this directory, or point\n'
      + 'GOOGLE_APPLICATION_CREDENTIALS at it.'
    );
    process.exit(1);
  }
  return require(SERVICE_ACCOUNT_PATH);
}

async function main() {
  const serviceAccount = loadServiceAccount();
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  const db = admin.firestore();

  console.log(`Project: ${serviceAccount.project_id}`);
  console.log(`Mode: ${isCommit ? 'COMMIT (will write to Firestore)' : 'DRY RUN (no writes)'}`);

  const ids = [...new Set([
    ...Object.keys(CATEGORY_FIXES),
    ...Object.keys(COORDINATE_FIXES),
  ])];
  const snaps = await db.getAll(...ids.map((id) => db.collection(COLLECTION).doc(id)));
  const byId = new Map(snaps.map((s) => [s.id, s]));

  const categoryPlan = [];
  const categorySkipped = [];
  for (const [id, fix] of Object.entries(CATEGORY_FIXES)) {
    const snap = byId.get(id);
    if (!snap || !snap.exists) {
      categorySkipped.push({ id, ...fix, reason: 'document no longer exists' });
      continue;
    }
    const data = snap.data();
    if (data.business_name !== fix.name) {
      categorySkipped.push({
        id, ...fix,
        reason: `name mismatch - document holds "${data.business_name}"`,
      });
      continue;
    }
    if (data.category === fix.now) {
      categorySkipped.push({ id, ...fix, reason: 'already correct' });
      continue;
    }
    if (data.category !== fix.was) {
      categorySkipped.push({
        id, ...fix,
        reason: `category is now "${data.category}", not the "${fix.was}" this fix was written against`,
      });
      continue;
    }
    categoryPlan.push({ id, ...fix });
  }

  const coordinatePlan = [];
  const coordinateSkipped = [];
  for (const [id, fix] of Object.entries(COORDINATE_FIXES)) {
    const snap = byId.get(id);
    if (!snap || !snap.exists) {
      coordinateSkipped.push({ id, ...fix, reason: 'document no longer exists' });
      continue;
    }
    const data = snap.data();
    if (data.business_name !== fix.name) {
      coordinateSkipped.push({
        id, ...fix,
        reason: `name mismatch - document holds "${data.business_name}"`,
      });
      continue;
    }
    if (!data.business_location) {
      coordinateSkipped.push({ id, ...fix, reason: 'coordinate already cleared' });
      continue;
    }
    coordinatePlan.push({
      id, ...fix,
      current: `${data.business_location.latitude}, ${data.business_location.longitude}`,
    });
  }

  console.log(`\nCategory corrections: ${categoryPlan.length}`);
  categoryPlan.forEach((f) => {
    console.log(`  ${f.name}`);
    console.log(`     "${f.was}"  ->  "${f.now}"`);
    console.log(`     because: ${f.because}`);
  });

  console.log(`\nCoordinates to clear: ${coordinatePlan.length}`);
  coordinatePlan.forEach((f) => {
    console.log(`  ${f.name} @ ${f.current}`);
    console.log(`     because: ${f.because}`);
  });

  const skipped = [...categorySkipped, ...coordinateSkipped];
  if (skipped.length > 0) {
    console.log(`\nSkipped: ${skipped.length}`);
    skipped.forEach((s) => console.log(`  ${s.name}: ${s.reason}`));
  }

  const results = {
    mode: isCommit ? 'commit' : 'dry-run',
    category_corrections: categoryPlan,
    coordinates_cleared: coordinatePlan,
    skipped,
  };

  if (!isCommit) {
    fs.writeFileSync(RESULTS_LOG_PATH, JSON.stringify(results, null, 2));
    console.log(`\nPlan written to ${RESULTS_LOG_PATH}`);
    console.log('Dry run only - re-run with --commit to apply.');
    return;
  }

  const batch = db.batch();
  categoryPlan.forEach((f) => {
    batch.update(db.collection(COLLECTION).doc(f.id), { category: f.now });
  });
  coordinatePlan.forEach((f) => {
    batch.update(db.collection(COLLECTION).doc(f.id), {
      business_location: admin.firestore.FieldValue.delete(),
      coordinates: admin.firestore.FieldValue.delete(),
    });
  });
  await batch.commit();

  fs.writeFileSync(RESULTS_LOG_PATH, JSON.stringify(results, null, 2));
  console.log(`\nDone. ${categoryPlan.length} category correction(s), `
    + `${coordinatePlan.length} coordinate(s) cleared.`);
  console.log(`Results written to ${RESULTS_LOG_PATH}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
