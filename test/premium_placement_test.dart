import 'package:flutter_test/flutter_test.dart';
import 'package:the_k_i_n_app/services/premium_placement.dart';

/// [selectPremiumRotation] is generic and pure, so it is exercised here
/// with plain strings - no Firestore, no widget tree.
void main() {
  DateTime windowStart(int index) => DateTime.fromMillisecondsSinceEpoch(
        index * kPremiumRotationWindow.inMilliseconds,
        isUtc: true,
      );

  List<String> ids(int n) =>
      List.generate(n, (i) => 'b${i.toString().padLeft(2, '0')}');

  group('premiumRotationWindowIndex', () {
    test('advances once per window and is timezone-independent', () {
      final t = windowStart(1234);
      expect(premiumRotationWindowIndex(t), 1234);
      expect(
        premiumRotationWindowIndex(
            t.add(kPremiumRotationWindow - const Duration(milliseconds: 1))),
        1234,
      );
      expect(premiumRotationWindowIndex(t.add(kPremiumRotationWindow)), 1235);
      // Same instant expressed in local time must land in the same window.
      expect(premiumRotationWindowIndex(t.toLocal()), 1234);
    });
  });

  group('selectPremiumRotation', () {
    test('returns everything when there is nothing to rotate', () {
      for (final n in [0, 1, 2, 3]) {
        expect(
          selectPremiumRotation(ids(n), now: windowStart(7)),
          ids(n),
          reason: '$n eligible should all be shown',
        );
      }
    });

    test('is stable within a window and changes across windows', () {
      final pool = ids(9);
      final a = selectPremiumRotation(pool, now: windowStart(0));
      final b = selectPremiumRotation(
        pool,
        now: windowStart(0).add(kPremiumRotationWindow ~/ 2),
      );
      final c = selectPremiumRotation(pool, now: windowStart(1));

      expect(a, b, reason: 'same window must show the same three');
      expect(a, isNot(c));
      expect(a, hasLength(kPremiumCarouselSlots));
    });

    test('every eligible business appears within a full cycle', () {
      // Covers pools that do and do not divide evenly by the slot count.
      for (final n in [4, 5, 6, 7, 8, 9, 10, 17]) {
        final pool = ids(n);
        final cycleWindows = (n / kPremiumCarouselSlots).ceil();
        final seen = <String>{};
        for (var w = 0; w < cycleWindows; w++) {
          seen.addAll(selectPremiumRotation(pool, now: windowStart(w)));
        }
        expect(
          seen,
          pool.toSet(),
          reason: '$n paid businesses should all be shown within '
              '$cycleWindows windows',
        );
      }
    });

    test('never repeats a business inside one window', () {
      final pool = ids(4);
      for (var w = 0; w < 8; w++) {
        final shown = selectPremiumRotation(pool, now: windowStart(w));
        expect(shown.toSet(), hasLength(shown.length));
      }
    });
  });
}
