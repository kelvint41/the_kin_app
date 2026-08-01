// One-off batch import of migration_data.json into the `businesses`
// Firestore collection. Not a Cloud Function - run manually from a
// developer machine with a service account key.
//
// Setup (one-time):
//   1. Firebase Console -> kinvest-build-app -> Project Settings ->
//      Service Accounts -> Generate new private key.
//   2. Save the downloaded file as serviceAccountKey.json in this
//      directory (firebase/scripts/) - it's gitignored, never commit it.
//   3. cd firebase/scripts && npm install
//
// Usage:
//   node import_businesses.js            # dry run - prints what would
//                                         # happen, writes nothing
//   node import_businesses.js --commit   # actually writes to Firestore
//
// Safety:
//   - Defaults to dry run; --commit is required to write anything.
//   - Before writing each record, checks whether a document with the
//     same ticker_symbol already exists and skips it - so re-running
//     this script after a partial failure (or by accident) won't create
//     duplicate businesses with duplicate ticker symbols.
//   - Reserves every imported ticker in `ticker_registry` (doc ID = the
//     ticker) in the same batch as the business write, using create()
//     so an already-reserved ticker fails the batch instead of stealing
//     it. Without this, signup (backend.dart maybeCreateUser) would see
//     every imported business ticker as free and could hand it to a
//     user - see lib/flutter_flow/kindex_ticker_util.dart.
//
// If tickers in migration_data.json are malformed or collide, regenerate
// them first with generate_tickers.js, which mirrors the app's format.
//   - Writes firebase/scripts/import_results.json logging every created
//     document's Firestore ID, ticker, and originating CSV line, for
//     traceability back to National_Directory - San_Antonio_TX_Directory.csv.

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const MIGRATION_JSON_PATH = path.join(__dirname, '..', '..', 'migration_data.json');
const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS
  || path.join(__dirname, 'serviceAccountKey.json');
const RESULTS_LOG_PATH = path.join(__dirname, 'import_results.json');
const COLLECTION = 'businesses';
const TICKER_REGISTRY = 'ticker_registry';
// Each record is two writes (the business doc + its ticker_registry
// reservation), so this is half of what the 500-write batch limit allows.
const BATCH_SIZE = 225;
const TICKER_QUERY_CHUNK = 30; // Firestore 'in' query max is 30 values

const isCommit = process.argv.includes('--commit');

function loadServiceAccount() {
  if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error(
      `Missing service account key at ${SERVICE_ACCOUNT_PATH}.\n` +
      'Generate one from Firebase Console -> Project Settings -> Service Accounts,\n' +
      'save it as serviceAccountKey.json in this directory, or point\n' +
      'GOOGLE_APPLICATION_CREDENTIALS at it.'
    );
    process.exit(1);
  }
  return require(SERVICE_ACCOUNT_PATH);
}

function toGeoPoint(value) {
  if (!value || typeof value.latitude !== 'number' || typeof value.longitude !== 'number') {
    return null;
  }
  return new admin.firestore.GeoPoint(value.latitude, value.longitude);
}

function chunk(array, size) {
  const out = [];
  for (let i = 0; i < array.length; i += size) {
    out.push(array.slice(i, i + size));
  }
  return out;
}

async function findExistingTickers(db, tickers) {
  const existing = new Set();
  for (const group of chunk(tickers, TICKER_QUERY_CHUNK)) {
    const snap = await db.collection(COLLECTION)
      .where('ticker_symbol', 'in', group)
      .get();
    snap.forEach((doc) => existing.add(doc.get('ticker_symbol')));
  }
  return existing;
}

/// Returns the subset of [tickers] already reserved in `ticker_registry`.
/// Registry doc IDs are the tickers themselves, so this is a documentId()
/// lookup rather than a field query.
async function findReservedTickers(db, tickers) {
  const reserved = new Set();
  for (const group of chunk(tickers, TICKER_QUERY_CHUNK)) {
    const refs = group.map((t) => db.collection(TICKER_REGISTRY).doc(t));
    const snaps = await db.getAll(...refs);
    snaps.forEach((doc) => {
      if (doc.exists) reserved.add(doc.id);
    });
  }
  return reserved;
}

