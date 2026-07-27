import 'package:flutter_test/flutter_test.dart';
import 'package:the_k_i_n_app/services/nearby_feed.dart';

/// [selectNearby] and [distanceKm] are pure, so they're exercised here with a
/// plain fixture class - no Firestore, no widget tree, no location plugin.
class _Place {
  const _Place(this.name, this.lat, this.lng);
  final String name;
  final double? lat;
  final double? lng;
}

List<String> _names(List<_Place> places) => places.map((p) => p.name).toList();

List<_Place> _select(
  List<_Place> places, {
  required double lat,
  required double lng,
  double radiusKm = kNearbyFeedRadiusKm,
  int limit = kNearbyFeedMaxBusinesses,
}) =>
    selectNearby(
      places,
      originLat: lat,
      originLng: lng,
      latOf: (p) => p.lat,
      lngOf: (p) => p.lng,
      radiusKm: radiusKm,
      limit: limit,
    );

void main() {
  // Real coordinates from the imported directory, so the distances under test
  // are the ones the app actually deals with.
  const sanAntonioDowntown = (lat: 29.4241, lng: -98.4936);
  const austinDowntown = (lat: 30.2672, lng: -97.7431);

  group('distanceKm', () {
    test('is zero for identical points', () {
      expect(
        distanceKm(
            sanAntonioDowntown.lat, sanAntonioDowntown.lng, sanAntonioDowntown.lat, sanAntonioDowntown.lng),
        closeTo(0.0, 1e-9),
      );
    });

    test('matches the known San Antonio -> Austin distance', () {
      // ~118 km great-circle. Allow a couple of km of slack.
      final d = distanceKm(sanAntonioDowntown.lat, sanAntonioDowntown.lng,
          austinDowntown.lat, austinDowntown.lng);
      expect(d, closeTo(118.0, 3.0));
    });

    test('is symmetric', () {
      final ab = distanceKm(29.4241, -98.4936, 30.2672, -97.7431);
      final ba = distanceKm(30.2672, -97.7431, 29.4241, -98.4936);
      expect(ab, closeTo(ba, 1e-9));
    });

    test('accounts for longitude convergence rather than treating degrees as flat', () {
      // One degree of latitude is ~111 km everywhere; one degree of longitude
      // at ~29.4N is only ~97 km. A naive Euclidean-on-degrees distance would
      // report these as equal, which is the bug this guards against.
      final northSouth = distanceKm(29.4241, -98.4936, 30.4241, -98.4936);
      final eastWest = distanceKm(29.4241, -98.4936, 29.4241, -97.4936);
      expect(northSouth, closeTo(111.2, 1.0));
      expect(eastWest, closeTo(96.9, 1.5));
      expect(eastWest, lessThan(northSouth));
    });

    test('handles antipodal points without NaN from floating point drift', () {
      final d = distanceKm(0.0, 0.0, 0.0, 180.0);
      expect(d.isNaN, isFalse);
      expect(d, closeTo(20015.0, 5.0));
    });
  });

  group('selectNearby', () {
    test('keeps only businesses inside the radius', () {
      final places = [
        const _Place('downtown', 29.4241, -98.4936), // 0 km
        const _Place('austin', 30.2672, -97.7431), // ~118 km
      ];
      final result = _select(places,
          lat: sanAntonioDowntown.lat, lng: sanAntonioDowntown.lng);
      expect(_names(result), ['downtown']);
    });

    test('orders nearest first', () {
      final places = [
        const _Place('far', 29.7241, -98.4936), // ~33 km N
        const _Place('near', 29.4341, -98.4936), // ~1 km N
        const _Place('mid', 29.5241, -98.4936), // ~11 km N
      ];
      final result = _select(places,
          lat: sanAntonioDowntown.lat, lng: sanAntonioDowntown.lng);
      expect(_names(result), ['near', 'mid', 'far']);
    });

    test('drops items with a missing location instead of placing them at (0,0)', () {
      final places = [
        const _Place('no-location', null, null),
        const _Place('lat-only', 29.4241, null),
        const _Place('lng-only', null, -98.4936),
        const _Place('real', 29.4341, -98.4936),
      ];
      final result = _select(places,
          lat: sanAntonioDowntown.lat, lng: sanAntonioDowntown.lng);
      expect(_names(result), ['real']);
    });

    test('a null-location business cannot outrank a real neighbour near the equator', () {
      // The (0,0) failure mode only bites for a user near Africa's west coast;
      // this pins the behaviour there specifically.
      final places = [
        const _Place('no-location', null, null),
        const _Place('actually-close', 0.05, 0.05),
      ];
      final result = _select(places, lat: 0.0, lng: 0.0);
      expect(_names(result), ['actually-close']);
    });

    test('caps at the Firestore whereIn limit', () {
      // 40 businesses spread over ~4 km, all within the radius.
      final places = List.generate(
        40,
        (i) => _Place('b$i', 29.4241 + i * 0.001, -98.4936),
      );
      final result = _select(places,
          lat: sanAntonioDowntown.lat, lng: sanAntonioDowntown.lng);
      expect(result.length, kNearbyFeedMaxBusinesses);
      // Truncation must keep the *closest* 30, not an arbitrary 30.
      expect(_names(result).first, 'b0');
      expect(_names(result).last, 'b29');
    });

    test('never exceeds the Firestore whereIn limit for any input size', () {
      for (final n in [0, 1, 29, 30, 31, 500]) {
        final places = List.generate(
          n,
          (i) => _Place('b$i', 29.4241 + i * 0.0001, -98.4936),
        );
        final result = _select(places,
            lat: sanAntonioDowntown.lat, lng: sanAntonioDowntown.lng);
        expect(result.length, lessThanOrEqualTo(kNearbyFeedMaxBusinesses));
        expect(result.length, lessThanOrEqualTo(n));
      }
    });

    test('is stable for co-located businesses', () {
      // Several imported rows share an address (salon suites, food halls).
      // Their relative order must not churn between rebuilds.
      final places = [
        const _Place('suite-a', 29.4241, -98.4936),
        const _Place('suite-b', 29.4241, -98.4936),
        const _Place('suite-c', 29.4241, -98.4936),
      ];
      for (var i = 0; i < 5; i++) {
        final result = _select(places,
            lat: sanAntonioDowntown.lat, lng: sanAntonioDowntown.lng);
        expect(_names(result), ['suite-a', 'suite-b', 'suite-c']);
      }
    });

    test('returns empty rather than everything when nothing is in range', () {
      final places = [const _Place('austin', 30.2672, -97.7431)];
      final result = _select(places,
          lat: sanAntonioDowntown.lat, lng: sanAntonioDowntown.lng);
      expect(result, isEmpty);
    });

    test('handles an empty input list', () {
      expect(
          _select([], lat: sanAntonioDowntown.lat, lng: sanAntonioDowntown.lng),
          isEmpty);
    });

    test('treats a non-positive limit or radius as "nothing"', () {
      final places = [const _Place('downtown', 29.4241, -98.4936)];
      expect(
        _select(places,
            lat: sanAntonioDowntown.lat,
            lng: sanAntonioDowntown.lng,
            limit: 0),
        isEmpty,
      );
      expect(
        _select(places,
            lat: sanAntonioDowntown.lat,
            lng: sanAntonioDowntown.lng,
            radiusKm: 0),
        isEmpty,
      );
    });

    test('includes a business sitting exactly on the radius boundary', () {
      final places = [const _Place('edge', 29.4241, -98.4936)];
      final result = _select(places,
          lat: sanAntonioDowntown.lat,
          lng: sanAntonioDowntown.lng,
          radiusKm: 0.0001);
      expect(_names(result), ['edge']);
    });
  });
}
