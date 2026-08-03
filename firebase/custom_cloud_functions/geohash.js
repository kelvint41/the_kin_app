/**
 * Geohash encoding for Cloud Functions.
 *
 * A business is only visible on the map if it carries a `geohash`:
 * GoogleMapPageModel queries by geohash prefix range, not by GeoPoint. Until
 * now nothing computed one at write time - it existed solely in a one-off
 * backfill script (firebase/scripts/backfill_business_geohashes.js) - so any
 * business created after that backfill was silently invisible on the map no
 * matter how good its coordinates were.
 *
 * Same base32 bit-interleaving algorithm as
 * lib/flutter_flow/geohash_util.dart's encodeGeohash and the backfill
 * script's copy. Three hand-synced implementations is two too many; if this
 * needs changing, change all three. Precision 9 matches what the backfill
 * wrote, and the map's prefix queries assume it.
 */
const GEOHASH_PRECISION = 9;

const BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz";

function encodeGeohash(lat, lng, precision = GEOHASH_PRECISION) {
  let latMin = -90, latMax = 90, lngMin = -180, lngMax = 180;
  let out = "";
  let bit = 0;
  let ch = 0;
  let evenBit = true;

  while (out.length < precision) {
    if (evenBit) {
      const mid = (lngMin + lngMax) / 2;
      if (lng >= mid) {
        ch |= 1 << (4 - bit);
        lngMin = mid;
      } else {
        lngMax = mid;
      }
    } else {
      const mid = (latMin + latMax) / 2;
      if (lat >= mid) {
        ch |= 1 << (4 - bit);
        latMin = mid;
      } else {
        latMax = mid;
      }
    }
    evenBit = !evenBit;
    if (bit < 4) {
      bit++;
    } else {
      out += BASE32[ch];
      bit = 0;
      ch = 0;
    }
  }
  return out;
}

module.exports = { encodeGeohash, GEOHASH_PRECISION };
