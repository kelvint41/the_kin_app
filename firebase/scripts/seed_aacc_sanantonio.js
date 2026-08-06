// Seeds Black-owned San Antonio businesses into `businesses`, sourced
// from the African American Chamber of Commerce of San Antonio (AACCSA)
// member directory (members.africanamericanchambersa.org/business-
// directory), a real, membership-verified chamber - same trust tier as
// the Dallas/DC/Atlanta batches. This is a *second* San Antonio source on
// top of the existing ~115 (mostly BOB/AABE-certified) businesses already
// in the directory - the same way Dallas's DBCC batch added to Dallas's
// pre-existing generic-Places coverage rather than being San Antonio's
// first pass.
//
// Modeled directly on seed_iabb_atlanta.js - same dedup-by-name+city
// guard, same ticker generation, same geohash encoder. The name+city
// dedup guard matters more here than in any prior batch, since this is
// the first city where KIN already has substantial existing coverage to
// dedupe against.
//
// IMPORTANT - what this data is and isn't:
//   AACCSA's site runs the WP Business Directory Plugin and actively
//   blocks plain scraper User-Agents with 403/404s - a full browser-like
//   header set (Chrome UA, Accept, Accept-Language, Referer) was needed
//   to get through. sa_aacc_data.json is NOT the raw scrape - it's the
//   result of paginating all 44 pages of the directory's "all listings"
//   view (431 raw entries, address/phone/category all inline per card -
//   no per-business detail-page fetch needed) and curating down:
//     - 431 raw -> 117 had a street address at all (much lower rate than
//       Atlanta's IABB - most AACCSA members list phone/category only)
//     - 117 -> 103 after dropping Nonprofit/Education categories
//     - 103 -> 95 after dropping a handful of non-address entries (a
//       website URL and a chamber acronym mistakenly in the address
//       field, a bare "Unit 131" with no street, government/school
//       district members, one duplicate) - the site's address field
//       frequently omits city/state entirely (e.g. "211 whitecliff dr,
//       78227"), so "San Antonio, TX" was appended wherever missing,
//       since every zip seen across all 431 raw listings was a native
//       78xxx San Antonio-area code.
//     - geocode_aacc_sanantonio.js then dropped 12 more: imprecise
//       geocodes, plus 2 genuinely out-of-metro (one 253mi away).
//
//   is_black_owned is still an inference from the source (chamber
//   membership), same confidence tier as every prior directory-sourced
//   batch - NOT a government certification (unlike the existing BOB/AABE
//   San Antonio rows, which mostly are), so is_certified_black_owned is
//   not set here either.
//
// Usage:
//   node seed_aacc_sanantonio.js            # dry run - writes nothing
//   node seed_aacc_sanantonio.js --commit    # creates the documents

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS
  || path.join(__dirname, 'serviceAccountKey.json');
const DATA_PATH = path.join(__dirname, 'sa_aacc_data.json');
const RESULTS_LOG_PATH = path.join(__dirname, 'seed_aacc_sanantonio_results.json');
const COLLECTION = 'businesses';
const TICKER_REGISTRY = 'ticker_registry';

const IMPORT_BATCH = 'aacc_sanantonio_2026_08';
const IMPORT_SOURCE = 'aacc_directory';

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

// --- Ticker generation, mirrors seed_iabb_atlanta.js ------------------------
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
