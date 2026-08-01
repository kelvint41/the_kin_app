// One-time bootstrap for the `business_categories` collection - the
// shared, ever-growing vocabulary behind Business Setup's category
// dropdown and both "Add a Business" discovery dialogs (previously three
// independently hardcoded 5-value lists, now one live Firestore-backed
// list). Run once so the categories already in use don't disappear when
// the pickers switch from hardcoded to live:
//
//   node seed_business_categories.js
//
// Idempotent - doc ID is the normalized (lowercase, trimmed) category
// name, so re-running this is a same-content overwrite, never a
// duplicate.

const path = require('path');
const admin = require('firebase-admin');

const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS
  || path.join(__dirname, 'serviceAccountKey.json');

const serviceAccount = require(SERVICE_ACCOUNT_PATH);
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

const SEED_CATEGORIES = [
  'Salon & Beauty',
  'Restaurant & Food',
  'Retail',
  'Professional Services',
  'Health & Wellness',
];

function normalize(name) {
  return name.trim().toLowerCase();
}

async function seed() {
  const db = admin.firestore();
  const batch = db.batch();
  for (const displayName of SEED_CATEGORIES) {
    const ref = db.collection('business_categories').doc(normalize(displayName));
    batch.set(ref, {
      display_name: displayName,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  console.log(`Seeded ${SEED_CATEGORIES.length} business_categories.`);
}

seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
