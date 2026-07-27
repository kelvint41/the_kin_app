// One-off cleanup of duplicate documents in the `businesses` Firestore
// collection. Not a Cloud Function - run manually from a developer machine
// with a service account key.
//
// Why this exists:
//   The collection was imported twice. The first pass used a naive
//   "first 4 letters of the business name" ticker scheme, which collides
//   badly (HAIR is shared by 10 businesses, TEXA by 7, SALO by 7) and
//   emits non-ASCII tickers like CHOP/RO'S. The second pass used
//   generate_tickers.js, which mirrors KindexTickerUtil's 5-char
//   [A-Z0-9] format. Because import_businesses.js checks idempotency by
//   ticker_symbol, regenerating the tickers made every record look new
//   and the whole file imported a second time.
//
//   The result is ~278 businesses present twice - once under a colliding
//   4-char ticker, once under a correct 5-char one.
//
// What it does:
//   Groups documents by normalized business_name + address. In each group
//   it keeps the document whose ticker matches the app's 5-char format,
//   copies over any field that only the doomed duplicates have, and
//   deletes the rest.
//
// Usage:
//   node dedupe_businesses.js            # dry run - writes nothing
//   node dedupe_businesses.js --commit   # actually merges and deletes
//
// Safety:
//   - Defaults to dry run; --commit is required to change anything.
//   - Only ever deletes a document that has a surviving twin in the same
//     group. A group with no valid-ticker keeper, or with more than one,
//     is reported and skipped rather than guessed at - see the
//     "needs manual review" section of the output.
//   - Refuses to delete any document referenced by users.owned_business
//     or exchange_posts.business_ref, so claiming/posting links can't be
//     broken by this script.
//   - Merges before deleting, so a field the duplicate uniquely carried
//     (a stray address, a demo kindex_score) survives on the keeper.
//   - Writes dedupe_results.json logging every merge and deletion.

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS
  || path.join(__dirname, 'serviceAccountKey.json');
const RESULTS_LOG_PATH = path.join(__dirname, 'dedupe_results.json');
const COLLECTION = 'businesses';
const BATCH_SIZE = 200; // a merge + a delete stays well under the 500 limit

// Must match KindexTickerUtil's format - the whole point of the cleanup is
// to keep the copy the rest of the app can actually look up.
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

function normalize(value) {
  return (value || '')
    .toString()
    .trim()
    .toLowerCase()
    .replace(/\s+/g, ' ');
}

