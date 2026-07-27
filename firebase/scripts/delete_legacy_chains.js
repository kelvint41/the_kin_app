// Removes the last documents left over from the original broken import - the
// ones still carrying 4-character "first 4 letters of the name" tickers.
//
// Run manually with a service account key, AFTER dedupe_businesses.js --commit.
//
// Why these documents are separable:
//   Every business in the current directory came from one of two imports. The
//   second (migration_data.json, via generate_tickers.js) produced 5-character
//   [A-Z0-9] tickers matching KindexTickerUtil. The first produced 4-character
//   tickers that collide badly and are not valid app tickers. After the dedupe
//   the only documents still holding a 4-character ticker are ones that exist
//   *solely* in that first import - they have no counterpart in
//   migration_data.json at all.
//
//   They are also, exactly, the set flagged is_black_owned == true, because
//   that first source file set the flag TRUE on every row indiscriminately.
//   See the memory note is-black-owned-flag-is-unreliable.
//
// Usage:
//   node delete_legacy_chains.js            # dry run - writes nothing
//   node delete_legacy_chains.js --commit   # deletes them
//
// Safety:
//   - Defaults to dry run; --commit is required to delete.
//   - Refuses to delete anything referenced by users.owned_business or
//     exchange_posts.business_ref.
//   - Refuses to delete a document whose ticker IS a valid 5-char ticker, so
//     it can never touch the migration_data.json set.
//   - Releases each deleted business's ticker_registry reservation in the same
//     batch, so a deleted business does not leave its symbol locked.
//   - Writes delete_legacy_chains_results.json listing every deleted document
//     in full, so the deletion is reversible from the log alone.

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS
  || path.join(__dirname, 'serviceAccountKey.json');
const RESULTS_LOG_PATH = path.join(__dirname, 'delete_legacy_chains_results.json');
const COLLECTION = 'businesses';
const TICKER_REGISTRY = 'ticker_registry';
const BATCH_SIZE = 200;

const VALID_TICKER = /^[A-Z0-9]{5}$/;

const isCommit = process.argv.includes('--commit');

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

function chunk(array, size) {
  const out = [];
  for (let i = 0; i < array.length; i += size) {
    out.push(array.slice(i, i + size));
  }
  return out;
}

async function findReferencedIds(db) {
  const referenced = new Map();
  const note = (id, where) => {
    if (!id) return;
    const existing = referenced.get(id) || [];
    existing.push(where);
    referenced.set(id, existing);
  };

  const users = await db.collection('users').get();
  users.forEach((doc) => {
    const ref = doc.get('owned_business');
    if (ref && ref.id) note(ref.id, `users/${doc.id}.owned_business`);
  });

  const posts = await db.collection('exchange_posts').get();
  posts.forEach((doc) => {
    const ref = doc.get('business_ref');
    if (ref && ref.id) note(ref.id, `exchange_posts/${doc.id}.business_ref`);
  });

  return referenced;
}

async function main() {
  const serviceAccount = loadServiceAccount();
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  const db = admin.firestore();

  console.log(`Project: ${serviceAccount.project_id}`);
  console.log(`Collection: ${COLLECTION}`);
  console.log(`Mode: ${isCommit ? 'COMMIT (will delete)' : 'DRY RUN (no writes)'}`);

  const referenced = await findReferencedIds(db);
  const snapshot = await db.collection(COLLECTION).get();
  const docs = [];
  snapshot.forEach((doc) => docs.push({ id: doc.id, data: doc.data() }));
  console.log(`\nLoaded ${docs.length} business documents.`);

  const targets = [];
  const protectedHits = [];
  for (const doc of docs) {
    const ticker = (doc.data.ticker_symbol || '').trim();
    // Never touch the migration_data.json set.
    if (VALID_TICKER.test(ticker)) continue;
    if (referenced.has(doc.id)) {
      protectedHits.push({ doc, where: referenced.get(doc.id) });
      continue;
    }
    targets.push(doc);
  }

  console.log(`\nLegacy-ticker documents to delete: ${targets.length}`);
  console.log(`Documents remaining after deletion: ${docs.length - targets.length}`);

  if (protectedHits.length > 0) {
    console.log(`\nSKIPPED - referenced elsewhere (${protectedHits.length}):`);
    protectedHits.forEach((p) => console.log(
      `  ${p.doc.data.business_name} [${p.doc.id}] <- ${p.where.join(', ')}`
    ));
  }

  console.log('\nFull list:');
  targets.forEach((t, i) => {
    const d = t.data;
    console.log(
      `  ${String(i + 1).padStart(2)}. ${JSON.stringify(d.ticker_symbol)}`.padEnd(14)
      + ` ${d.business_name} (${d.city}) | black_owned=${d.is_black_owned}`
      + ` | ${d.website || '(no website)'}`
    );
  });

  const results = {
    mode: isCommit ? 'commit' : 'dry-run',
    deleted_count: targets.length,
    // Full document bodies, so this log alone is enough to restore.
    deleted: targets.map((t) => ({ id: t.id, data: t.data })),
    skipped_referenced: protectedHits.map((p) => ({
      id: p.doc.id,
      business_name: p.doc.data.business_name,
      referenced_by: p.where,
    })),
  };

  if (!isCommit) {
    fs.writeFileSync(RESULTS_LOG_PATH, JSON.stringify(results, null, 2));
    console.log(`\nPlan written to ${RESULTS_LOG_PATH}`);
    console.log('Dry run only - re-run with --commit to delete.');
    return;
  }

  let done = 0;
  for (const group of chunk(targets, BATCH_SIZE)) {
    const batch = db.batch();
    for (const target of group) {
      batch.delete(db.collection(COLLECTION).doc(target.id));
      // Release the symbol if this business held it, so it does not stay
      // locked against a future signup or re-import.
      const ticker = (target.data.ticker_symbol || '').trim();
      if (ticker) {
        batch.delete(db.collection(TICKER_REGISTRY).doc(ticker));
      }
    }
    await batch.commit();
    done += group.length;
    console.log(`Deleted ${done}/${targets.length}.`);
  }

  fs.writeFileSync(RESULTS_LOG_PATH, JSON.stringify(results, null, 2));
  console.log(`\nDone. Deleted ${targets.length} document(s).`);
  console.log(`Full bodies logged to ${RESULTS_LOG_PATH}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
