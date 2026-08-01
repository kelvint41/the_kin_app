// One-off backfill for `signup_feed`, which had no writer until
// signup_feed_sync.js (syncSignupFeed) was added: the Executive Dashboard's
// "Total Users" KPI counts this collection instead of `users` (see the
// comment on that KPI card - `users` can't be counted directly under the
// current security rules), so it was reporting whatever handful of docs
// existed there from manual seeding/testing rather than the real signup
// count.
//
// This backfills one signup_feed doc per existing `users` doc that doesn't
// already have one, using the same doc-id-equals-user-id scheme the new
// trigger uses, so it's safe to re-run - already-backfilled users are
// skipped, not duplicated.
//
// Usage:
//   node backfill_signup_feed.js            # dry run - writes nothing
//   node backfill_signup_feed.js --commit    # applies the writes

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS
  || path.join(__dirname, 'serviceAccountKey.json');

const isCommit = process.argv.includes('--commit');

function loadServiceAccount() {
  if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error(`Missing service account key at ${SERVICE_ACCOUNT_PATH}.`);
    process.exit(1);
  }
  return require(SERVICE_ACCOUNT_PATH);
}

async function main() {
  admin.initializeApp({ credential: admin.credential.cert(loadServiceAccount()) });
  const db = admin.firestore();

  const [usersSnap, existingFeedSnap] = await Promise.all([
    db.collection('users').get(),
    db.collection('signup_feed').get(),
  ]);

  const existingFeedIds = new Set(existingFeedSnap.docs.map((d) => d.id));

  const toCreate = usersSnap.docs.filter((d) => !existingFeedIds.has(d.id));

  console.log(`users: ${usersSnap.size}`);
  console.log(`signup_feed already present: ${existingFeedSnap.size}`);
  console.log(`signup_feed missing (would create): ${toCreate.length}`);

  for (const doc of toCreate) {
    const u = doc.data();
    console.log(
      `  ${doc.id}  ${u.display_name || '(no display name)'}  ` +
      `tier=${u.subscription_status || 'Free'}`,
    );
  }

  if (!isCommit) {
    console.log('\nDry run only. Re-run with --commit to write.');
    process.exit(0);
  }

  let batch = db.batch();
  let count = 0;
  for (const doc of toCreate) {
    const u = doc.data();
    batch.set(db.collection('signup_feed').doc(doc.id), {
      user_ref: doc.ref,
      display_name: u.display_name || '',
      subscription_status: u.subscription_status || 'Free',
      timestamp: u.created_time || admin.firestore.FieldValue.serverTimestamp(),
    });
    count += 1;
    if (count % 400 === 0) {
      await batch.commit();
      batch = db.batch();
    }
  }
  if (count % 400 !== 0) {
    await batch.commit();
  }

  console.log(`\nCreated ${toCreate.length} signup_feed doc(s).`);
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
