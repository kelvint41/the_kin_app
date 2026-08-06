// Manually invokes the real nightly Kindex recompute (this directory's own
// business_kindex_nightly.js exports recomputeAll via _internals
// specifically for this) instead of waiting for its 2:00 AM
// America/Chicago Cloud Scheduler trigger.
//
// Lives in this directory rather than firebase/scripts/ deliberately: the
// two directories keep separate node_modules installs of firebase-admin,
// and Firestore's own client rejects a Timestamp built by one copy when
// passed to a query running through the other ("Detected an object of
// type Timestamp that doesn't match the expected instance") - requiring
// business_kindex_nightly.js from here means every admin.* call resolves
// to the same install it already uses internally.
//
// Needed today because the 569 newly-seeded NORBCC New Orleans businesses
// (and the earlier GA/IL test batch before its first nightly run) have no
// kindex_score field at all yet - it's only ever written by this job, never
// at seed time, so "why don't these show a 500 starting score" is a timing
// gap, not missing data. This just runs the same real logic early instead
// of leaving it to the next scheduled run.
//
// Safe to run anytime, including outside the normal 2 AM window - it's the
// same idempotent recompute over the whole `businesses` collection the
// schedule already runs nightly, not a special one-off pass scoped to any
// particular batch.
//
// Usage (from this directory):
//   GOOGLE_APPLICATION_CREDENTIALS=../scripts/serviceAccountKey.json node run_kindex_nightly_now.js

const admin = require('firebase-admin');
if (!admin.apps.length) {
  admin.initializeApp();
}

const { _internals } = require('./business_kindex_nightly.js');

async function main() {
  const db = admin.firestore();
  console.log('Running the real business_kindex_nightly recompute now...');
  const result = await _internals.recomputeAll(db, Date.now());
  console.log(`Done: ${result.updated} of ${result.businesses} businesses updated.`);
}

main().catch((err) => { console.error(err); process.exit(1); });
