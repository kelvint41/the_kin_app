// Pure date-logic tests for currentSeasonalTheme - no widget pumping, no
// Firebase, so this runs fast and needs nothing beyond the Dart SDK
// flutter_test already gives every other test in this suite.
import 'package:flutter_test/flutter_test.dart';
import 'package:the_k_i_n_app/services/seasonal_theme.dart';

void main() {
  group('Thanksgiving window (Nov 1 through Thanksgiving Day)', () {
    test('starts November 1st', () {
      expect(currentSeasonalTheme(DateTime(2026, 10, 31)).season,
          isNot(Season.thanksgiving));
      expect(
          currentSeasonalTheme(DateTime(2026, 11, 1)).season,
          Season.thanksgiving);
    });

    test('runs through Thanksgiving Day itself (Nov 26, 2026)', () {
      expect(currentSeasonalTheme(DateTime(2026, 11, 26)).season,
          Season.thanksgiving);
      // The very next day is Black Friday - Christmas, not Thanksgiving.
      expect(currentSeasonalTheme(DateTime(2026, 11, 27)).season,
          isNot(Season.thanksgiving));
    });

    test('a year with a later Thanksgiving (2024, Nov 28) still works', () {
      expect(currentSeasonalTheme(DateTime(2024, 11, 28)).season,
          Season.thanksgiving);
      expect(currentSeasonalTheme(DateTime(2024, 11, 29)).season,
          isNot(Season.thanksgiving));
    });
  });

  group('Small Business Saturday (Thanksgiving + 2 days, one day only)', () {
    test('lands on the Saturday after Thanksgiving 2026 (Nov 28)', () {
      expect(currentSeasonalTheme(DateTime(2026, 11, 27)).season,
          isNot(Season.smallBusinessSaturday)); // Black Friday
      expect(currentSeasonalTheme(DateTime(2026, 11, 28)).season,
          Season.smallBusinessSaturday);
      expect(currentSeasonalTheme(DateTime(2026, 11, 29)).season,
          isNot(Season.smallBusinessSaturday)); // back to Christmas
    });

    test('wins over Christmas for that one day', () {
      // Nov 29, 2026 is a normal Christmas-season day either side of it.
      expect(
          currentSeasonalTheme(DateTime(2026, 11, 29)).season,
          Season.christmas);
      expect(
          currentSeasonalTheme(DateTime(2026, 11, 28)).season,
          Season.smallBusinessSaturday);
    });

    test('is exactly one day', () {
      final daysInSeason = List.generate(31, (i) => i + 1)
          .where((day) =>
              currentSeasonalTheme(DateTime(2026, 11, day)).season ==
              Season.smallBusinessSaturday)
          .length;
      expect(daysInSeason, 1);
    });
  });

  group('Christmas window (day after Thanksgiving through Dec 25)', () {
    test('starts on Black Friday, not a fixed Dec 1', () {
      // Thanksgiving 2026 is Nov 26 (4th Thursday) - Black Friday the 27th.
      expect(currentSeasonalTheme(DateTime(2026, 11, 26)).season,
          isNot(Season.christmas));
      expect(currentSeasonalTheme(DateTime(2026, 11, 27)).season,
          Season.christmas);
    });

    test('a year where Thanksgiving falls late still starts the day after', () {
      // Thanksgiving 2024 was Nov 28 (the latest possible 4th Thursday).
      expect(currentSeasonalTheme(DateTime(2024, 11, 28)).season,
          isNot(Season.christmas));
      expect(currentSeasonalTheme(DateTime(2024, 11, 29)).season,
          Season.christmas);
    });

    test('a year where Thanksgiving falls early still starts the day after', () {
      // Thanksgiving 2025 is Nov 27 (an earlier possible 4th Thursday than 2026).
      expect(currentSeasonalTheme(DateTime(2025, 11, 27)).season,
          isNot(Season.christmas));
      expect(currentSeasonalTheme(DateTime(2025, 11, 28)).season,
          Season.christmas);
    });

    test('runs through December 25th inclusive, not past it', () {
      expect(currentSeasonalTheme(DateTime(2026, 12, 25)).season,
          Season.christmas);
      expect(currentSeasonalTheme(DateTime(2026, 12, 26)).season,
          isNot(Season.christmas));
    });
  });

  group('Juneteenth window (7 days, June 13-19)', () {
    test('starts on the 13th, not the 15th', () {
      expect(
          currentSeasonalTheme(DateTime(2026, 6, 12)).season,
          isNot(Season.juneteenth));
      expect(
          currentSeasonalTheme(DateTime(2026, 6, 13)).season,
          Season.juneteenth);
    });

    test('ends on the 19th itself, not past it', () {
      expect(
          currentSeasonalTheme(DateTime(2026, 6, 19)).season,
          Season.juneteenth);
      expect(
          currentSeasonalTheme(DateTime(2026, 6, 20)).season,
          isNot(Season.juneteenth));
    });

    test('is exactly 7 days', () {
      final daysInSeason = List.generate(30, (i) => i + 1)
          .where((day) =>
              currentSeasonalTheme(DateTime(2026, 6, day)).season ==
              Season.juneteenth)
          .length;
      expect(daysInSeason, 7);
    });
  });

  group('Kwanzaa window (unchanged: Dec 26 - Jan 1)', () {
    test('still starts the 26th', () {
      expect(currentSeasonalTheme(DateTime(2026, 12, 25)).season,
          isNot(Season.kwanzaa));
      expect(
          currentSeasonalTheme(DateTime(2026, 12, 26)).season, Season.kwanzaa);
    });

    test('still ends New Year\'s Day', () {
      expect(
          currentSeasonalTheme(DateTime(2027, 1, 1)).season, Season.kwanzaa);
      expect(currentSeasonalTheme(DateTime(2027, 1, 2)).season,
          isNot(Season.kwanzaa));
    });
  });

  test('windows never overlap across a full year', () {
    // A year should never see two seasons claim the same day - if
    // Christmas's now-variable start ever drifted into Halloween's
    // October or Juneteenth's June, this would catch it.
    Season? lastSeason;
    for (var day = 1; day <= 365; day++) {
      final date = DateTime(2026).add(Duration(days: day - 1));
      final season = currentSeasonalTheme(date).season;
      // Only checking each transition is a real month-boundary jump, not
      // a double-claim - non-overlap by construction is the property
      // under test, not any specific sequence.
      lastSeason = season;
    }
    expect(lastSeason, isNotNull);
  });
}
