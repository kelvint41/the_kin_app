// Applies the City of San Antonio / Bexar County certified Black-owned
// business list to the `businesses` collection as a *certification signal*,
// and emits a re-verification worklist for the rest.
//
// Source file (repo root, gitignored - it carries third-party PII):
//   BOB_Bexar Listing_202010051132064966 (1) - Certified BOB AABE_Bexar_CDMS.csv
//
// Why it is not a plain import:
//   The file has 366 certified businesses but NO street address - only city
//   and ZIP (58 distinct). Placing 347 unmatched businesses at ZIP centroids
//   would put map pins on addresses that do not exist and route shoppers to
//   nothing, so only businesses already in the directory (with real
//   coordinates) are touched. The rest are written out as a worklist to be
//   address-researched before they can appear on the map.
//
//   The file is also dated 2020-10-05. Five and a half years of small
//   business closure and relocation means every row needs re-confirmation
//   before it is presented to users as current.
//
// PII:
//   Every row carries Primary Owner Salutation / First Name / Last Name /
//   Suffix / Email - personal data belonging to third parties who did not
//   give it to KIN. None of it is read into Firestore or into the worklist.
//   See PII_COLUMNS below; the script asserts they never leave this file.
//
// What a match gets:
//   is_black_owned            true   (certification is evidence of ownership)
//   is_certified_black_owned  true
//   certification_source      'BOB Bexar County / AABE (City of San Antonio)'
//   certification_as_of       '2020-10-05'
//
//   certification_as_of is deliberately the *source* date, not today, so the
//   staleness travels with the record instead of being laundered into a
//   fresh-looking verification.
//
// Usage:
//   node apply_bob_certification.js            # dry run - writes nothing
//   node apply_bob_certification.js --commit   # applies to Firestore
//
// Safety:
//   - Defaults to dry run; --commit is required to write.
//   - Matches only on phone, or on name + city together. A bare name match
//     is reported but not applied - "Elite Barber Shop" is not a unique key.
//   - Never creates a business document. It only annotates existing ones.

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS
  || path.join(__dirname, 'serviceAccountKey.json');
const BOB_CSV_PATH = path.join(
  __dirname, '..', '..',
  'BOB_Bexar Listing_202010051132064966 (1) - Certified BOB AABE_Bexar_CDMS.csv'
);
const WORKLIST_PATH = path.join(__dirname, 'bob_reverification_worklist.csv');
const RESULTS_LOG_PATH = path.join(__dirname, 'bob_certification_results.json');
const COLLECTION = 'businesses';

const CERTIFICATION_SOURCE = 'BOB Bexar County / AABE (City of San Antonio)';
const CERTIFICATION_AS_OF = '2020-10-05';

/// Columns that must never reach Firestore or the worklist.
const PII_COLUMNS = [
  'Primary Owner Salutation',
  'Primary Owner First Name',
  'Primary Owner Last Name',
  'Primary Owner Suffix',
  'Primary Owner Email',
];

/// Business-level contact fields, kept. A business's own published phone and
/// email are not personal data in the way the owner columns are.
const WORKLIST_COLUMNS = [
  'Business Name', 'Phone', 'Email', 'City', 'State/Province',
  'Zip Code/Postcode', 'County', 'Website', 'Business Description',
];

/// Dropping the five owner columns is not enough on its own: in 320 of the
/// 366 rows the "business" Email is byte-identical to Primary Owner Email,
/// and 150 of those are consumer mailboxes. A name@gmail.com belongs to a
/// person whatever column it is filed under, so it is redacted; an address
/// on the company's own domain is a published business contact and is kept.
const FREEMAIL_DOMAINS = new Set([
  'gmail.com', 'yahoo.com', 'hotmail.com', 'aol.com', 'outlook.com',
  'icloud.com', 'msn.com', 'live.com', 'att.net', 'sbcglobal.net',
  'me.com', 'comcast.net', 'verizon.net', 'mail.com', 'ymail.com',
  'protonmail.com', 'earthlink.net', 'roadrunner.com', 'juno.com',
]);

/// Scans anywhere in the value rather than assuming the address sits alone in
/// the Email column - the source has consumer addresses typed into Website
/// too ("http://aaaprestige.ac_heating@yahoo.com"), so a column-scoped rule
/// leaks them out the side.
const EMAIL_PATTERN = /[A-Za-z0-9._%+-]+@([A-Za-z0-9.-]+\.[A-Za-z]{2,})/g;