async function main() {
  const serviceAccount = loadServiceAccount();
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  const db = admin.firestore();

  console.log(`Project: ${serviceAccount.project_id}`);
  console.log(`Collection: ${COLLECTION}`);
  console.log(`Mode: ${isCommit ? 'COMMIT (will write to Firestore)' : 'DRY RUN (no writes)'}`);

  const raw = fs.readFileSync(MIGRATION_JSON_PATH, 'utf8');
  const records = JSON.parse(raw);
  console.log(`Loaded ${records.length} records from ${MIGRATION_JSON_PATH}`);

  const tickers = records.map((r) => r.ticker_symbol);
  const dupTickers = tickers.filter((t, i) => tickers.indexOf(t) !== i);
  if (dupTickers.length > 0) {
    console.error(`Aborting: migration_data.json has duplicate ticker_symbol values: ${[...new Set(dupTickers)].join(', ')}`);
    console.error('Regenerate them with: node generate_tickers.js <source.csv> --write');
    process.exit(1);
  }

  // Must match KindexTickerUtil's format, or the app's registry reservation
  // and business lookups won't line up with what we write here.
  const malformed = tickers.filter((t) => !/^[A-Z0-9]{5}$/.test(t || ''));
  if (malformed.length > 0) {
    console.error(`Aborting: ${malformed.length} ticker_symbol values aren't 5 chars of A-Z0-9: ${malformed.slice(0, 10).join(', ')}`);
    console.error('Regenerate them with: node generate_tickers.js <source.csv> --write');
    process.exit(1);
  }

  // Runs in both modes. This is a read, and gating it on --commit made the
  // dry run useless once a partial import existed: every already-imported
  // record stayed in `toWrite`, so the ticker_registry check below saw the
  // reservations those same businesses legitimately hold and aborted. The
  // dry run has to filter exactly as the commit does or it isn't a rehearsal.
  console.log('Checking for already-imported tickers (idempotency check)...');
  const skipExisting = await findExistingTickers(db, tickers);
  if (skipExisting.size > 0) {
    console.log(`Skipping ${skipExisting.size} records already present in Firestore.`);
  }

  const toWrite = records.filter((r) => !skipExisting.has(r.ticker_symbol));
  console.log(`${toWrite.length} records to ${isCommit ? 'write' : 'simulate writing'}.`);

  // Runs in dry mode too - it's a read, and catching a reserved ticker before
  // you commit is the whole point of the dry run.
  if (toWrite.length > 0) {
    // A ticker already in the registry belongs to someone else (most likely a
    // user assigned it at signup). Claiming it would point ticker_registry at
    // this business while the original owner keeps the same ticker_symbol, so
    // stop and let the operator regenerate rather than silently colliding.
    console.log('Checking ticker_registry for already-reserved tickers...');
    const reserved = await findReservedTickers(db, toWrite.map((r) => r.ticker_symbol));
    if (reserved.size > 0) {
      console.error(`Aborting: ${reserved.size} ticker(s) are already reserved in ${TICKER_REGISTRY}: ${[...reserved].slice(0, 10).join(', ')}`);
      console.error('Regenerate them with: node generate_tickers.js <source.csv> --write');
      process.exit(1);
    }
  }

  if (!isCommit) {
    console.log('Sample record (first):');
    console.log(JSON.stringify(toWrite[0], null, 2));
    console.log('\nDry run only - re-run with --commit to write to Firestore.');
    return;
  }

  const resultsLog = [];
  for (const group of chunk(toWrite, BATCH_SIZE)) {
    const batch = db.batch();
    const groupResults = [];
    for (const record of group) {
      const { _source_csv_line: sourceLine, business_location, coordinates, ...rest } = record;
      const docRef = db.collection(COLLECTION).doc();
      batch.set(docRef, {
        ...rest,
        business_location: toGeoPoint(business_location),
        coordinates: toGeoPoint(coordinates),
      });
      // create() (not set()) so a ticker reserved between the check above and
      // this commit fails the batch instead of overwriting its owner.
      batch.create(db.collection(TICKER_REGISTRY).doc(record.ticker_symbol), {
        owner_ref: docRef,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      groupResults.push({
        docId: docRef.id,
        ticker_symbol: record.ticker_symbol,
        business_name: record.business_name,
        source_csv_line: sourceLine,
      });
    }
    await batch.commit();
    resultsLog.push(...groupResults);
    console.log(`Committed batch of ${group.length} (${resultsLog.length}/${toWrite.length} total).`);
  }

  fs.writeFileSync(RESULTS_LOG_PATH, JSON.stringify(resultsLog, null, 2));
  console.log(`Done. Wrote ${resultsLog.length} businesses. Results log: ${RESULTS_LOG_PATH}`);
}

main().catch((err) => {
  console.error('Import failed:', err);
  process.exit(1);
});
