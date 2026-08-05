// Looks up a real street address + coordinates for every business in
// bob_reverification_worklist.csv (the 347 BOB-certified businesses that
// had no directory match and no street address - see
// apply_bob_certification.js's header comment for why they were held
// back from the map instead of guessed).
//
// This is research only. It never writes to Firestore and never creates
// a business document - it produces a review file
// (bob_geocode_results.json) for a human to read before anything is
// imported. The source list is from 2020; Google's business_status field
// is used to flag likely closures so those don't get reviewed as if they
// were live.
//
// Uses the Places API "Find Place From Text" endpoint (same Google Maps
// API key already used client-side by GeocodingService and
// FlutterFlowPlacePicker - see lib/services/geocoding_service.dart -
// this is a new caller of an existing credential, not a new one) because
// it resolves a business *name*, unlike the plain Geocoding API which
// expects a street address.
//
// Usage:
//   node geocode_bob_worklist.js            # looks up all 347 rows
//   node geocode_bob_worklist.js --limit 10 # smoke test on a subset
//
// Output: firebase/scripts/bob_geocode_results.json
//   Each row: source business name/city/zip/description (no owner PII -
//   the worklist already excludes it), the matched place name + formatted
//   address + lat/lng + business_status, and a `name_match` confidence
//   flag (exact normalized match vs. loose) so weak matches are obvious
//   at a glance instead of silently mixed in with good ones.

const fs = require('fs');
const path = require('path');
const https = require('https');

const WORKLIST_PATH = path.join(__dirname, 'bob_reverification_worklist.csv');
const RESULTS_PATH = path.join(__dirname, 'bob_geocode_results.json');

// Same key already used by FlutterFlowPlacePicker/GeocodingService in this
// app - not a new credential.
const API_KEY = 'AIzaSyD1w4m7IaWva5Bxl9fsbsZgILC7R8wf_Go';

const limitArgIdx = process.argv.indexOf('--limit');
const LIMIT = limitArgIdx >= 0 ? parseInt(process.argv[limitArgIdx + 1], 10) : Infinity;

/// Minimal RFC4180 reader, same as apply_bob_certification.js.
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

function findPlace(query) {
  return new Promise((resolve) => {
    const params = new URLSearchParams({
      input: query,
      inputtype: 'textquery',
      fields: 'place_id,name,formatted_address,geometry,business_status',
      locationbias: 'circle:50000@29.4241,-98.4936', // San Antonio, 50km
      key: API_KEY,
    });
    https.get(`https://maps.googleapis.com/maps/api/place/findplacefromtext/json?${params}`, (res) => {
      let body = '';
      res.on('data', (chunk) => { body += chunk; });
      res.on('end', () => {
        try {
          const json = JSON.parse(body);
          resolve(json);
        } catch (e) {
          resolve({ status: 'PARSE_ERROR', error: e.message });
        }
      });
    }).on('error', (e) => resolve({ status: 'REQUEST_ERROR', error: e.message }));
  });
}

async function main() {
  if (!fs.existsSync(WORKLIST_PATH)) {
    console.error(`Missing ${WORKLIST_PATH} - run apply_bob_certification.js first.`);
    process.exit(1);
  }
  const rows = parseCsv(fs.readFileSync(WORKLIST_PATH, 'utf8')).slice(0, LIMIT);
  console.log(`Looking up ${rows.length} businesses via Places API...`);

  const results = [];
  let found = 0, closed = 0, notFound = 0, weakName = 0;

  for (let i = 0; i < rows.length; i += 1) {
    const row = rows[i];
    const query = `${row['Business Name']}, ${row.City}, TX`;
    const resp = await findPlace(query);

    if (resp.status !== 'OK' || !resp.candidates || resp.candidates.length === 0) {
      notFound += 1;
      results.push({
        business_name: row['Business Name'],
        city: row.City,
        zip: row['Zip Code/Postcode'],
        website: row.Website,
        description: row['Business Description'],
        match: null,
        place_status: resp.status,
      });
    } else {
      const candidate = resp.candidates[0];
      const isClosed = candidate.business_status
        && candidate.business_status !== 'OPERATIONAL';
      if (isClosed) closed += 1; else found += 1;

      const nameMatch = normalizeName(candidate.name) === normalizeName(row['Business Name']);
      if (!nameMatch) weakName += 1;

      results.push({
        business_name: row['Business Name'],
        city: row.City,
        zip: row['Zip Code/Postcode'],
        website: row.Website,
        description: row['Business Description'],
        match: {
          place_id: candidate.place_id,
          matched_name: candidate.name,
          formatted_address: candidate.formatted_address,
          lat: candidate.geometry?.location?.lat ?? null,
          lng: candidate.geometry?.location?.lng ?? null,
          business_status: candidate.business_status || 'UNKNOWN',
          name_match: nameMatch ? 'exact' : 'weak',
        },
      });
    }

    if ((i + 1) % 25 === 0 || i === rows.length - 1) {
      console.log(`  ${i + 1}/${rows.length} processed`);
    }
    // Be polite to the API - small delay between requests.
    await new Promise((r) => setTimeout(r, 120));
  }

  const summary = {
    source_rows: rows.length,
    operational_matches: found,
    likely_closed_or_moved: closed,
    no_match: notFound,
    weak_name_matches: weakName,
  };
  console.log('\nSummary:', JSON.stringify(summary, null, 2));

  fs.writeFileSync(RESULTS_PATH, JSON.stringify({ summary, results }, null, 2));
  console.log(`\nWritten to ${RESULTS_PATH}. Nothing was written to Firestore -`);
  console.log('this is a review file only. Read it before deciding what to import.');
}

main().catch((err) => { console.error(err); process.exit(1); });