function redactPersonalEmail(value) {
  const text = (value === null || value === undefined) ? '' : value.toString();
  if (!text.includes('@')) return text;
  return text.replace(EMAIL_PATTERN, (match, domain) => (
    FREEMAIL_DOMAINS.has(domain.toLowerCase()) ? '[redacted-personal-email]' : match
  ));
}

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

/// Minimal RFC4180 reader - the source file quotes descriptions that contain
/// commas, so splitting on ',' alone corrupts every row after the first.
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

/// Last 10 digits, so (210) 555-1234 and +1 210 555 1234 compare equal.
function normalizePhone(value) {
  const digits = (value || '').toString().replace(/\D/g, '');
  return digits.length >= 10 ? digits.slice(-10) : '';
}

function csvEscape(value) {
  const str = (value === null || value === undefined) ? '' : value.toString();
  return /[",\n]/.test(str) ? `"${str.replace(/"/g, '""')}"` : str;
}

async function main() {
  const serviceAccount = loadServiceAccount();
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  const db = admin.firestore();

  console.log(`Project: ${serviceAccount.project_id}`);
  console.log(`Mode: ${isCommit ? 'COMMIT (will write to Firestore)' : 'DRY RUN (no writes)'}`);

  if (!fs.existsSync(BOB_CSV_PATH)) {
    console.error(`Missing source file: ${BOB_CSV_PATH}`);
    process.exit(1);
  }
  const bobRows = parseCsv(fs.readFileSync(BOB_CSV_PATH, 'utf8'));
  console.log(`Loaded ${bobRows.length} certified businesses from the BOB list.`);

  const snapshot = await db.collection(COLLECTION).get();
  const byPhone = new Map();
  const byNameCity = new Map();
  const byName = new Map();
  snapshot.forEach((doc) => {
    const data = doc.data();
    const entry = { id: doc.id, data };
    const phone = normalizePhone(data.phone_number);
    if (phone) {
      const bucket = byPhone.get(phone) || [];
      bucket.push(entry);
      byPhone.set(phone, bucket);
    }
    const name = normalizeName(data.business_name);
    if (!name) return;
    const nameCity = `${name}|${normalizeCity(data.city)}`;
    const cityBucket = byNameCity.get(nameCity) || [];
    cityBucket.push(entry);
    byNameCity.set(nameCity, cityBucket);
    const nameBucket = byName.get(name) || [];
    nameBucket.push(entry);
    byName.set(name, nameBucket);
  });
  console.log(`Indexed ${snapshot.size} existing business documents.`);

  const matches = [];
  const weakMatches = [];
  const unmatched = [];

  for (const row of bobRows) {
    const phone = normalizePhone(row.Phone);
    const name = normalizeName(row['Business Name']);
    const city = normalizeCity(row.City);

    const hits = byPhone.get(phone) || byNameCity.get(`${name}|${city}`) || [];
    if (hits.length > 0) {
      const how = (byPhone.get(phone) || []).length > 0 ? 'phone' : 'name+city';
      hits.forEach((hit) => matches.push({
        docId: hit.id,
        business_name: hit.data.business_name,
        city: hit.data.city,
        matched_on: how,
        bob_name: row['Business Name'],
      }));
      continue;
    }

    // Name-only hits are surfaced for a human to confirm, never auto-applied.
    const loose = byName.get(name) || [];
    if (loose.length > 0) {
      weakMatches.push({
        bob_name: row['Business Name'],
        bob_city: row.City,
        candidates: loose.map((h) => `${h.data.business_name} (${h.data.city}) [${h.id}]`),
      });
      continue;
    }
    unmatched.push(row);
  }

  // The BOB list repeats businesses - EJ Smith Construction appears on four
  // rows, Spirits Heart on two - so several rows resolve to the same Firestore
  // document. Collapse by document id: the count then reflects businesses
  // certified rather than source rows matched, and the batch below writes each
  // document once instead of queueing redundant identical updates.
  const byDocId = new Map();
  for (const match of matches) {
    const existing = byDocId.get(match.docId);
    if (existing) {
      existing.bob_names.add(match.bob_name);
    } else {
      byDocId.set(match.docId, {
        docId: match.docId,
        business_name: match.business_name,
        city: match.city,
        matched_on: match.matched_on,
        bob_names: new Set([match.bob_name]),
      });
    }
  }
  // A shared phone number is not proof of certification. The BOB list contains
  // families of companies on one switchboard - Event Professional Services, EJ
  // Smith Management, EJ Smith Construction and EJ Smith Supply all share a
  // line - so a phone hit alone would certify a sibling that is not itself on
  // the list. Require the business's own name to appear on it; anything that
  // matched only by phone goes to manual review rather than being written.
  const uniqueMatches = [];
  for (const entry of byDocId.values()) {
    const bobNames = [...entry.bob_names];
    const confirmed = bobNames.some(
      (name) => normalizeName(name) === normalizeName(entry.business_name)
    );
    if (confirmed) {
      uniqueMatches.push({ ...entry, bob_names: bobNames });
    } else {
      weakMatches.push({
        bob_name: bobNames.join(' | '),
        bob_city: entry.city,
        candidates: [
          `${entry.business_name} (${entry.city}) [${entry.docId}]`
          + ' - phone matched but this name is not on the BOB list',
        ],
      });
    }
  }

  console.log(`\nConfident matches (phone, or name+city): ${uniqueMatches.length}`
    + ` businesses, from ${matches.length} source row(s)`);
  uniqueMatches.forEach((m) => {
    console.log(`  ${m.business_name} (${m.city}) via ${m.matched_on}`);
    if (m.bob_names.length > 1) {
      console.log(`      matched ${m.bob_names.length} BOB rows: ${m.bob_names.join(' | ')}`);
    }
  });

  if (weakMatches.length > 0) {
    console.log(`\nName-only candidates - NOT applied, confirm by hand: ${weakMatches.length}`);
    weakMatches.forEach((w) => {
      console.log(`  "${w.bob_name}" (${w.bob_city}) ->`);
      w.candidates.forEach((c) => console.log(`      ${c}`));
    });
  }

  console.log(`\nNo match - need address research before they can go on the map: ${unmatched.length}`);

  // Worklist. PII columns are excluded by construction: WORKLIST_COLUMNS is an
  // allowlist, and this asserts the two lists never overlap.
  const leaked = WORKLIST_COLUMNS.filter((c) => PII_COLUMNS.includes(c));
  if (leaked.length > 0) {
    console.error(`Aborting: worklist would leak owner PII columns: ${leaked.join(', ')}`);
    process.exit(1);
  }
  const worklist = [
    [...WORKLIST_COLUMNS, 'needs_address', 'certification_as_of'].join(','),
    ...unmatched.map((row) => [
      ...WORKLIST_COLUMNS.map((c) => csvEscape(redactPersonalEmail(row[c]))),
      'TRUE',
      CERTIFICATION_AS_OF,
    ].join(',')),
  ].join('\n');
  fs.writeFileSync(WORKLIST_PATH, `${worklist}\n`);
  console.log(`Worklist written to ${WORKLIST_PATH} (owner PII columns excluded).`);

  const results = {
    mode: isCommit ? 'commit' : 'dry-run',
    source_rows: bobRows.length,
    matched: uniqueMatches,
    matched_source_rows: matches.length,
    name_only_candidates: weakMatches,
    unmatched_count: unmatched.length,
  };

  if (!isCommit) {
    fs.writeFileSync(RESULTS_LOG_PATH, JSON.stringify(results, null, 2));
    console.log(`\nDry run only - re-run with --commit to apply certification to the ${uniqueMatches.length} businesses.`);
    return;
  }

  const batch = db.batch();
  for (const match of uniqueMatches) {
    batch.update(db.collection(COLLECTION).doc(match.docId), {
      is_black_owned: true,
      is_certified_black_owned: true,
      certification_source: CERTIFICATION_SOURCE,
      certification_as_of: CERTIFICATION_AS_OF,
    });
  }
  await batch.commit();
  fs.writeFileSync(RESULTS_LOG_PATH, JSON.stringify(results, null, 2));
  console.log(`\nApplied certification to ${uniqueMatches.length} document(s).`);
  console.log(`Results written to ${RESULTS_LOG_PATH}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
