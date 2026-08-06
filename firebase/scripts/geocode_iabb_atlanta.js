// Geocodes the 523 curated Atlanta "I Am Black Business" (IABB) listings
// (atl_iabb_curated.json - filtered from 999 raw listings on the Atlanta
// Black Chambers instance of the platform, abc.iamblackbusiness.com).
//
// Different provenance from the Dallas/DC chamber-membership batches:
// IABB is a purpose-built Black-owned-business directory (not a general
// chamber membership roster that happens to include large non-Black-owned
// sponsors alongside real small businesses), so curation here was lighter
// - filtered to GA addresses, dropped the "Organizations" category
// (nonprofits/foundations - see atl_iabb_curated.json's construction step
// for examples), and spot-checked for large-corporation names (found only
// 2 false-positive matches, both individual insurance agent franchises -
// "William Henry State Farm" and "The Douglass Allstate Agency" - kept,
// same reasoning as Dallas's MIM Insurance Solutions: the agent owns the
// storefront even though it operates under a national brand).
//
// Research only, mirrors geocode_gwbcc_dc.js's posture - never touches
// Firestore. Produces atl_iabb_data.json (final seed input, same shape as
// the Dallas/DC ones) plus atl_iabb_geocode_review.json (every row,
// including drops, for a human to spot-check).
//
// Same Geocoding API + precision bar (ROOFTOP/RANGE_INTERPOLATED) and
// distance sanity check as the prior two batches, centered on downtown
// Atlanta. 40mi covers the real Atlanta metro sprawl (Kennesaw, Duluth,
// Morrow, Alpharetta all seen in this batch during curation, all
// comfortably inside it) without accepting a wrong-city geocode.
//
// Usage:
//   node geocode_iabb_atlanta.js            # geocodes all curated rows
//   node geocode_iabb_atlanta.js --limit 5  # smoke test

const fs = require('fs');
const path = require('path');
const https = require('https');

const INPUT_PATH = path.join(__dirname, 'atl_iabb_curated.json');
const OUTPUT_PATH = path.join(__dirname, 'atl_iabb_data.json');
const REVIEW_PATH = path.join(__dirname, 'atl_iabb_geocode_review.json');

// Same key already used by FlutterFlowPlacePicker/GeocodingService in this
// app - not a new credential (see geocode_bob_worklist.js).
const API_KEY = 'AIzaSyD1w4m7IaWva5Bxl9fsbsZgILC7R8wf_Go';

// Georgia State Capitol - the distance sanity-check anchor.
const ATL_LAT = 33.7490;
const ATL_LNG = -84.3880;
const MAX_DISTANCE_MILES = 40;

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

// Pulls street/city/state/zip out of Google's own parsed
// address_components rather than trusting any regex split of the source
// text - the source addresses have no comma between street and city
// ("10105 Westside Parkway Alpharetta,GA 30009"), which a first pass at
// this script tried to split with a regex and got wrong on every single
// row (grabbed only the leading house number as the street, dumped the
// rest - "Westside Parkway Alpharetta" - into city). Google has already
// solved this problem correctly as a side effect of geocoding the address
// in the first place, so use its answer instead of re-deriving it badly.
function extractAddressParts(components) {
  const get = (type) =>
    components.find((c) => c.types.includes(type))?.long_name || '';
  // Short name (e.g. "GA", not "Georgia") - the one field of the four
  // this repo's other seed scripts store abbreviated.
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
        const distance = haversineMiles(lat, lng, ATL_LAT, ATL_LNG);
        const withinRange = distance <= MAX_DISTANCE_MILES;
        // Google's own component parse must have actually found a street
        // number/route, not just a locality-level match dressed up as
        // "precise" - belt-and-suspenders on top of the location_type
        // check, since a bare "GEOMETRIC_CENTER" isn't the only way a
        // messy source address can resolve to something too vague to use.
        const hasStreet = parts.street.trim().length > 0;

        if (precise && withinRange && hasStreet) {
          status = 'kept';
          kept.push({
            name: row.name,
            category: row.category || '',
            street: parts.street,
            city: parts.city,
            state: parts.state || 'GA',
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
