// Seeds Black-owned Washington DC businesses into `businesses`, sourced
// from the Greater Washington DC Black Chamber of Commerce (GWBCC) member
// directory (https://business.gwbcc.org/member-directory), the same trust
// tier as the Dallas/New Orleans batches - a real, membership-verified
// chamber, not a crowdsourced/unmoderated list.
//
// Modeled directly on seed_dbcc_dallas.js - same dedup-by-name+city guard,
// same ticker generation, same geohash encoder.
//
// IMPORTANT - what this data is and isn't:
//   GWBCC's directory runs on GrowthZone (same chamber-directory platform
//   family as several other chambers checked during the city-expansion
//   research, just a different URL shape than DBCC's Wix site:
//   /member-directory/FindStartsWith?term=<letter>, 27 letter/digit pages
//   rather than one flat list). Unlike DBCC, each listing card already
//   carries full schema.org address microdata inline, so this batch was
//   scraped directly with a script (not fetched page-by-page via
//   WebFetch) - see the fetch step's notes in session memory if this
//   needs re-running.
//
//   dc_gwbcc_data.json (27 rows) is NOT the raw scrape - it's the result
//   of fetching all 106 member cards across every letter page and
//   hand-curating down to plausible small businesses only:
//     - 76 of 106 raw members list no street address at all (many read as
//       individual consultants/agents/remote-service listings) - dropped,
//       same "no confirmed precise location" bar every batch applies.
//     - Of the 30 with a full address, dropped 3: Clark Construction
//       Group LLC (a large national construction contractor, not a small
//       business), Intralot Inc. (a large international gaming-tech
//       corporation, also genuinely outside the DC metro in Duluth, GA),
//       and Tribute Specialty Services (Philadelphia, PA - not DC).
//     - Two DC-owned Black banks (Industrial Bank, The Harbor Bank of
//       Maryland) were deliberately KEPT despite being sizable
//       institutions - unlike the corporate-sponsor exclusions above,
//       these are themselves Black-owned businesses the chamber directory
//       exists to represent, not large non-Black-owned sponsors diluting
//       it. Multi-location small local groups (Matchbox, Milk & Honey,
//       Wiseguy Pizza - 2 DC locations each) were kept as separate rows,
//       one per physical location, the same way any other business with
//       more than one storefront would be.
//
//   is_black_owned is still an inference from the source (chamber
//   membership), same confidence tier as every prior chamber-directory
//   batch - NOT a government certification, so is_certified_black_owned
//   is not set here either.
//
//   category comes from each listing's free-text description where GWBCC
//   provided one - unlike DBCC's per-member category field, most GWBCC
//   cards left this blank, so category coverage here is closer to
//   NORBCC's "about half uncategorized" than DBCC's near-complete one.
//
// Usage:
//   node seed_gwbcc_dc.js            # dry run - writes nothing
//   node seed_gwbcc_dc.js --commit    # creates the documents

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS
  || path.join(__dirname, 'serviceAccountKey.json');
const DATA_PATH = path.join(__dirname, 'dc_gwbcc_data.json');
const RESULTS_LOG_PATH = path.join(__dirname, 'seed_gwbcc_dc_results.json');
const COLLECTION = 'businesses';
const TICKER_REGISTRY = 'ticker_registry';

const IMPORT_BATCH = 'gwbcc_dc_2026_08';
const IMPORT_SOURCE = 'gwbcc_directory';

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

// --- Ticker generation, mirrors seed_dbcc_dallas.js -------------------------
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
