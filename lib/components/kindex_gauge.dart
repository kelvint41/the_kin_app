import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '/flutter_flow/flutter_flow_theme.dart';

/// A circular gauge for a Kindex score.
///
/// Replaces a LinearPercentIndicator whose `percent` was the literal 0.85 -
/// it drew the same 85% bar for every business regardless of its score, so
/// it was a picture of a progress bar rather than one. Its colour was
/// `primaryText`, which meant it also went near-black the moment light mode
/// stopped painting text gold.
///
/// A ring rather than a bar because this is the number the whole app is
/// built around and it was rendering as an 8px line: a ring gives the score
/// somewhere to sit, reads at a glance, and does not disappear into a card.
///
/// The arc is the brand gold on both themes - it sits on a card, not on
/// text, so a token that inverts between modes would be the wrong choice
/// here for the same reason it was wrong on the Power Hour buttons.
class KindexGauge extends StatelessWidget {
  const KindexGauge({
    super.key,
    required this.score,
    required this.maxScore,
    this.label,
  });

  final double score;

  /// Tier-dependent: business_kindex_nightly.js clamps to 750 for standard
  /// businesses and 900 for premium ones. Passed in rather than assumed,
  /// because a premium business can hold a score a standard maximum would
  /// show as over-full.
  final int maxScore;

  /// Optional caption under the ring. Null where the section already has a
  /// heading, which would otherwise repeat the same three words twice within
  /// an inch of each other.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    const gold = Color(0xFFD4AF37);

    // Clamped so a score above its own ceiling - which happens when a
    // business is downgraded and keeps the score it earned - draws a full
    // ring instead of overflowing it.
    final fraction =
        maxScore <= 0 ? 0.0 : (score / maxScore).clamp(0.0, 1.0).toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularPercentIndicator(
          percent: fraction,
          radius: 84.0,
          lineWidth: 14.0,
          animation: true,
          animateFromLastPercent: true,
          animationDuration: 900,
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: gold,
          // The unfilled remainder, not a second accent: a low-contrast
          // track so the gold arc is the only thing the eye lands on.
          backgroundColor: theme.alternate,
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.round().toString(),
                style: theme.displaySmall.override(
                  font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  color: theme.primaryText,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'of $maxScore',
                style: theme.labelSmall.override(
                  font: GoogleFonts.plusJakartaSans(),
                  color: theme.secondaryText,
                  letterSpacing: 0.0,
                ),
              ),
            ],
          ),
        ),
        if (label != null)
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0, 14, 0, 0),
          child: Text(
            label!,
            style: theme.labelMedium.override(
              font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              color: theme.accentOnSurface,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
