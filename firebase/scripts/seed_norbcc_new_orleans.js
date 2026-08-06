// Seeds Black-owned New Orleans businesses into `businesses`, sourced from
// the New Orleans Regional Black Chamber of Commerce (NORBCC) member
// directory (https://members.nolablkchamber.org/list/), the same trust
// tier as the BOB Bexar/AABE list San Antonio's directory was built from -
// a real, membership-verified chamber, not a crowdsourced/unmoderated list.
//
// Modeled directly on seed_directory_test_batch.js - same dedup-by-
// name+city guard, same ticker generation, same geohash encoder.
//
// IMPORTANT - what this data is and isn't:
//   NORBCC's public directory is a general MEMBERSHIP list, not a
//   certified-Black-owned-businesses list. Chamber membership includes
//   large corporate sponsors (banks, insurers, telecoms, energy
//   companies), government agencies, universities, and national
//   nonprofits alongside genuine small Black-owned businesses - none of
//   which belong in a Black-owned business directory regardless of how
//   they got onto the chamber's member list.
//
//   norbcc_new_orleans_data.json (569 rows) is NOT the raw scrape - it's
//   the result of hand-curating all 795 raw entries down to plausible
//   small businesses only:
//     - Dropped 14 entries in Elected Officials/Government/Individual/
//       Chambers of Commerce/Business Member Organization categories
//     - Dropped 162 named entries recognized as large corporations,
//       government bodies, universities/hospital systems, or national
//       nonprofits/civic associations (AT&T, Chase Bank, Ochsner Health,
//       Tulane University, United Way, etc.) - see the session notes for
//       the full exclude list if this batch is ever re-run from scratch
//     - Dropped 28 with no street address at all, 5 exact-name duplicates,
//       10 with an out-of-Louisiana ZIP code (chamber members based
//       elsewhere), and 6 whose address didn't resolve to a precise point
//       via Geocoding (PO boxes / bad source data) - same "no confirmed
//       precise location" bar seed_directory_test_batch.js applies
//     - Dropped 1 more (2 B Chic Boutiqe) after a post-geocode distance
//       sanity check: its street ("4000 Washington") geocoded 127 miles
//       away to the town of Washington, LA - Google read the street name
//       as a place name because the source address's city field was
//       corrupted ("4000 Washington, Non-Hispanic, LA, 70043" in NORBCC's
//       own data). Every other result landed within a plausible distance
//       of New Orleans; this was the one exception.
//
//   is_black_owned is still an inference from the source (chamber
//   membership), same confidence tier as the buyblack.org-sourced rows in
//   seed_directory_test_batch.js - NOT a government certification, so
//   is_certified_black_owned is not set here either.
//
//   category is best-effort keyword inference from the business name only
//   (no category data was available from the source) - about half come
//   through uncategorized, which the app already treats as "eligible,
//   just unlabeled" everywhere category is read (QuestEligibility,
//   Category Breakdown chart).
//
// Usage:
//   node seed_norbcc_new_orleans.js            # dry run - writes nothing
//   node seed_norbcc_new_orleans.js --commit    # creates the documents

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS
  || path.join(__dirname, 'serviceAccountKey.json');
const DATA_PATH = path.join(__dirname, 'norbcc_new_orleans_data.json');
const RESULTS_LOG_PATH = path.join(__dirname, 'seed_norbcc_new_orleans_results.json');
const COLLECTION = 'businesses';
const TICKER_REGISTRY = 'ticker_registry';

const IMPORT_BATCH = 'norbcc_no_2026_08';
const IMPORT_SOURCE = 'norbcc_directory';

const isCommit = process.argv.includes('--commit');

function loadServiceAccount() {
  if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error(`Missing service account key at ${SERVICE_ACCOUNT_PATH}.`);
    process.exit(1);
  }
  return require(SERVICE_ACCOUNT_PATH);
}

function normalizeName(value) {
  return (value || '').toString().toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .replace(/\b(llc|inc|l l c|corp|co|company|the)\b/g, '')
    .replace(/\s+/g, ' ').trim();
}
function normalizeCity(value) {
  return (value || '').toString().trim().toLowerCase().replace(/\s+/g, ' ');
}

// --- Ticker generation, mirrors seed_directory_test_batch.js --------------
const TICKER_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
const TICKER_LENGTH = 5;
const FILLER_WORDS = ['LLC', 'INC', 'CO', 'THE'];

function semanticCandidate(name) {
  const cleaned = String(name).toUpperCase().split(/[^A-Z0-9]+/)
    .filter((w) => w.length > 0 && !FILLER_WORDS.includes(w)).join('');
  return cleaned.length >= TICKER_LENGTH ? cleaned.slice(0, TICKER_LENGTH) : null;
}
function derivedCandidate(seed, attempt) {
  let hash = 0x811c9dc5;
  const input = `${seed}#${attempt}`;
  for (let i = 0; i < input.length; i++) {
    hash ^= input.charCodeAt(i);
    hash = Math.imul(hash, 0x01000193) >>> 0;
  }
  let out = '';
  for (let i = 0; i < TICKER_LENGTH; i++) {
    out += TICKER_CHARS[hash % TICKER_CHARS.length];
    hash = Math.floor(hash / TICKER_CHARS.length) + Math.imul(hash, 31) % 997;
    hash = hash >>> 0;
  }
  return out;
}
function pickTicker(name, taken) {
  const semantic = semanticCandidate(name);
  if (semantic && !taken.has(semantic)) return semantic;
  for (let attempt = 0; attempt < 50; attempt += 1) {
    const candidate = derivedCandidate(name, attempt);
    if (!taken.has(candidate)) return candidate;
  }
  throw new Error(`Could not find a free ticker for "${name}"`);
}

