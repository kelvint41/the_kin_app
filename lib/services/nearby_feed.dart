// Selection logic for the "Nearby" Exchange feed shown on the Feed tab.
//
// Background: The Exchange stores one wall per business - `exchange_posts`
// rows carry a `business_ref`, and the per-business page queries
// `where business_ref == <that business>`. There is no global feed document.
// The Feed tab used to paper over this by opening whichever business
// Firestore happened to return first (`queryBusinessesRecordOnce(limit: 1)`),
// so every user landed on an arbitrary business's wall.
//
// This picks the businesses closest to the user instead, and the Nearby Feed
// page then fans out a single `where business_ref whereIn [...]` query across
// them. That keeps the existing one-wall-per-business data model completely
// unchanged - it just reads several walls at once.
//
// Everything here is pure: no Firestore, no widgets, no plugins. The page
// adapts `BusinessesRecord` into the callbacks below.

import 'dart:math' as math;

/// How far out "nearby" reaches, in kilometres (~25 miles).
///
/// Wide enough that a user in a metro area sees more than their own block,
/// narrow enough that "nearby" stays honest - the directory spans all of
/// Texas, so an unbounded radius would just be a random national feed again.
const double kNearbyFeedRadiusKm = 40.0;

/// Hard cap on how many businesses a single feed query may span.
///
/// This is a Firestore limit, not a product choice: `whereIn` accepts at most
/// 30 values, and the Nearby Feed issues one `business_ref whereIn [...]`
/// query. Exceeding it would throw at runtime, so [selectNearby] truncates to
/// the closest 30.
const int kNearbyFeedMaxBusinesses = 30;

/// Mean Earth radius in kilometres, used by [distanceKm].
const double _earthRadiusKm = 6371.0088;

double _toRadians(double degrees) => degrees * math.pi / 180.0;

/// Great-circle distance in kilometres between two lat/lng pairs (haversine).
///
/// Accurate to well under a percent at the scales this feed cares about, and
/// unlike a naive Euclidean distance on raw degrees it stays correct as
/// longitude lines converge - at Texas latitudes a degree of longitude is
/// about 15% shorter than a degree of latitude, which would otherwise skew
/// every "nearby" result east-west.
double distanceKm(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  final dLat = _toRadians(lat2 - lat1);
  final dLng = _toRadians(lng2 - lng1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_toRadians(lat1)) *
          math.cos(_toRadians(lat2)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * _earthRadiusKm * math.asin(math.min(1.0, math.sqrt(a)));
}

/// Returns the items within [radiusKm] of the origin, nearest first, capped at
/// [limit].
///
/// Items whose coordinates are null are dropped rather than treated as
/// (0, 0) - a business with no `business_location` would otherwise appear to
/// sit off the coast of Africa and could outrank real neighbours for a user
/// near the equator.
///
/// Generic over [T] so it can be unit-tested with plain objects; the page
/// passes `BusinessesRecord` and reads `businessLocation`.
List<T> selectNearby<T>(
  List<T> items, {
  required double originLat,
  required double originLng,
  required double? Function(T item) latOf,
  required double? Function(T item) lngOf,
  double radiusKm = kNearbyFeedRadiusKm,
  int limit = kNearbyFeedMaxBusinesses,
}) {
  if (limit <= 0 || radiusKm <= 0) return <T>[];

  final withDistance = <({T item, double distance})>[];
  for (final item in items) {
    final lat = latOf(item);
    final lng = lngOf(item);
    if (lat == null || lng == null) continue;
    final d = distanceKm(originLat, originLng, lat, lng);
    if (d <= radiusKm) {
      withDistance.add((item: item, distance: d));
    }
  }

  // Stable ordering: equal distances keep their original relative order, so
  // the feed doesn't reshuffle between rebuilds for co-located businesses
  // (several of the imported rows share an address, e.g. salon suites).
  mergeSortByDistance(withDistance);

  final capped = withDistance.length > limit
      ? withDistance.sublist(0, limit)
      : withDistance;
  return capped.map((e) => e.item).toList();
}

/// In-place stable sort by ascending distance.
///
/// Dart's [List.sort] is *not* guaranteed stable, and co-located businesses
/// are common in this data, so this uses an explicit merge sort to keep the
/// feed's ordering deterministic.
void mergeSortByDistance<T>(List<({T item, double distance})> list) {
  if (list.length < 2) return;
  final mid = list.length ~/ 2;
  final left = list.sublist(0, mid);
  final right = list.sublist(mid);
  mergeSortByDistance(left);
  mergeSortByDistance(right);

  var i = 0, j = 0, k = 0;
  while (i < left.length && j < right.length) {
    // `<=` keeps left (earlier) elements first on ties - that's what makes
    // this stable.
    list[k++] = left[i].distance <= right[j].distance ? left[i++] : right[j++];
  }
  while (i < left.length) {
    list[k++] = left[i++];
  }
  while (j < right.length) {
    list[k++] = right[j++];
  }
}
