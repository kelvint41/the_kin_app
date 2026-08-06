// Dynamic seasonal theming for the Scavenger Hunt page and the map.
//
// Pure and date-driven - no state, no provider, no rebuild trigger of its
// own. Each widget that wants seasonal styling calls
// currentSeasonalTheme() directly in build(); Flutter already rebuilds on
// the next frame/navigation, and a theme that could change mid-session
// (crossing midnight into a new season) isn't worth a stream listener for
// how rarely that matters here.
import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_google_map.dart' show GoogleMapStyle;

enum Season {
  standard,
  blackHistoryMonth,
  juneteenth,
  halloween,
  thanksgiving,
  smallBusinessSaturday,
  kwanzaa,
  christmas,
}

class SeasonalTheme {
  const SeasonalTheme({
    required this.season,
    required this.label,
    required this.accent,
    this.mapStyle = GoogleMapStyle.standard,
    this.rareMarkerEmoji,
  });

  final Season season;

  /// Shown nowhere in the UI yet - kept for logging/debugging and any
  /// future "You're seeing X theme" banner.
  final String label;

  /// The one accent colour this season replaces the brand gold with,
  /// everywhere the Scavenger Hunt page currently hardcodes gold (header
  /// gradient, rare-card glow/border, badge fills).
  final Color accent;

  /// Which of the app's existing Google Map style presets
  /// (flutter_flow_google_map.dart) this season uses. No new map JSON is
  /// authored here - only real, already-shipped presets.
  final GoogleMapStyle mapStyle;

  /// Overrides the Rare/Hidden Gem marker glyph with an emoji instead of
  /// the default diamond/star Material icon. Null means "keep the
  /// default" - this is deliberately Halloween-only (see the doc comment
  /// on _halloween below for why the other observances don't get a
  /// novelty marker).
  final String? rareMarkerEmoji;
}

const _standard = SeasonalTheme(
  season: Season.standard,
  label: 'Standard',
  accent: Color(0xFFD4AF37), // brand gold, unchanged
);

// Pan-African flag colours (red/black/green), paired with the app's
// existing forest green rather than introducing a new dark neutral.
const _blackHistoryMonth = SeasonalTheme(
  season: Season.blackHistoryMonth,
  label: 'Black History Month',
  accent: Color(0xFFCE1126),
);

const _juneteenth = SeasonalTheme(
  season: Season.juneteenth,
  label: 'Juneteenth',
  accent: Color(0xFFCE1126),
);

const _kwanzaa = SeasonalTheme(
  season: Season.kwanzaa,
  label: 'Kwanzaa',
  accent: Color(0xFF149954),
);

// The only season with a novelty marker: "rare find" is already a
// treasure-hunt gimmick, and a ghost/pumpkin fits it the way it wouldn't
// fit a cultural or religious observance. Also the only season that swaps
// the map style - GoogleMapStyle.night's darker palette matches the mood
// without needing a bespoke JSON style.
const _halloween = SeasonalTheme(
  season: Season.halloween,
  label: 'Halloween',
  accent: Color(0xFFFF7A1A),
  mapStyle: GoogleMapStyle.night,
  rareMarkerEmoji: '🎃',
);

const _christmas = SeasonalTheme(
  season: Season.christmas,
  label: 'Christmas',
  accent: Color(0xFFC41E3A),
  mapStyle: GoogleMapStyle.silver,
);

// Deliberately no rareMarkerEmoji, same reasoning as Christmas/Kwanzaa/
// Juneteenth/Black History Month above - this is a real holiday people
// gather and cater for (a big season for Black-owned catering businesses
// specifically), not a treasure-hunt gimmick. A harvest amber distinct
// from both Halloween's brighter orange and Christmas's red.
const _thanksgiving = SeasonalTheme(
  season: Season.thanksgiving,
  label: 'Thanksgiving',
  accent: Color(0xFFB5651D),
);

// One day only, carved out of the Christmas window it would otherwise
// fall inside (the Saturday right after Thanksgiving/Black Friday) - the
// real, nationally-recognized "Shop Small" day, and arguably the single
// most on-mission day of the year for an app built around a Black-owned
// small business directory. Purple/plum matches the real Small Business
// Saturday campaign's own established branding, not a color picked fresh
// here.
const _smallBusinessSaturday = SeasonalTheme(
  season: Season.smallBusinessSaturday,
  label: 'Small Business Saturday',
  accent: Color(0xFF7A4FA0),
);

/// The 4th Thursday of November for [year] - Thanksgiving's date moves
/// every year, so this walks the month rather than hardcoding a
/// day-of-month the way every other window here can.
DateTime _thanksgivingDate(int year) {
  var seen = 0;
  for (var day = 1; day <= 30; day++) {
    final d = DateTime(year, 11, day);
    if (d.weekday == DateTime.thursday) {
      seen += 1;
      if (seen == 4) return d;
    }
  }
  throw StateError('November always has a 4th Thursday');
}

/// The active season for [now] (defaults to the current moment).
///
/// Pass an explicit [now] in tests; the app itself always omits it.
/// Windows are non-overlapping by construction, so order only matters for
/// readability, not correctness.
SeasonalTheme currentSeasonalTheme([DateTime? now]) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);

  if (n.month == 2) return _blackHistoryMonth;
  // 7 days (was 5) - June 13 through the 19th itself, not past it. Unlike
  // Christmas below, this doesn't lead into a separate retail season
  // afterward, so there's nothing to extend the window toward.
  if (n.month == 6 && n.day >= 13 && n.day <= 19) return _juneteenth;
  if (n.month == 10) return _halloween;

  // Thanksgiving season: all of November up through Thanksgiving Day
  // itself, then Christmas picks up immediately the next day (Black
  // Friday) below - the two windows share a single boundary rather than
  // each computing it independently, so they can never drift apart or
  // leave a gap/overlap between them.
  final thanksgivingDay = _thanksgivingDate(n.year);
  final novemberStart = DateTime(n.year, 11, 1);
  if (!today.isBefore(novemberStart) && !today.isAfter(thanksgivingDay)) {
    return _thanksgiving;
  }

  // Small Business Saturday: Thanksgiving + 2 days (the day after Black
  // Friday). Checked before Christmas below specifically because it falls
  // inside that window and needs to win for its one day, not get absorbed
  // by it.
  final smallBusinessSaturday = thanksgivingDay.add(const Duration(days: 2));
  if (today.isAtSameMomentAs(smallBusinessSaturday)) {
    return _smallBusinessSaturday;
  }

  // Starts the day after Thanksgiving (Black Friday - the actual start of
  // the retail Christmas season, not a fixed December 1st) through
  // December 25th.
  final christmasStart = thanksgivingDay.add(const Duration(days: 1));
  final christmasEnd = DateTime(n.year, 12, 25);
  if (!today.isBefore(christmasStart) && !today.isAfter(christmasEnd)) {
    return _christmas;
  }

  if ((n.month == 12 && n.day >= 26) || (n.month == 1 && n.day == 1)) {
    return _kwanzaa;
  }
  return _standard;
}
