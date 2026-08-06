// Geocodes the 27 curated Greater Washington DC Black Chamber of Commerce
// (GWBCC) member addresses (dc_gwbcc_curated.json - hand-curated down from
// 106 raw member-directory entries, same exclusion bar as the Dallas/New
// Orleans batches: dropped large/national corporations and anything
// clearly outside the metro).
//
// Research only, mirrors geocode_dbcc_dallas.js's posture - never touches
// Firestore. Produces dc_gwbcc_data.json (the final seed input, same
// shape as dallas_dbcc_data.json: {name, category, street, city, state,
// zip, lat, lng, phone}) plus dc_gwbcc_geocode_review.json (every row,
// including drops, for a human to spot-check).
//
// Same Geocoding API + precision bar (ROOFTOP/RANGE_INTERPOLATED only) and
// distance sanity check as the Dallas script, just re-centered on
// downtown DC and with a tighter radius - DC's own metro area is smaller
// than DFW's, and a couple of GWBCC members already turned up genuinely
// outside it (Philadelphia, suburban Atlanta) during curation, so 45mi
// comfortably covers the real DC/MD/VA suburbs (Silver Spring, Columbia
// MD, Dumfries VA all fall well inside it) without accepting a mistaken
// or out-of-metro member the way a Dallas-sized 60mi radius might.
//
// Usage:
//   node geocode_gwbcc_dc.js            # geocodes all curated rows
//   node geocode_gwbcc_dc.js --limit 5  # smoke test

const fs = require('fs');
const path = require('path');
const https = require('https');

const INPUT_PATH = path.join(__dirname, 'dc_gwbcc_curated.json');
const OUTPUT_PATH = path.join(__dirname, 'dc_gwbcc_data.json');
const REVIEW_PATH = path.join(__dirname, 'dc_gwbcc_geocode_review.json');

// Same key already used by FlutterFlowPlacePicker/GeocodingService in this
// app - not a new credential (see geocode_bob_worklist.js).
const API_KEY = 'AIzaSyD1w4m7IaWva5Bxl9fsbsZgILC7R8wf_Go';

// The White House - the distance sanity-check anchor.
const DC_LAT = 38.8977;
const DC_LNG = -77.0365;
const MAX_DISTANCE_MILES = 45;

const limitArgIdx = process.argv.indexOf('--limit');
const LIMIT = limitArgIdx >= 0 ? parseInt(process.argv[limitArgIdx + 1], 10) : Infinity;

function haversineMiles(lat1, lng1, lat2, lng2) {
  const R = 3958.8;
  const toRad = (d) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function geocodeAddress(fullAddress) {
  return new Promise((resolve, reject) => {
    const params = new URLSearchParams({ address: fullAddress, key: API_KEY });
    https
      .get(`https://maps.googleapis.com/maps/api/geocode/json?${params}`, (res) => {
        let body = '';
        res.on('data', (chunk) => (body += chunk));
        res.on('end', () => {
          try {
            resolve(JSON.parse(body));
          } catch (e) {
            reject(e);
          }
        });
      })
      .on('error', reject);
  });
}

async function main() {
  const rows = JSON.parse(fs.readFileSync(INPUT_PATH, 'utf8')).slice(0, LIMIT);
  const kept = [];
  const review = [];

  for (const row of rows) {
    const fullAddress = `${row.street}, ${row.city}, ${row.state} ${row.zip}`;
    let status = 'error';
    let lat, lng, locationType, formattedAddress;

    try {
      const result = await geocodeAddress(fullAddress);
      if (result.status === 'OK' && result.results.length > 0) {
        const best = result.results[0];
        lat = best.geometry.location.lat;
        lng = best.geometry.location.lng;
        locationType = best.geometry.location_type;
        formattedAddress = best.formatted_address;

        const precise = locationType === 'ROOFTOP' || locationType === 'RANGE_INTERPOLATED';
        const distance = haversineMiles(lat, lng, DC_LAT, DC_LNG);
        const withinRange = distance <= MAX_DISTANCE_MILES;

        if (precise && withinRange) {
          status = 'kept';
          kept.push({
            name: row.name,
            category: row.category || '',
            street: row.street,
            city: row.city,
            state: row.state,
            zip: row.zip,
            lat,
            lng,
            phone: (row.phone || '').replace(/\D/g, ''),
          });
        } else if (!precise) {
          status = 'dropped_imprecise';
        } else {
          status = `dropped_out_of_range_${distance.toFixed(0)}mi`;
        }
      } else {
        status = `dropped_no_result_(${result.status})`;
      }
    } catch (e) {
      status = `error_${e.message}`;
    }

    review.push({
      name: row.name,
      queryAddress: fullAddress,
      status,
      formattedAddress,
      lat,
      lng,
      locationType,
    });

    await new Promise((r) => setTimeout(r, 120));
  }

  fs.writeFileSync(OUTPUT_PATH, JSON.stringify(kept, null, 2));
  fs.writeFileSync(REVIEW_PATH, JSON.stringify(review, null, 2));

  const dropped = review.filter((r) => r.status !== 'kept');
  console.log(`Geocoded ${rows.length} rows: ${kept.length} kept, ${dropped.length} dropped.`);
  if (dropped.length) {
    console.log('Dropped:');
    dropped.forEach((r) => console.log(`  - ${r.name}: ${r.status}`));
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
