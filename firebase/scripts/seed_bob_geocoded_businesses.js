// Creates new `businesses` documents for the BOB-certified businesses that
// apply_bob_certification.js couldn't match to an existing directory entry,
// using addresses/coordinates found afterward by geocode_bob_worklist.js
// (see bob_geocode_high_confidence.csv - exact name match, operating,
// confirmed Texas address).
//
// Reviewed by hand before this ran: of the 58 high-confidence rows, 2
// (The Burrell Group -> Dallas, ASD Consultants -> Austin) were the same
// name as an unrelated business hundreds of miles away and are excluded
// below. The rest carry the same certification metadata
// apply_bob_certification.js writes for a directory match, since they come
// from the identical source list.
//
// Idempotency: skips any row that already matches an existing business by
// phone or name+city, same rule as apply_bob_certification.js, so a second
// run (or overlap with a future BOB re-import) doesn't create a duplicate.
//
// Usage:
//   node seed_bob_geocoded_businesses.js            # dry run - writes nothing
//   node seed_bob_geocoded_businesses.js --commit   # creates the documents
//
// Safety:
//   - Defaults to dry run; --commit is required to write.
//   - Ticker symbols are checked against both `businesses` and
//     `ticker_registry` before committing, same guard as import_businesses.js,
//     so a batch import can't hand out a ticker someone already holds.

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS
  || path.join(__dirname, 'serviceAccountKey.json');
const HIGH_CONFIDENCE_CSV = path.join(__dirname, 'bob_geocode_high_confidence.csv');
const WORKLIST_CSV = path.join(__dirname, 'bob_reverification_worklist.csv');
const RESULTS_LOG_PATH = path.join(__dirname, 'seed_bob_geocoded_results.json');
const COLLECTION = 'businesses';
const TICKER_REGISTRY = 'ticker_registry';

const CERTIFICATION_SOURCE = 'BOB Bexar County / AABE (City of San Antonio)';
const CERTIFICATION_AS_OF = '2020-10-05';

// Confirmed same-name-different-business by hand (see header comment).
const EXCLUDED_NAMES = new Set(['The Burrell Group', 'ASD Consultants, Inc.']);

const isCommit = process.argv.includes('--commit');

function loadServiceAccount() {
  if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error(`Missing service account key at ${SERVICE_ACCOUNT_PATH}.`);
    process.exit(1);
  }
  return require(SERVICE_ACCOUNT_PATH);
}

function parseCsv(text) {
  const rows = [];
  let row = [];
  let field = '';
  let quoted = false;
  for (let i = 0; i < text.length; i += 1) {
    const ch = text[i];
    if (quoted) {
      if (ch === '"') {
        if (text[i + 1] === '"') { field += '"'; i += 1; } else { quoted = false; }
      } else {
        field += ch;
      }
      continue;
    }
    if (ch === '"') { quoted = true; continue; }
    if (ch === ',') { row.push(field); field = ''; continue; }
    if (ch === '\r') continue;
    if (ch === '\n') { row.push(field); rows.push(row); row = []; field = ''; continue; }
    field += ch;
  }
  if (field !== '' || row.length > 0) { row.push(field); rows.push(row); }
  const header = rows.shift().map((h) => h.trim());
  return rows
    .filter((r) => r.some((c) => c.trim() !== ''))
    .map((r) => Object.fromEntries(header.map((h, i) => [h, (r[i] || '').trim()])));
}

