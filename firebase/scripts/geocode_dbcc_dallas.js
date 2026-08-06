// Geocodes the 53 curated Dallas Black Chamber of Commerce (DBCC) member
// addresses (dallas_dbcc_curated.json - hand-curated down from 72 raw
// profile-page fetches, same exclusion bar as NORBCC's New Orleans batch:
// dropped large/national corporations and franchise brands, nonprofits/
// foundations, out-of-state entries, and anything with no street address
// at all).
//
// Research only, mirrors geocode_bob_worklist.js's posture - never
// touches Firestore. Produces dallas_dbcc_data.json (the final seed
// input, same shape as norbcc_new_orleans_data.json:
// {name, category, street, city, state, zip, lat, lng, phone}) plus
// dallas_dbcc_geocode_review.json (every row, including drops, for a
// human to spot-check).
//
// Uses the plain Geocoding API rather than findplacefromtext (which
// geocode_bob_worklist.js uses) because these rows already have full
// street addresses, not just business names - Geocoding is the more
// precise tool for address-in, point-out. Same Google Maps API key
// already used client-side by GeocodingService/FlutterFlowPlacePicker.
//
// A result is kept only if Google's location_type is ROOFTOP or
// RANGE_INTERPOLATED (a real street-level match) - GEOMETRIC_CENTER/
// APPROXIMATE means Google fell back to a city or ZIP centroid, the same
// "no confirmed precise location" bar NORBCC applied (that batch dropped
// 6 rows on exactly this test, plus one more - "2 B Chic Boutiqe" - on a
// post-geocode distance sanity check catching a street name that
// geocoded to an unrelated town 127 miles away). This script applies
// that same distance sanity check: any result more than 60 miles from
// downtown Dallas is dropped rather than trusted, since every kept row
// here should be somewhere in the DFW metro or immediately adjacent
// (Fort Worth/Houston entries seen so far are >150mi and were excluded
// by hand already; 60mi comfortably covers legitimate DFW-metro drift
// without accepting a geocoder mistake going out to another city).
//
// Usage:
//   node geocode_dbcc_dallas.js            # geocodes all curated rows
//   node geocode_dbcc_dallas.js --limit 5  # smoke test

const fs = require('fs');
const path = require('path');
const https = require('https');

const INPUT_PATH = path.join(__dirname, 'dallas_dbcc_curated.json');
const OUTPUT_PATH = path.join(__dirname, 'dallas_dbcc_data.json');
const REVIEW_PATH = path.join(__dirname, 'dallas_dbcc_geocode_review.json');

// Same key already used by FlutterFlowPlacePicker/GeocodingService in this
// app - not a new credential (see geocode_bob_worklist.js).
const API_KEY = 'AIzaSyD1w4m7IaWva5Bxl9fsbsZgILC7R8wf_Go';

// Downtown Dallas (Reunion Tower) - the distance sanity-check anchor.
const DALLAS_LAT = 32.7756;
const DALLAS_LNG = -96.8089;
const MAX_DISTANCE_MILES = 60;

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
        const distance = haversineMiles(lat, lng, DALLAS_LAT, DALLAS_LNG);
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

    // Stay well under Google's rate limits - this is a one-off research
    // run, not a hot path.
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
