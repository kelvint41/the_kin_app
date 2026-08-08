// Seeds the Georgia/Illinois test batch researched this session (12
// hand-curated + 38 buyblack.org-directory-sourced, Places-verified) into
// `businesses`, tagged so they're easy to find/remove later and so the
// KinQuestMapDemoWidget can query just this batch instead of the whole
// collection.
//
// Modeled directly on seed_bob_geocoded_businesses.js - same dedup-by-
// phone-or-name+city guard, same ticker generation, same geohash encoder
// (a business without one is invisible on the map - see geohash.js).
//
// Unlike the BOB batch, none of this is government-certified - it's
// sourced from public directories (buyblack.org) plus hand research, so
// is_certified_black_owned is NOT set here. is_verified is false for all
// of them (unclaimed, nobody at KIN has confirmed them in person).
//
// 3 researched businesses are deliberately excluded: Myavana, TKST Law
// (no confirmed street address, only city-level), and "1 Of 1 Cuts"
// (Google only has a Plus Code for it, no street address) - seeding a
// city-center or Plus-Code-only coordinate as if it were a precise
// location would misplace the pin.
//
// Usage:
//   node seed_directory_test_batch.js            # dry run - writes nothing
//   node seed_directory_test_batch.js --commit    # creates the documents

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS
  || path.join(__dirname, 'serviceAccountKey.json');
const RESULTS_LOG_PATH = path.join(__dirname, 'seed_directory_test_batch_results.json');
const COLLECTION = 'businesses';
const TICKER_REGISTRY = 'ticker_registry';

const IMPORT_BATCH = 'ga_il_test_2026_08';

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
function normalizePhone(value) {
  const digits = (value || '').toString().replace(/\D/g, '');
  return digits.length >= 10 ? digits.slice(-10) : '';
}

// --- Ticker generation, mirrors seed_bob_geocoded_businesses.js -----------
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

