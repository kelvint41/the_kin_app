import 'dart:math';

/// Standard base32 geohash alphabet.
const _kBase32 = '0123456789bcdefghjkmnpqrstuvwxyz';

/// Encodes a lat/lng pair into a base32 geohash string, `precision`
/// characters long. Standard bit-interleaving algorithm - each character
/// packs 5 bits, alternating which half of the remaining longitude/latitude
/// range the point falls in.
String encodeGeohash(double lat, double lng, {int precision = 8}) {
  var latMin = -90.0, latMax = 90.0, lngMin = -180.0, lngMax = 180.0;
  final buffer = StringBuffer();
  var bit = 0;
  var ch = 0;
  var evenBit = true;

  while (buffer.length < precision) {
    if (evenBit) {
      final mid = (lngMin + lngMax) / 2;
      if (lng >= mid) {
        ch |= (1 << (4 - bit));
        lngMin = mid;
      } else {
        lngMax = mid;
      }
    } else {
      final mid = (latMin + latMax) / 2;
      if (lat >= mid) {
        ch |= (1 << (4 - bit));
        latMin = mid;
      } else {
        latMax = mid;
      }
    }
    evenBit = !evenBit;
    if (bit < 4) {
      bit++;
    } else {
      buffer.write(_kBase32[ch]);
      bit = 0;
      ch = 0;
    }
  }
  return buffer.toString();
}

/// Great-circle distance in metres. Same formula as the server-side
/// haversineMeters in firebase/custom_cloud_functions/visit_verification.js,
/// duplicated here rather than shared since one is Dart and one is JS.
double haversineMeters(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  double toRad(double d) => d * pi / 180.0;
  final dLat = toRad(lat2 - lat1);
  final dLng = toRad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(toRad(lat1)) * cos(toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  return 2 * r * asin(min(1.0, sqrt(a)));
}

// Approximate geohash cell width in km at each precision (1-8), the
// standard published table for this encoding. Used to pick a precision
// whose cell is roughly the size of the requested query radius - finer
// than that wastes queries on redundant neighbor cells, coarser than that
// pulls in far more area (and documents) than the viewport needs.
const _kCellWidthKm = [5000.0, 1250.0, 156.0, 39.1, 4.89, 1.22, 0.153, 0.0382];

/// Returns the geohash range prefixes (as `[prefix, prefix]` pairs meant to
/// be queried with `>= prefix` and `< prefix + '~'`, since `~` sorts after
/// every base32 character) needed to cover a bounding box.
///
/// This is the "9-neighbor" simplification of the standard geohash
/// viewport-query technique (the same idea GeoFire's `geohashQueryBounds`
/// implements more precisely with bit-level neighbor math): pick a geohash
/// precision whose cell width roughly matches the box, sample the center
/// plus the 8 surrounding points at that cell spacing, geohash-encode each,
/// and de-duplicate. Small over-fetch at cell edges is expected and
/// harmless - callers should still filter results to the exact
/// lat/lng bounds/radius they actually want, the same way
/// visit_verification.js treats geohash as a coarse pre-filter and
/// haversineMeters as the real check.
List<String> geohashPrefixesForBounds({
  required double swLat,
  required double swLng,
  required double neLat,
  required double neLng,
}) {
  final centerLat = (swLat + neLat) / 2;
  final centerLng = (swLng + neLng) / 2;
  final radiusMeters = haversineMeters(swLat, swLng, neLat, neLng) / 2;
  final radiusKm = max(radiusMeters / 1000.0, 0.1);

  var precision = _kCellWidthKm.length;
  for (var i = 0; i < _kCellWidthKm.length; i++) {
    if (_kCellWidthKm[i] <= radiusKm) {
      precision = i + 1;
      break;
    }
  }
  precision = precision.clamp(1, 8);
  final cellWidthKm = _kCellWidthKm[precision - 1];

  final deltaLat = cellWidthKm / 111.0;
  final cosLat = cos(centerLat * pi / 180.0).abs().clamp(0.01, 1.0);
  final deltaLng = cellWidthKm / (111.0 * cosLat);

  final prefixes = <String>{};
  for (final latOffset in [-1, 0, 1]) {
    for (final lngOffset in [-1, 0, 1]) {
      final lat = (centerLat + latOffset * deltaLat).clamp(-90.0, 90.0);
      final lng = centerLng + lngOffset * deltaLng;
      // Wrap longitude rather than clamp - clamping would collapse
      // antimeridian-adjacent cells onto the same edge value.
      final wrappedLng = ((lng + 180.0) % 360.0 + 360.0) % 360.0 - 180.0;
      prefixes.add(encodeGeohash(lat, wrappedLng, precision: precision));
    }
  }
  return prefixes.toList();
}
