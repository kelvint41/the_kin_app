// Geocodes the 53 curated Chatham Business Association (CBA) member
// addresses (chi_cba_curated.json - hand-curated down from 79 raw
// listings on members.cbaworks.org, a legacy ChamberMaster theme -
// different DOM than GWBCC's newer GrowthZone template but the same
// underlying platform family and the same schema.org address microdata
// inline per card).
//
// CBA represents Chicago's Chatham neighborhood specifically (a historic
// South Side Black business district), not the whole city - Black
// Chamber of Commerce of Illinois (bcciinc.org), the other option
// researched for Chicago, is offline (DNS doesn't resolve at all), so
// this is the only workable Chicago source found.
//
// Curation dropped 15 of 68 addressed raw entries: several large
// national corporate sponsors (AT&T, Best Buy, Comcast Business, Capital
// One, PNC Bank, US Bank, Old Second National Bank, Exelon ComEd, Floor &
// Decor, Sterling Bay Companies), a labor union (Chicago Regional Council
// of Carpenters), a government/political office listing, the chamber's
// own self-listing, and 2 rows of bad source data (a "ServiceMaster of
// Southern Nevada" franchise entry and a mismatched-zip duplicate that
// clearly don't belong in a Chicago directory). Two historically
// Black-owned banks with a presence in the area (Liberty Bank and Trust,
// Seaway/Self-Help FCU) were deliberately KEPT despite being sizable
// institutions, same reasoning as DC's Industrial Bank/Harbor Bank of
// Maryland and Atlanta's insurance-agent franchises: large ≠ automatic
// exclusion, large-and-not-what-this-directory-represents is.
//
// Research only, mirrors every prior batch's posture - never touches
// Firestore. Produces chi_cba_data.json (final seed input) plus
// chi_cba_geocode_review.json (every row, including drops).
//
// Same Geocoding API + precision bar (ROOFTOP/RANGE_INTERPOLATED plus the
// hasStreet component check) as every batch since the Atlanta bug fix.
// Centered on downtown Chicago; 30mi covers the real Chicagoland spread
// seen in this batch (South Holland, Calumet City, Burr Ridge, Forest
// Park, Oak Lawn, Schaumburg all appeared during curation, all
// comfortably inside it) without accepting a genuinely wrong-city match.
//
// Usage:
//   node geocode_cba_chicago.js            # geocodes all curated rows
//   node geocode_cba_chicago.js --limit 5  # smoke test

const fs = require('fs');
const path = require('path');
const https = require('https');

const INPUT_PATH = path.join(__dirname, 'chi_cba_curated.json');
const OUTPUT_PATH = path.join(__dirname, 'chi_cba_data.json');
const REVIEW_PATH = path.join(__dirname, 'chi_cba_geocode_review.json');

// Same key already used by FlutterFlowPlacePicker/GeocodingService in this
// app - not a new credential (see geocode_bob_worklist.js).
const API_KEY = 'AIzaSyD1w4m7IaWva5Bxl9fsbsZgILC7R8wf_Go';

// Willis Tower - the distance sanity-check anchor.
const CHI_LAT = 41.8789;
const CHI_LNG = -87.6359;
const MAX_DISTANCE_MILES = 30;

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
        const parts = extractAddressParts(best.address_components);

        const precise = locationType === 'ROOFTOP' || locationType === 'RANGE_INTERPOLATED';
        const distance = haversineMiles(lat, lng, CHI_LAT, CHI_LNG);
        const withinRange = distance <= MAX_DISTANCE_MILES;
        const hasStreet = parts.street.trim().length > 0;

        if (precise && withinRange && hasStreet) {
          status = 'kept';
          kept.push({
            name: row.name,
            category: row.category || '',
            street: parts.street,
            city: parts.city,
            state: parts.state || 'IL',
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
