// One-time backfill of the `role` field on the `users` collection.
//
// Stage 1 of making account role explicit. Every user gets an explicit
// role of 'customer' or 'business_owner', derived from whether they own a
// business:
//   owned_business is set  -> 'business_owner'
//   owned_business is null  -> 'customer'
//
// Not a Cloud Function - run manually from a developer machine with a
// service account key.
//
// Setup (one-time):
//   1. Firebase Console -> kinvest-build-app -> Project Settings ->
//      Service Accounts -> Generate new private key.
//   2. Save it as serviceAccountKey.json in this directory
//      (firebase/scripts/) - it's gitignored, never commit it.
//   3. cd firebase/scripts && npm install
//
// Usage:
//   node backfill_user_roles.js            # DRY RUN (default) - prints
//                                          # every intended change, writes
//                                          # nothing
//   node backfill_user_roles.js --commit   # actually writes to Firestore
//
// Safety:
//   - Defaults to dry run; --commit is required to write anything.
//   - Idempotent: users that already have a valid role ('customer' or
//     'business_owner') are skipped, so re-running (or running after a
//     partial failure) only fills gaps. A blank or invalid existing role
//     is treated as unset and corrected.
//   - Paginates the collection and writes in batches under Firestore's
//     500-write limit.
//   - Writes firebase/scripts/backfill_results.json (gitignored) logging
//     every user's id, the role assigned, and why - for traceability.

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS
  || path.join(__dirname, 'serviceAccountKey.json');
const RESULTS_LOG_PATH = path.join(__dirname, 'backfill_results.json');
const COLLECTION = 'users';
const PAGE_SIZE = 500;      // read page size
const BATCH_SIZE = 450;     // stays under Firestore's 500-write batch limit
const VALID_ROLES = new Set(['customer', 'business_owner']);

const isCommit = process.argv.includes('--commit');

function roleForUser(data) {
  // owned_business is a DocumentReference when set; null/undefined otherwise.
  return data.owned_business ? 'business_owner' : 'customer';
}

async function main() {
  if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error(`Service account key not found at ${SERVICE_ACCOUNT_PATH}.`);
    console.error('See the setup notes at the top of this script.');
    process.exit(1);
  }

  admin.initializeApp({
    credential: admin.credential.cert(require(SERVICE_ACCOUNT_PATH)),
  });
  const db = admin.firestore();

  console.log(
    isCommit
      ? '=== BACKFILL user roles: COMMIT MODE (writing to Firestore) ==='
      : '=== BACKFILL user roles: DRY RUN (no writes; pass --commit to write) ===',
  );

  const results = [];
  const counts = { customer: 0, business_owner: 0, skipped: 0, total: 0 };

  let batch = db.batch();
  let batchWrites = 0;
  let lastDoc = null;

  // Paginate by document ID so a large users collection is processed in
  // bounded memory.
  // eslint-disable-next-line no-constant-condition
  while (true) {
    let query = db
      .collection(COLLECTION)
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(PAGE_SIZE);
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }
    const snap = await query.get();
    if (snap.empty) break;

    for (const doc of snap.docs) {
      counts.total += 1;
      const data = doc.data();
      const existing = data.role;

      if (typeof existing === 'string' && VALID_ROLES.has(existing)) {
        counts.skipped += 1;
        continue; // already has a valid role - leave it
      }

      const role = roleForUser(data);
      counts[role] += 1;
      const reason = data.owned_business
        ? 'has owned_business'
        : 'no owned_business';
      results.push({ id: doc.id, role, reason, previousRole: existing || null });

      if (isCommit) {
        console.log(`  SET ${doc.id} -> role='${role}' (${reason})`);
        batch.update(doc.ref, { role });
        batchWrites += 1;
        if (batchWrites >= BATCH_SIZE) {
          await batch.commit();
          batch = db.batch();
          batchWrites = 0;
        }
      } else {
        console.log(`  WOULD SET ${doc.id} -> role='${role}' (${reason})`);
      }
    }

    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.size < PAGE_SIZE) break;
  }

  if (isCommit && batchWrites > 0) {
    await batch.commit();
  }

  fs.writeFileSync(RESULTS_LOG_PATH, JSON.stringify(results, null, 2));

  console.log('');
  console.log('--- Summary ---');
  console.log(`  Total users scanned:      ${counts.total}`);
  console.log(`  Already had valid role:   ${counts.skipped}`);
  console.log(`  -> business_owner:        ${counts.business_owner}`);
  console.log(`  -> customer:              ${counts.customer}`);
  console.log(
    `  ${isCommit ? 'Written' : 'Would write'}:             ${results.length}`,
  );
  console.log(`  Details logged to:        ${RESULTS_LOG_PATH}`);
  if (!isCommit) {
    console.log('');
    console.log('DRY RUN complete. Re-run with --commit to apply these changes.');
  }
}

main().catch((err) => {
  console.error('Backfill failed:', err);
  process.exit(1);
});
