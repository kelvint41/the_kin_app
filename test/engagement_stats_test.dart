import 'package:flutter_test/flutter_test.dart';
import 'package:the_k_i_n_app/services/engagement_stats.dart';

void main() {
  group('supportStreakDays', () {
    final now = DateTime(2026, 7, 27, 14, 30);

    DateTime daysAgo(int days, {int hour = 12}) =>
        DateTime(2026, 7, 27 - days, hour);

    test('returns 0 with no activity', () {
      expect(supportStreakDays([], now: now), 0);
    });

    test('counts today alone as a 1-day streak', () {
      expect(supportStreakDays([daysAgo(0)], now: now), 1);
    });

    test('counts consecutive days ending today', () {
      final times = [daysAgo(0), daysAgo(1), daysAgo(2)];
      expect(supportStreakDays(times, now: now), 3);
    });

    test('collapses several actions on the same day into one', () {
      final times = [
        daysAgo(0, hour: 8),
        daysAgo(0, hour: 13),
        daysAgo(0, hour: 21),
        daysAgo(1),
      ];
      expect(supportStreakDays(times, now: now), 2);
    });

    test('keeps the streak alive when today has no activity yet', () {
      final times = [daysAgo(1), daysAgo(2)];
      expect(supportStreakDays(times, now: now), 2);
    });

    test('breaks the streak once a full day is missed', () {
      final times = [daysAgo(2), daysAgo(3)];
      expect(supportStreakDays(times, now: now), 0);
    });

    test('stops at the first gap rather than counting all active days', () {
      final times = [daysAgo(0), daysAgo(1), daysAgo(5), daysAgo(6)];
      expect(supportStreakDays(times, now: now), 2);
    });

    test('is order independent', () {
      final times = [daysAgo(2), daysAgo(0), daysAgo(1)];
      expect(supportStreakDays(times, now: now), 3);
    });
  });

  group('reviewMilestoneLabel', () {
    test('uses the singular at one', () {
      expect(reviewMilestoneLabel(1), '1 Review');
    });

    test('uses the plural at zero and above one', () {
      expect(reviewMilestoneLabel(0), '0 Reviews');
      expect(reviewMilestoneLabel(5), '5 Reviews');
    });
  });

  group('countdownLabel', () {
    final now = DateTime(2026, 7, 27, 12, 0);

    test('returns null when there is no expiry', () {
      expect(countdownLabel(null, now: now), isNull);
    });

    test('returns null for an offer that already lapsed', () {
      expect(
          countdownLabel(now.subtract(Duration(minutes: 1)), now: now), isNull);
      expect(countdownLabel(now, now: now), isNull);
    });

    test('formats hours and minutes', () {
      final expires = now.add(Duration(hours: 2, minutes: 14));
      expect(countdownLabel(expires, now: now), '2h 14m');
    });

    test('formats days and hours past 24 hours', () {
      final expires = now.add(Duration(days: 1, hours: 3, minutes: 30));
      expect(countdownLabel(expires, now: now), '1d 3h');
    });

    test('formats a sub-hour window', () {
      expect(
          countdownLabel(now.add(Duration(minutes: 42)), now: now), '0h 42m');
    });
  });

  group('businessInitials', () {
    test('takes the first letter of the first two words', () {
      expect(businessInitials('Estate Coffee Co.'), 'EC');
      expect(businessInitials('Pearl Brewery'), 'PB');
    });

    test('takes two characters from a single-word name', () {
      expect(businessInitials('Hopscotch'), 'HO');
    });

    test('handles a one-character name and empty input', () {
      expect(businessInitials('X'), 'X');
      expect(businessInitials('   '), '?');
    });

    test('collapses irregular spacing', () {
      expect(businessInitials('  The   Iron Cactus '), 'TI');
    });
  });

  group('impactScoreLabel', () {
    test('shows a placeholder when the user has no score yet', () {
      expect(impactScoreLabel(null), '--');
    });

    test('rounds the score to a whole number', () {
      expect(impactScoreLabel(512.4), '512');
      expect(impactScoreLabel(512.6), '513');
    });
  });
}