function normalizeName(value) {
  return (value || '')
    .toString()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .replace(/\b(llc|inc|l l c|corp|co|company|the)\b/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function normalizeCity(value) {
  return (value || '').toString().trim().toLowerCase().replace(/\s+/g, ' ');
}

function normalizePhone(value) {
  const digits = (value || '').toString().replace(/\D/g, '');
  return digits.length >= 10 ? digits.slice(-10) : '';
}

// Splits "8452 Fredericksburg Rd, San Antonio, TX 78229, USA" into parts.
function splitAddress(formatted) {
  const m = formatted.match(/^(.*?),\s*([^,]+),\s*TX\s*(\d{5})/);
  if (!m) return { street: formatted, city: '', zip: '' };
  return { street: m[1].trim(), city: m[2].trim(), zip: m[3].trim() };
}

// --- Ticker generation, mirrors generate_tickers.js / KindexTickerUtil -----
const TICKER_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
const TICKER_LENGTH = 5;
const FILLER_WORDS = ['LLC', 'INC', 'CO', 'THE'];

function semanticCandidate(name) {
  const cleaned = String(name)
    .toUpperCase()
    .split(/[^A-Z0-9]+/)
    .filter((w) => w.length > 0 && !FILLER_WORDS.includes(w))
    .join('');
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

// --- Geohash, mirrors backfill_business_geohashes.js / geohash_util.dart ---
const GEOHASH_PRECISION = 9;
const BASE32 = '0123456789bcdefghjkmnpqrstuvwxyz';

function encodeGeohash(lat, lng, precision = GEOHASH_PRECISION) {
  let latMin = -90, latMax = 90, lngMin = -180, lngMax = 180;
  let out = '';
  let bit = 0;
  let ch = 0;
  let evenBit = true;
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

  console.log(`Project: ${serviceAccount.project_id}`);
  console.log(`Mode: ${isCommit ? 'COMMIT (will write to Firestore)' : 'DRY RUN (no writes)'}`);

  const candidates = parseCsv(fs.readFileSync(HIGH_CONFIDENCE_CSV, 'utf8'))
    .filter((r) => !EXCLUDED_NAMES.has(r.business_name));
  const worklist = parseCsv(fs.readFileSync(WORKLIST_CSV, 'utf8'));
  const phoneByName = new Map(worklist.map((r) => [r['Business Name'], r.Phone]));

  console.log(`${candidates.length} candidate businesses (58 high-confidence minus ${EXCLUDED_NAMES.size} excluded).`);

  const snapshot = await db.collection(COLLECTION).get();
  const byPhone = new Map();
  const byNameCity = new Map();
  const takenTickers = new Set();
  snapshot.forEach((doc) => {
    const data = doc.data();
    if (data.ticker_symbol) takenTickers.add(data.ticker_symbol);
    const phone = normalizePhone(data.phone_number);
    if (phone) {
      const bucket = byPhone.get(phone) || [];
      bucket.push(doc.id);
      byPhone.set(phone, bucket);
    }
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

  for (const row of candidates) {
    const phone = row_phone(row);
    const { street, city, zip } = splitAddress(row.matched_address);
    const normPhone = normalizePhone(phone);
    const nameCityKey = `${normalizeName(row.business_name)}|${normalizeCity(city)}`;

    const existingByPhone = normPhone ? byPhone.get(normPhone) : null;
    const existingByNameCity = byNameCity.get(nameCityKey);
    if (existingByPhone || existingByNameCity) {
      alreadyExists.push({
        business_name: row.business_name,
        matched_existing_ids: existingByPhone || existingByNameCity,
      });
      continue;
    }

    const ticker = pickTicker(row.business_name, takenTickers);
    takenTickers.add(ticker);

    const lat = parseFloat(row.lat);
    const lng = parseFloat(row.lng);

    toCreate.push({
      business_name: row.business_name,
      address: street,
      city,
      state: 'TX',
      zip_code_postcode: zip,
      phone_number: phone,
      website: row.website === 'n/a' ? '' : row.website,
      description: row.description,
      latitude: lat,
      longitude: lng,
      ticker_symbol: ticker,
      is_black_owned: true,
      is_certified_black_owned: true,
      certification_source: CERTIFICATION_SOURCE,
      certification_as_of: CERTIFICATION_AS_OF,
      is_verified: false,
      _lat: lat,
      _lng: lng,
    });
  }

  function row_phone(row) {
    return phoneByName.get(row.business_name) || '';
  }

  console.log(`\nAlready in directory (skipped, not duplicated): ${alreadyExists.length}`);
  alreadyExists.forEach((a) => console.log(`  ${a.business_name} -> ${a.matched_existing_ids.join(', ')}`));

  console.log(`\nTo create: ${toCreate.length}`);

  if (!isCommit) {
    console.log('\nSample record (first):');
    const { _lat, _lng, ...sample } = toCreate[0];
    console.log(JSON.stringify(sample, null, 2));
    console.log('\nDry run only - re-run with --commit to write to Firestore.');
    fs.writeFileSync(RESULTS_LOG_PATH, JSON.stringify({
      mode: 'dry-run', to_create: toCreate.map((r) => r.business_name), already_exists: alreadyExists,
    }, null, 2));
    return;
  }

  const resultsLog = [];
  const batch = db.batch();
  for (const record of toCreate) {
    const { _lat, _lng, ticker_symbol, ...rest } = record;
    const docRef = db.collection(COLLECTION).doc();
    const geoPoint = new admin.firestore.GeoPoint(_lat, _lng);
    batch.set(docRef, {
      ...rest,
      ticker_symbol,
      business_location: geoPoint,
      coordinates: geoPoint,
      geohash: encodeGeohash(_lat, _lng),
    });
    batch.create(db.collection(TICKER_REGISTRY).doc(ticker_symbol), {
      owner_ref: docRef,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });
    resultsLog.push({ docId: docRef.id, ticker_symbol, business_name: record.business_name });
  }
  await batch.commit();
  fs.writeFileSync(RESULTS_LOG_PATH, JSON.stringify({ mode: 'commit', created: resultsLog, already_exists: alreadyExists }, null, 2));
  console.log(`\nCreated ${resultsLog.length} businesses. Results: ${RESULTS_LOG_PATH}`);
}

main().catch((err) => { console.error(err); process.exit(1); });
