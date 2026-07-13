// One-time bootstrap script — NOT a Cloud Function, not required by
// index.js, so `firebase deploy --only functions` never picks it up.
// Run manually once (with GOOGLE_APPLICATION_CREDENTIALS pointed at a
// service account, or via `firebase functions:shell`-adjacent auth) to
// create the initial scoring weights doc:
//
//   node seed_kindex_config.js
//
// Afterwards, adjust weights directly in the Firebase Console at
// kindex_config/scoring_weights — no redeploy needed.

const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

const DEFAULT_WEIGHTS = {
  like: 1,
  share: 5,
  post: 10,
  comment: 2,
  checkin: 15, // Physical check-in via daily code — highest-trust engagement signal
};

async function seed() {
  const db = admin.firestore();
  const ref = db.collection("kindex_config").doc("scoring_weights");
  const existing = await ref.get();
  if (existing.exists) {
    console.log("kindex_config/scoring_weights already exists, skipping.");
    console.log(existing.data());
    return;
  }
  await ref.set(DEFAULT_WEIGHTS);
  console.log("Seeded kindex_config/scoring_weights:", DEFAULT_WEIGHTS);
}

seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
