// Geocodes the 95 curated San Antonio African American Chamber of
// Commerce (AACCSA) member addresses (sa_aacc_curated.json - hand-curated
// down from 431 raw listings on the chamber's WP Business Directory
// Plugin site, members.africanamericanchambersa.org/business-directory).
//
// San Antonio already has substantial coverage (115 businesses, mostly
// from the BOB/AABE certification batch - see kin-app-directory-and-ui
// memory) - this batch adds a second, independent chamber-membership
// source on top of that, the same way Dallas's DBCC batch added to
// Dallas's existing generic-Places coverage.
//
// Mirrors geocode_iabb_atlanta.js's approach: query Google's Geocoding
// API with the address and pull street/city/state/zip back out of its
// own parsed address_components rather than trusting a regex split of
// the source text (learned the hard way on the Atlanta batch - see that
// script's header comment). The site's own address field frequently
// omitted city/state entirely (e.g. "211 whitecliff dr, 78227" with no
// "San Antonio, TX" at all) - since every zip seen across all 431 raw
// listings was a native San Antonio-area 78xxx code, "San Antonio, TX"
// was appended wherever city/state were missing during curation, and
// Google's own geocode of the resulting string is what's trusted for the
// final stored values, not the guess.
//
// Research only, mirrors every prior batch's posture - never touches
// Firestore. Produces sa_aacc_data.json (final seed input) plus
// sa_aacc_geocode_review.json (every row, including drops).
//
// Same Geocoding API + precision bar (ROOFTOP/RANGE_INTERPOLATED, plus
// the hasStreet component check added after the Atlanta bug) and
// distance sanity check as prior batches, centered on the same San
// Antonio coordinate GoogleMapPageWidget already uses as its own default
// map center (lib/pages/google_map_page/google_map_page_widget.dart).
// 35mi comfortably covers the metro without accepting a wrong-city match.
//
// Usage:
//   node geocode_aacc_sanantonio.js            # geocodes all curated rows
//   node geocode_aacc_sanantonio.js --limit 5  # smoke test

const fs = require('fs');
const path = require('path');
const https = require('https');

const INPUT_PATH = path.join(__dirname, 'sa_aacc_curated.json');
const OUTPUT_PATH = path.join(__dirname, 'sa_aacc_data.json');
const REVIEW_PATH = path.join(__dirname, 'sa_aacc_geocode_review.json');

// Same key already used by FlutterFlowPlacePicker/GeocodingService in this
// app - not a new credential (see geocode_bob_worklist.js).
const API_KEY = 'AIzaSyD1w4m7IaWva5Bxl9fsbsZgILC7R8wf_Go';

// Same default center GoogleMapPageWidget uses for San Antonio.
const SA_LAT = 29.4241;
const SA_LNG = -98.4936;
const MAX_DISTANCE_MILES = 35;

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

function extractAddressParts(components) {
  const get = (type) =>
    components.find((c) => c.types.includes(type))?.long_name || '';
  const getShort = (type) =>
    components.find((c) => c.types.includes(type))?.short_name || '';
  const streetNumber = get('street_number');
  const route = get('route');
  const street = [streetNumber, route].filter(Boolean).join(' ');
  return {
    street,
    city: get('locality') || get('sublocality') || get('postal_town'),
    state: getShort('administrative_area_level_1'),
    zip: get('postal_code'),
  };
}

async function main() {
  const rows = JSON.parse(fs.readFileSync(INPUT_PATH, 'utf8')).slice(0, LIMIT);
  const kept = [];
  const review = [];

  for (const row of rows) {
    const fullAddress = row.raw_address;
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
        const parts = extractAddressParts(best.address_components);

        const precise = locationType === 'ROOFTOP' || locationType === 'RANGE_INTERPOLATED';
        const distance = haversineMiles(lat, lng, SA_LAT, SA_LNG);
        const withinRange = distance <= MAX_DISTANCE_MILES;
        const hasStreet = parts.street.trim().length > 0;

        if (precise && withinRange && hasStreet) {
          status = 'kept';
          kept.push({
            name: row.name,
            category: row.category || '',
            street: parts.street,
            city: parts.city,
            state: parts.state || 'TX',
            zip: parts.zip,
            lat,
            lng,
            phone: (row.phone || '').replace(/\D/g, ''),
          });
        } else if (!precise || !hasStreet) {
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
