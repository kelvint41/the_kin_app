// Repairs dangling document references and backfills the ticker registry.
// Run manually with a service account key - same setup as import_businesses.js.
//
// Run this AFTER dedupe_businesses.js --commit and after the import is
// complete. Reserving tickers for documents that are about to be deleted
// just means undoing them again.
//
// Two problems this fixes:
//
// 1. Dangling owned_business references.
//    The businesses collection was wiped and re-imported at some point, which
//    minted new document IDs. users.owned_business still points at the old
//    ones, so those accounts reference businesses that no longer exist.
//    This is not cosmetic: _ensureDevBypassBusiness() in lib/main.dart bails
//    out early when `userDoc.ownedBusiness != null`, so an account holding a
//    dangling ref never gets a working test business AND never gets a real
//    one - it is wedged. Clearing the dead ref unwedges it.
//
// 2. An empty ticker_registry.
//    Signup assigns tickers via KindexTickerUtil, which treats any ticker
//    absent from `ticker_registry` as free. The registry currently holds a
//    single document while the businesses collection holds hundreds, so a new
//    user can be handed a ticker that an imported business already displays.
//    Every business ticker needs a reservation pointing back at it.
//
// Usage:
//   node repair_references.js            # dry run - writes nothing
//   node repair_references.js --commit   # applies the repairs
//
// Safety:
//   - Defaults to dry run; --commit is required to write.
//   - Only ever clears a reference whose target is confirmed missing. A
//     reference that resolves is left alone.
//   - Never deletes an exchange_post. Posts pointing at a missing business
//     are reported for a human to decide on, since the post text is user
//     content that no script should discard.
//   - Refuses to reserve a ticker that two businesses share, or that is
//     already reserved by a different document, and reports both cases.

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS
  || path.join(__dirname, 'serviceAccountKey.json');
const RESULTS_LOG_PATH = path.join(__dirname, 'repair_results.json');
const BUSINESSES = 'businesses';
const USERS = 'users';
const EXCHANGE_POSTS = 'exchange_posts';
const TICKER_REGISTRY = 'ticker_registry';
const BATCH_SIZE = 400;

// Must match KindexTickerUtil's format, or a reservation written here will not
// line up with what the app looks up at signup.
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