// name, category, street, city, state, zip, lat, lng, website (optional),
// source ('curated_research' | 'buyblack_org_directory')
const ROWS = [
  // --- Batch 1: hand-curated, individually web-researched (Atlanta area) ---
  ['Busy Bee Cafe', 'Restaurant', '810 Martin Luther King Jr Dr SW', 'Atlanta', 'GA', '30314', 33.7544134, -84.4140043, 'https://thebusybeecafe.com', 'curated_research'],
  ["Virgil's Gullah Kitchen & Bar", 'Restaurant', '822 Marietta St NW', 'Atlanta', 'GA', '30318', 33.7747021, -84.4066173, 'https://virgilsgullahkitchen.com', 'curated_research'],
  ['The Gathering Spot', 'Membership Club & Event Venue', '384 Northyards Blvd NW Ste 190', 'Atlanta', 'GA', '30313', 33.7672724, -84.4001851, 'https://www.thegatheringspot.club', 'curated_research'],
  ['SP HairCare', 'Beauty Salon', '1820 Peachtree St NW Ste 105', 'Atlanta', 'GA', '30309', 33.8051862, -84.3942645, 'https://sphaircare.com', 'curated_research'],
  ["Mia' Bella Beauty Supply", 'Beauty Supply Store', '2625 Piedmont Rd NE Ste 52-252', 'Atlanta', 'GA', '30324', 33.8275967, -84.3654021, '', 'curated_research'],
  ['For Keeps Books', 'Bookstore', '171 Auburn Ave NE Unit H1', 'Atlanta', 'GA', '30303', 33.7552465, -84.3814071, '', 'curated_research'],
  ['Nubian Books', 'Bookstore', '1540 Southlake Pkwy Ste 7A', 'Morrow', 'GA', '30260', 33.5736206, -84.3363697, 'https://www.nubianbookstore.com', 'curated_research'],
  ['Medu Bookstore', 'Bookstore', '2841 Greenbriar Pkwy SW', 'Atlanta', 'GA', '30331', 33.6890044, -84.4951070, 'https://www.medubookstore.com', 'curated_research'],
  ['The Black Firm', 'Law Firm', '950 Herrington Rd Ste C-114', 'Lawrenceville', 'GA', '30044', 33.9406448, -84.0824721, 'https://www.theblackfirm.com', 'curated_research'],
  ['Chroma Creators', 'Marketing Agency', '2275 Marietta Blvd NW Ste 270-431', 'Atlanta', 'GA', '30318', 33.8192890, -84.4496743, 'https://chromacreators.agency', 'curated_research'],

  // --- Batch 2: buyblack.org directory, resolved via Places API ---
  ['Automotive Technical Solutions & Kustoms', 'Auto Repair Shop', '1060 Donald Lee Hollowell Pkwy NW Ste-B', 'Atlanta', 'GA', '30318', 33.7712263, -84.4224045, '', 'buyblack_org_directory'],
  ['& Cheese Midtown', 'Restaurant', '620 Peachtree St NE Ste 202', 'Atlanta', 'GA', '30308', 33.7716849, -84.3851924, '', 'buyblack_org_directory'],
  ['1 Healthy Drink - RhodiGandha', 'Juice Bar', '170 Peachtree Rd NE', 'Atlanta', 'GA', '30303', 33.7580977, -84.3877842, '', 'buyblack_org_directory'],
  ['100 Hoodies', 'Clothing Store', '1314 Chattahoochee Ave NW Ste I2', 'Atlanta', 'GA', '30318', 33.8013496, -84.4309676, '', 'buyblack_org_directory'],
  ['1HR Press Bar', 'Hair Salon', '2411 Memorial Dr SE Ste A', 'Atlanta', 'GA', '30317', 33.7470167, -84.3081183, '', 'buyblack_org_directory'],
  ['1st Generation Electric', 'Electrical Contractor', '3571 S Fulton Ave', 'Atlanta', 'GA', '30354', 33.6568411, -84.4107276, '', 'buyblack_org_directory'],
  ['2 Amigos Tacos ATL', 'Restaurant', '1955 Campbellton Rd SW', 'Atlanta', 'GA', '30311', 33.7086047, -84.4531806, '', 'buyblack_org_directory'],
  ['20 West Realty', 'Real Estate Agency', '2440 Fairburn Rd SW #302', 'Atlanta', 'GA', '30331', 33.6880479, -84.5111183, '', 'buyblack_org_directory'],
  ['21 M Street', 'Restaurant', '2149 Metropolitan Pkwy SW', 'Atlanta', 'GA', '30315', 33.6958703, -84.4085995, '', 'buyblack_org_directory'],
  ["2J's One Stop Shop", 'Auto Repair Shop', '3519 Budreau Ave', 'Savannah', 'GA', '31408', 32.0965188, -81.1419920, '', 'buyblack_org_directory'],
  ['3 Bros Moving', 'Moving Company', '630 Indian St', 'Savannah', 'GA', '31401', 32.0849295, -81.0994119, '', 'buyblack_org_directory'],
  ['311 Hair Studio', 'Hair Salon', '123 Oglethorpe Professional Blvd Ste B', 'Savannah', 'GA', '31406', 32.0024652, -81.1077843, '', 'buyblack_org_directory'],
  ['520 Wings', 'Restaurant', '2701 Bull St', 'Savannah', 'GA', '31401', 32.0526370, -81.1023434, '', 'buyblack_org_directory'],
  ['A.M. Diverse Cooking', 'Catering Service', '100 Bull St Ste 200-2734', 'Savannah', 'GA', '31401', 32.0786619, -81.0917233, '', 'buyblack_org_directory'],
  ['Abercorn Dental', 'Dental Clinic', '1310 Abercorn St', 'Savannah', 'GA', '31401', 32.0623080, -81.0955437, '', 'buyblack_org_directory'],
  ["Adrian's Car Wash", 'Car Wash', '1111 Montgomery St', 'Savannah', 'GA', '31401', 32.0654252, -81.1021241, '', 'buyblack_org_directory'],
  ["Ahmad's Chop Shop", 'Barbershop', '7135 Hodgson Memorial Dr #23', 'Savannah', 'GA', '31406', 32.0062703, -81.1109816, '', 'buyblack_org_directory'],
  ['All American Liquor', 'Liquor Store', '4317 Ogeechee Rd #105', 'Savannah', 'GA', '31405', 32.0478439, -81.1660690, '', 'buyblack_org_directory'],
  ['AMPT Savannah', 'Fitness Studio', '411 W Charlton St', 'Savannah', 'GA', '31401', 32.0744631, -81.0990133, '', 'buyblack_org_directory'],
  ['Anew Med Spa & Clinic', 'Med Spa', '359 Commercial Dr Ste E', 'Savannah', 'GA', '31406', 32.0069381, -81.1075717, '', 'buyblack_org_directory'],
  ['Ashford Tea Company', 'Tea House', '406 E Oglethorpe Ave', 'Savannah', 'GA', '31401', 32.0758904, -81.0879694, '', 'buyblack_org_directory'],
  ['Automotive Repair On Wheels', 'Auto Repair Shop', '5307 Montgomery St', 'Savannah', 'GA', '31405', 32.0308882, -81.1153154, '', 'buyblack_org_directory'],
  ['One Stop Shop', 'Convenience Store', '2100 Montgomery St', 'Savannah', 'GA', '31401', 32.0579079, -81.1040917, '', 'buyblack_org_directory'],
  ['360 Automotive Group', 'Car Dealership', '5041 Mercer University Dr', 'Macon', 'GA', '31206', 32.8323368, -83.7273954, '', 'buyblack_org_directory'],
  ["Anderson's Diner", 'Restaurant', '1209 Eisenhower Pkwy', 'Macon', 'GA', '31206', 32.8149256, -83.6613153, '', 'buyblack_org_directory'],
  ['APremium Healthcare Solution', 'Home Care Service', '2012 Riverside Dr', 'Macon', 'GA', '31204', 32.8559076, -83.6451273, '', 'buyblack_org_directory'],
  ['Adams Jordan & Herrington', 'Law Firm', '915 Hill Park', 'Macon', 'GA', '31201', 32.8417227, -83.6321743, '', 'buyblack_org_directory'],
  ['Faith Hope & Love Store', 'Boutique', '7909 S Cottage Grove Ave', 'Chicago', 'IL', '60619', 41.7509326, -87.6050003, '', 'buyblack_org_directory'],
  ["King PeeWee's Cupcakes", 'Bakery', '828 N Lawler Ave', 'Chicago', 'IL', '60651', 41.8958920, -87.7522349, '', 'buyblack_org_directory'],
  ['14 Parish', 'Restaurant', '1644 E 53rd St', 'Chicago', 'IL', '60615', 41.7997524, -87.5848303, '', 'buyblack_org_directory'],
  ['24Life Training & Fitness', 'Fitness Studio', '2306 S State St', 'Chicago', 'IL', '60616', 41.8508392, -87.6273544, '', 'buyblack_org_directory'],
  ['26.2 Realty', 'Real Estate Agency', '2261 W 111th St #1', 'Chicago', 'IL', '60643', 41.6916087, -87.6786745, '', 'buyblack_org_directory'],
  ['360 Co-working & Event Space', 'Coworking Space', '360 E 69th St', 'Chicago', 'IL', '60637', 41.7695019, -87.6163228, '', 'buyblack_org_directory'],
  ["3D's Jerk Chicken", 'Restaurant', '5317 W North Ave', 'Chicago', 'IL', '60639', 41.9092212, -87.7589240, '', 'buyblack_org_directory'],
  ['3rd Lane Oasis', 'Boutique', '817 W 59th St', 'Chicago', 'IL', '60621', 41.7868488, -87.6457408, '', 'buyblack_org_directory'],
  ['4835 Studios', 'Arts & Entertainment', '4835 N Elston Ave', 'Chicago', 'IL', '60630', 41.9689147, -87.7409649, '', 'buyblack_org_directory'],
  ['529 Management', 'Professional Services', '1016 W Jackson Blvd Ste 296', 'Chicago', 'IL', '60607', 41.8780331, -87.6527651, '', 'buyblack_org_directory'],
];

async function main() {
  const serviceAccount = loadServiceAccount();
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  const db = admin.firestore();

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
    const [name, category, street, city, state, zip, lat, lng, website, source] = row;
    const nameCityKey = `${normalizeName(name)}|${normalizeCity(city)}`;
    const existing = byNameCity.get(nameCityKey);
    if (existing) {
      alreadyExists.push({ business_name: name, matched_existing_ids: existing });
      continue;
    }

    const ticker = pickTicker(name, takenTickers);
    takenTickers.add(ticker);

    toCreate.push({
      business_name: name, category, address: street, city, state,
      zip_code_postcode: zip, website, ticker_symbol: ticker,
      is_black_owned: true, is_verified: false, is_claimed: false,
      subscription_tier: 'Community', is_premium: false,
      directory_import_batch: IMPORT_BATCH, directory_import_source: source,
      _lat: lat, _lng: lng,
    });
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
      created_at: admin.firestore.FieldValue.serverTimestamp(),
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
