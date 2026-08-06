// Seeds Black-owned Atlanta businesses into `businesses`, sourced from
// the Atlanta Black Chambers instance of "I Am Black Business"
// (https://abc.iamblackbusiness.com), a purpose-built Black-owned-business
// directory platform - different provenance from the Dallas/DC batches,
// which came from general chamber membership rosters that happen to
// include real small businesses alongside large non-Black-owned sponsors.
// IABB's whole mission is specifically Black-owned business, so this
// batch needed lighter curation than those did.
//
// Modeled directly on seed_gwbcc_dc.js - same dedup-by-name+city guard,
// same ticker generation, same geohash encoder.
//
// IMPORTANT - what this data is and isn't:
//   atl_iabb_data.json is NOT the raw scrape - it's the result of
//   scraping all ~100 list pages (999 raw listings, address/phone/
//   category/description all embedded directly in each card's "Get
//   Directions" link and visible text - no per-business detail-page
//   fetch needed, unlike DBCC) and curating down:
//     - 999 raw -> 588 had a full street address at all (the rest -
//       mostly listings with no location.location <div> in the card -
//       dropped, same "no confirmed precise location" bar every batch
//       applies)
//     - 588 -> 554 in Georgia (dropped 34 out-of-state IABB members -
//       this platform isn't Atlanta-exclusive, other cities' businesses
//       show up in the same national catalog)
//     - 554 -> 523 after dropping the "Organizations" category (31 rows -
//       spot-checked and confirmed to be nonprofits/foundations/community
//       orgs, e.g. "Financial Parent Academy", "Help Orphans Worldwide" -
//       a business directory, not a nonprofit one)
//     - Spot-checked the remaining 523 for large-corporation names by
//       keyword (bank/hospital/university/national retail chains, etc.) -
//       found only 2 false positives, both individual insurance agent
//       franchises ("William Henry State Farm", "The Douglass Allstate
//       Agency") kept for the same reason Dallas's MIM Insurance
//       Solutions was: the agent owns the storefront even though it
//       operates under a national brand.
//     - geocode_iabb_atlanta.js then dropped rows with an imprecise
//       geocode or landing >40mi from downtown Atlanta.
//
//   is_black_owned is still an inference from the source (platform
//   membership, curated by Atlanta Black Chambers), same confidence tier
//   as every prior directory-sourced batch - NOT a government
//   certification, so is_certified_black_owned is not set here either.
//
//   category comes from IABB's own per-listing category (Business
//   Services, Health and Wellness, Retail, etc.) - real coverage, closer
//   to DBCC's near-complete categorization than GWBCC/NORBCC's mostly-
//   uncategorized ones.
//
// Usage:
//   node seed_iabb_atlanta.js            # dry run - writes nothing
//   node seed_iabb_atlanta.js --commit    # creates the documents

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS
  || path.join(__dirname, 'serviceAccountKey.json');
const DATA_PATH = path.join(__dirname, 'atl_iabb_data.json');
const RESULTS_LOG_PATH = path.join(__dirname, 'seed_iabb_atlanta_results.json');
const COLLECTION = 'businesses';
const TICKER_REGISTRY = 'ticker_registry';

const IMPORT_BATCH = 'iabb_atlanta_2026_08';
const IMPORT_SOURCE = 'iabb_directory';

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

// --- Ticker generation, mirrors seed_gwbcc_dc.js ----------------------------
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