// --- Geohash, mirrors geohash.js -------------------------------------------
const GEOHASH_PRECISION = 9;
const BASE32 = '0123456789bcdefghjkmnpqrstuvwxyz';
function encodeGeohash(lat, lng, precision = GEOHASH_PRECISION) {
  let latMin = -90, latMax = 90, lngMin = -180, lngMax = 180;
  let out = '', bit = 0, ch = 0, evenBit = true;
  while (out.length < precision) {
    if (evenBit) {
      const mid = (lngMin + lngMax) / 2;
      if (lng >= mid) { ch |= 1 << (4 - bit); lngMin = mid; } else { lngMax = mid; }
    } else {
      const mid = (latMin + latMax) / 2;
      if (lat >= mid) { ch |= 1 << (4 - bit); latMin = mid; } else { latMax = mid; }
    }
    evenBit = !evenBit;
    if (bit < 4) { bit += 1; } else { out += BASE32[ch]; bit = 0; ch = 0; }
  }
  return out;
}

async function main() {
  const serviceAccount = loadServiceAccount();
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  const db = admin.firestore();

  const ROWS = JSON.parse(fs.readFileSync(DATA_PATH, 'utf8'));

  console.log(`Project: ${serviceAccount.project_id}`);
  console.log(`Mode: ${isCommit ? 'COMMIT (will write to Firestore)' : 'DRY RUN (no writes)'}`);
  console.log(`${ROWS.length} candidate businesses.`);

  const snapshot = await db.collection(COLLECTION).get();
  const byNameCity = new Map();
  const takenTickers = new Set();
  snapshot.forEach((doc) => {
    const data = doc.data();
    if (data.ticker_symbol) takenTickers.add(data.ticker_symbol);
    const name = normalizeName(data.business_name);
    if (name) {
      const key = `${name}|${normalizeCity(data.city)}`;
      const bucket = byNameCity.get(key) || [];
      bucket.push(doc.id);
      byNameCity.set(key, bucket);
    }
  });
  console.log(`Indexed ${snapshot.size} existing businesses (${takenTickers.size} tickers in use).`);

  const toCreate = [];
  const alreadyExists = [];

  for (const row of ROWS) {
    const nameCityKey = `${normalizeName(row.name)}|${normalizeCity(row.city)}`;
    const existing = byNameCity.get(nameCityKey);
    if (existing) {
      alreadyExists.push({ business_name: row.name, matched_existing_ids: existing });
      continue;
    }

    const ticker = pickTicker(row.name, takenTickers);
    takenTickers.add(ticker);

    toCreate.push({
      business_name: row.name, category: row.category, address: row.street,
      city: row.city, state: row.state, zip_code_postcode: row.zip,
      phone_number: row.phone, ticker_symbol: ticker,
      is_black_owned: true, is_verified: false, is_claimed: false,
      subscription_tier: 'Community', is_premium: false,
      directory_import_batch: IMPORT_BATCH, directory_import_source: IMPORT_SOURCE,
      _lat: row.lat, _lng: row.lng,
    });
  }

  console.log(`\nAlready in directory (skipped, not duplicated): ${alreadyExists.length}`);
  console.log(`To create: ${toCreate.length}`);

  if (!isCommit) {
    console.log('\nSample records (first 3):');
    toCreate.slice(0, 3).forEach((r) => {
      const { _lat, _lng, ...sample } = r;
      console.log(JSON.stringify(sample, null, 2));
    });
    console.log('\nDry run only - re-run with --commit to write to Firestore.');
    fs.writeFileSync(RESULTS_LOG_PATH, JSON.stringify({
      mode: 'dry-run', to_create: toCreate.map((r) => r.business_name), already_exists: alreadyExists,
    }, null, 2));
    return;
  }

  const resultsLog = [];
  // Firestore batches cap at 500 writes - this batch alone (businesses +
  // ticker_registry docs) can exceed that, so chunk into multiple batches
  // rather than one, unlike seed_directory_test_batch.js's smaller batch.
  const CHUNK_SIZE = 200;
  for (let start = 0; start < toCreate.length; start += CHUNK_SIZE) {
    const chunk = toCreate.slice(start, start + CHUNK_SIZE);
    const batch = db.batch();
    for (const record of chunk) {
      const { _lat, _lng, ticker_symbol, ...rest } = record;
      const docRef = db.collection(COLLECTION).doc();
      const geoPoint = new admin.firestore.GeoPoint(_lat, _lng);
      batch.set(docRef, {
        ...rest,
        ticker_symbol,
        business_location: geoPoint,
        coordinates: geoPoint,
        geohash: encodeGeohash(_lat, _lng),
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      batch.create(db.collection(TICKER_REGISTRY).doc(ticker_symbol), {
        owner_ref: docRef,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      resultsLog.push({ docId: docRef.id, ticker_symbol, business_name: record.business_name });
    }
    await batch.commit();
    console.log(`Committed ${Math.min(start + CHUNK_SIZE, toCreate.length)}/${toCreate.length}`);
  }
  fs.writeFileSync(RESULTS_LOG_PATH, JSON.stringify({ mode: 'commit', created: resultsLog, already_exists: alreadyExists }, null, 2));
  console.log(`\nCreated ${resultsLog.length} businesses. Results: ${RESULTS_LOG_PATH}`);
}

main().catch((err) => { console.error(err); process.exit(1); });