/// At least one address in the source data is a leaked LLM refusal
/// ("I do not have enough information to answer this query..."). It is
/// worse than a blank - it would group and merge as if it were real - so
/// it's treated as absent everywhere.
const JUNK_TEXT = /^(i do not have|i don'?t have|not enough information|as an ai|unable to (determine|find)|unknown|n\/a)/i;

function isJunk(value) {
  return typeof value === 'string' && JUNK_TEXT.test(value.trim());
}

function usableAddress(data) {
  const address = (data.address || '').toString().trim();
  if (!address || isJunk(address)) return '';
  return normalize(address);
}

function isEmpty(value) {
  if (value === null || value === undefined || value === '') return true;
  if (Array.isArray(value) && value.length === 0) return true;
  if (isJunk(value)) return true;
  return false;
}

function chunk(array, size) {
  const out = [];
  for (let i = 0; i < array.length; i += size) {
    out.push(array.slice(i, i + size));
  }
  return out;
}

/// Document IDs that other collections point at. Deleting one of these
/// would dangle the reference, which is how the current orphaned
/// users.owned_business refs came about in the first place.
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

/// Fields the keeper is missing that a doomed duplicate can supply. Skips
/// ticker_symbol - swapping the good ticker back for the colliding one is
/// exactly what this script exists to undo.
function buildMerge(keeper, duplicates) {
  const merged = {};
  for (const duplicate of duplicates) {
    for (const [field, value] of Object.entries(duplicate.data)) {
      if (field === 'ticker_symbol') continue;
      if (isEmpty(value)) continue;
      if (!isEmpty(keeper.data[field])) continue;
      if (field in merged) continue;
      merged[field] = value;
    }
  }
  return merged;
}

async function main() {
  const serviceAccount = loadServiceAccount();
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  const db = admin.firestore();

  console.log(`Project: ${serviceAccount.project_id}`);
  console.log(`Collection: ${COLLECTION}`);
  console.log(`Mode: ${isCommit ? 'COMMIT (will merge and delete)' : 'DRY RUN (no writes)'}`);

  const referenced = await findReferencedIds(db);
  console.log(`${referenced.size} document(s) are referenced by users/exchange_posts and are protected.`);

  const snapshot = await db.collection(COLLECTION).get();
  const docs = [];
  snapshot.forEach((doc) => docs.push({ id: doc.id, data: doc.data() }));
  console.log(`Loaded ${docs.length} documents.`);

  // Pass 1: documents that have a real address group on name + address.
  // Name alone is too loose - "Pressed Roots" is a genuine pair of distinct
  // locations in Houston and Dallas, as are Supercuts Belton/Tyler.
  const groups = new Map();
  const byNameCity = new Map();
  const addressless = [];

  for (const doc of docs) {
    const address = usableAddress(doc.data);
    if (!address) {
      addressless.push(doc);
      continue;
    }
    const key = `${normalize(doc.data.business_name)}|${address}`;
    const bucket = groups.get(key) || [];
    bucket.push(doc);
    groups.set(key, bucket);

    const nameCity = `${normalize(doc.data.business_name)}|${normalize(doc.data.city)}`;
    const keys = byNameCity.get(nameCity) || new Set();
    keys.add(key);
    byNameCity.set(nameCity, keys);
  }

  // Pass 2: a document with no address can still be a duplicate - the first
  // import populated addresses the second one left blank. Fold it into the
  // addressed group for the same name and city, but only when that is
  // unambiguous; a name+city with two real addresses is two storefronts.
  for (const doc of addressless) {
    const nameCity = `${normalize(doc.data.business_name)}|${normalize(doc.data.city)}`;
    const candidates = byNameCity.get(nameCity);
    const key = candidates && candidates.size === 1
      ? [...candidates][0]
      : `${nameCity}|<no-address>`;
    const bucket = groups.get(key) || [];
    bucket.push(doc);
    groups.set(key, bucket);
  }

  const plan = [];
  const manual = [];

  for (const [key, bucket] of groups) {
    if (bucket.length < 2) continue;

    const keepers = bucket.filter((d) => VALID_TICKER.test((d.data.ticker_symbol || '').trim()));

    if (keepers.length !== 1) {
      manual.push({
        key,
        reason: keepers.length === 0
          ? 'no document in this group has a valid 5-char ticker'
          : `${keepers.length} documents have a valid 5-char ticker`,
        docs: bucket.map((d) => ({
          id: d.id,
          ticker_symbol: d.data.ticker_symbol,
          business_name: d.data.business_name,
          city: d.data.city,
        })),
      });
      continue;
    }

    const keeper = keepers[0];
    const duplicates = bucket.filter((d) => d.id !== keeper.id);

    const protectedDupes = duplicates.filter((d) => referenced.has(d.id));
    if (protectedDupes.length > 0) {
      manual.push({
        key,
        reason: 'a duplicate is referenced elsewhere: '
          + protectedDupes.map((d) => referenced.get(d.id).join(', ')).join('; '),
        docs: bucket.map((d) => ({
          id: d.id,
          ticker_symbol: d.data.ticker_symbol,
          business_name: d.data.business_name,
          city: d.data.city,
        })),
      });
      continue;
    }

    plan.push({
      business_name: keeper.data.business_name,
      city: keeper.data.city,
      keep: { id: keeper.id, ticker_symbol: keeper.data.ticker_symbol },
      merge: buildMerge(keeper, duplicates),
      delete: duplicates.map((d) => ({ id: d.id, ticker_symbol: d.data.ticker_symbol })),
    });
  }

  const deleteCount = plan.reduce((sum, p) => sum + p.delete.length, 0);
  const mergeCount = plan.filter((p) => Object.keys(p.merge).length > 0).length;

  console.log(`\nGroups with duplicates: ${plan.length + manual.length}`);
  console.log(`  actionable: ${plan.length} (deleting ${deleteCount} documents, merging fields into ${mergeCount})`);
  console.log(`  needs manual review: ${manual.length}`);
  console.log(`Documents after cleanup: ${docs.length - deleteCount}`);

  const mergedFieldTally = {};
  for (const item of plan) {
    for (const field of Object.keys(item.merge)) {
      mergedFieldTally[field] = (mergedFieldTally[field] || 0) + 1;
    }
  }
  if (Object.keys(mergedFieldTally).length > 0) {
    console.log('\nFields recovered from duplicates before deletion:');
    Object.entries(mergedFieldTally)
      .sort((a, b) => b[1] - a[1])
      .forEach(([field, count]) => console.log(`  ${count.toString().padStart(4)}  ${field}`));
  }

  if (manual.length > 0) {
    console.log('\nNEEDS MANUAL REVIEW (left untouched):');
    manual.forEach((m) => {
      console.log(`  - ${m.docs[0].business_name} (${m.docs[0].city}): ${m.reason}`);
      m.docs.forEach((d) => console.log(`      ${d.id}  ticker=${JSON.stringify(d.ticker_symbol)}`));
    });
  }

  if (!isCommit) {
    console.log('\nSample of the first 3 planned actions:');
    console.log(JSON.stringify(plan.slice(0, 3), null, 2));
    fs.writeFileSync(RESULTS_LOG_PATH, JSON.stringify({ mode: 'dry-run', plan, manual }, null, 2));
    console.log(`\nFull plan written to ${RESULTS_LOG_PATH}`);
    console.log('Dry run only - re-run with --commit to apply.');
    return;
  }

  const applied = [];
  for (const group of chunk(plan, BATCH_SIZE)) {
    const batch = db.batch();
    for (const item of group) {
      if (Object.keys(item.merge).length > 0) {
        batch.update(db.collection(COLLECTION).doc(item.keep.id), item.merge);
      }
      for (const doomed of item.delete) {
        batch.delete(db.collection(COLLECTION).doc(doomed.id));
      }
    }
    await batch.commit();
    applied.push(...group);
    console.log(`Committed batch of ${group.length} (${applied.length}/${plan.length} groups).`);
  }

  fs.writeFileSync(RESULTS_LOG_PATH, JSON.stringify({ mode: 'commit', plan: applied, manual }, null, 2));
  console.log(`\nDone. Deleted ${deleteCount} duplicate document(s).`);
  console.log(`Results written to ${RESULTS_LOG_PATH}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
