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

/// The active season for [now] (defaults to the current moment).
///
/// Pass an explicit [now] in tests; the app itself always omits it.
/// Windows are non-overlapping by construction, so order only matters for
/// readability, not correctness.
SeasonalTheme currentSeasonalTheme([DateTime? now]) {
  final n = now ?? DateTime.now();

  if (n.month == 2) return _blackHistoryMonth;
  if (n.month == 6 && n.day >= 15 && n.day <= 19) return _juneteenth;
  if (n.month == 10) return _halloween;
  if (n.month == 12 && n.day <= 25) return _christmas;
  if ((n.month == 12 && n.day >= 26) || (n.month == 1 && n.day == 1)) {
    return _kwanzaa;
  }
  return _standard;
}