async function main() {
  const serviceAccount = loadServiceAccount();
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  const db = admin.firestore();

  console.log(`Project: ${serviceAccount.project_id}`);
  console.log(`Mode: ${isCommit ? 'COMMIT (will write to Firestore)' : 'DRY RUN (no writes)'}`);

  const businessSnap = await db.collection(BUSINESSES).get();
  const liveIds = new Set();
  const businesses = [];
  businessSnap.forEach((doc) => {
    liveIds.add(doc.id);
    businesses.push({ id: doc.id, data: doc.data() });
  });
  console.log(`\n${businesses.length} business documents.`);

  // --- 1. Dangling user references -----------------------------------------
  const userSnap = await db.collection(USERS).get();
  const danglingUsers = [];
  userSnap.forEach((doc) => {
    const ref = doc.get('owned_business');
    if (ref && !liveIds.has(ref.id)) {
      danglingUsers.push({
        userId: doc.id,
        email: doc.get('email') || '(no email)',
        deadRef: ref.path,
      });
    }
  });

  console.log(`\nUsers with a dangling owned_business: ${danglingUsers.length}`);
  danglingUsers.forEach((u) => console.log(`  ${u.email} (${u.userId}) -> ${u.deadRef}`));
  if (danglingUsers.length > 0) {
    console.log('  These accounts are wedged: lib/main.dart _ensureDevBypassBusiness()');
    console.log('  skips them because ownedBusiness is non-null. Clearing lets it run.');
  }

  // --- 2. Dangling exchange_posts (reported only) ---------------------------
  const postSnap = await db.collection(EXCHANGE_POSTS).get();
  const orphanPosts = [];
  postSnap.forEach((doc) => {
    const ref = doc.get('business_ref');
    if (ref && !liveIds.has(ref.id)) {
      orphanPosts.push({ postId: doc.id, deadRef: ref.path });
    }
  });
  console.log(`\nexchange_posts pointing at a missing business: ${orphanPosts.length} (reported, never deleted)`);
  orphanPosts.forEach((p) => console.log(`  ${p.postId} -> ${p.deadRef}`));

  // --- 3. Ticker registry backfill -----------------------------------------
  const byTicker = new Map();
  const malformed = [];
  for (const business of businesses) {
    const ticker = (business.data.ticker_symbol || '').trim();
    if (!VALID_TICKER.test(ticker)) {
      malformed.push({ id: business.id, ticker, name: business.data.business_name });
      continue;
    }
    const bucket = byTicker.get(ticker) || [];
    bucket.push(business);
    byTicker.set(ticker, bucket);
  }

  const collided = [...byTicker.entries()].filter(([, v]) => v.length > 1);
  const candidates = [...byTicker.entries()].filter(([, v]) => v.length === 1);

  // A ticker already in the registry belongs to whoever reserved it - most
  // likely a user assigned it at signup. Claiming it here would point the
  // registry at this business while the original holder keeps displaying the
  // same symbol, so those are skipped rather than overwritten.
  const registrySnap = await db.collection(TICKER_REGISTRY).get();
  const reserved = new Map();
  registrySnap.forEach((doc) => reserved.set(doc.id, doc.get('owner_ref')));
  console.log(`\nticker_registry currently holds ${reserved.size} reservation(s).`);

  const toReserve = [];
  const alreadyHeld = [];
  for (const [ticker, [business]] of candidates) {
    const holder = reserved.get(ticker);
    if (holder === undefined) {
      toReserve.push({ ticker, business });
    } else if (!holder || holder.id !== business.id) {
      alreadyHeld.push({ ticker, business, holder: holder ? holder.path : '(no owner_ref)' });
    }
  }

  console.log(`  to reserve: ${toReserve.length}`);
  console.log(`  already correct: ${candidates.length - toReserve.length - alreadyHeld.length}`);

  if (malformed.length > 0) {
    console.log(`\nSKIPPED - ticker is not 5 chars of A-Z0-9 (${malformed.length}):`);
    malformed.slice(0, 20).forEach((m) => console.log(`  ${JSON.stringify(m.ticker)}  ${m.name}`));
    if (malformed.length > 20) console.log(`  ...and ${malformed.length - 20} more`);
    console.log('  Fix with: node generate_tickers.js <source.csv> --write, then re-import,');
    console.log('  or reassign by hand. They cannot be reserved as-is.');
  }

  if (collided.length > 0) {
    console.log(`\nSKIPPED - ticker shared by more than one business (${collided.length}):`);
    collided.forEach(([ticker, group]) => {
      console.log(`  ${ticker}:`);
      group.forEach((b) => console.log(`      ${b.data.business_name} (${b.data.city}) [${b.id}]`));
    });
    console.log('  One of each set must be reassigned before either can be reserved.');
  }

  if (alreadyHeld.length > 0) {
    console.log(`\nSKIPPED - ticker already reserved by someone else (${alreadyHeld.length}):`);
    alreadyHeld.forEach((a) => console.log(`  ${a.ticker} held by ${a.holder}, wanted by ${a.business.data.business_name}`));
  }

  const results = {
    mode: isCommit ? 'commit' : 'dry-run',
    cleared_user_refs: danglingUsers,
    orphan_posts: orphanPosts,
    reserved_tickers: toReserve.map((t) => ({ ticker: t.ticker, businessId: t.business.id })),
    skipped_malformed: malformed,
    skipped_collided: collided.map(([ticker, group]) => ({ ticker, ids: group.map((b) => b.id) })),
    skipped_already_held: alreadyHeld.map((a) => ({ ticker: a.ticker, holder: a.holder })),
  };

  if (!isCommit) {
    fs.writeFileSync(RESULTS_LOG_PATH, JSON.stringify(results, null, 2));
    console.log(`\nPlan written to ${RESULTS_LOG_PATH}`);
    console.log('Dry run only - re-run with --commit to apply.');
    return;
  }

  if (danglingUsers.length > 0) {
    const batch = db.batch();
    danglingUsers.forEach((u) => {
      batch.update(db.collection(USERS).doc(u.userId), {
        owned_business: admin.firestore.FieldValue.delete(),
      });
    });
    await batch.commit();
    console.log(`\nCleared ${danglingUsers.length} dangling owned_business reference(s).`);
  }

  let written = 0;
  for (const group of chunk(toReserve, BATCH_SIZE)) {
    const batch = db.batch();
    for (const { ticker, business } of group) {
      // create() (not set()) so a ticker reserved between the read above and
      // this commit fails the batch instead of overwriting its owner.
      batch.create(db.collection(TICKER_REGISTRY).doc(ticker), {
        owner_ref: db.collection(BUSINESSES).doc(business.id),
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    written += group.length;
    console.log(`Reserved ${written}/${toReserve.length} ticker(s).`);
  }

  fs.writeFileSync(RESULTS_LOG_PATH, JSON.stringify(results, null, 2));
  console.log(`\nDone. Results written to ${RESULTS_LOG_PATH}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
