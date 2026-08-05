import '/flutter_flow/flutter_flow_theme.dart';
import '/services/kindex_tiers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A KINDEX score pill: trend arrow, score, and (above the 300 baseline) a
/// tier label - the shared visual language for any score-bearing surface
/// (Exchange feed posts, the leaderboard's highlight cards and podium).
///
/// Extracted from what was a private `_KindexScoreBadge` inside
/// exchange_feed_item_widget.dart, which owned both the badge's visuals and
/// its own live `KindexScoresRecord` stream. Streaming only makes sense
/// where the caller doesn't already have a score in hand - the leaderboard
/// widgets fetch `KindexTickerEntry.score` once per load and would gain
/// nothing from a second live subscription per card - so this widget takes
/// `score`/`isTrendingUp` as plain values and leaves any streaming to the
/// caller, same as before for the feed (still done there, just one level
/// up).
class KindexTierBadge extends StatelessWidget {
  const KindexTierBadge({
    super.key,
    required this.score,
    required this.isTrendingUp,
    this.dense = true,
  });

  final double score;
  final bool isTrendingUp;

  /// true reproduces the original compact feed-pill sizing exactly (no
  /// visual regression for exchange_feed_item_widget.dart); false scales
  /// everything up for the leaderboard's larger highlight cards.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    // Tier drives the badge's color and, above the 300 baseline, an
    // appended label - null at baseline keeps the original plain-gold
    // look rather than badging every brand-new account.
    final tier = kindexTierForScore(score);
    final accentColor = tier?.color ?? Color(0xFFFFD700);
    final fontSize = dense ? 11.0 : 13.0;
    final iconSize = dense ? 10.0 : 14.0;
    final horizontalPadding = dense ? 6.0 : 9.0;
    final verticalPadding = dense ? 2.0 : 4.0;
    final labelMaxWidth = dense ? 84.0 : 110.0;

    return Container(
      decoration: BoxDecoration(
        color: accentColor.withAlpha(0x1A),
        borderRadius: BorderRadius.circular(theme.designToken.radius.full),
        border: Border.all(color: accentColor.withAlpha(0x4D), width: 1.0),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
            horizontalPadding, verticalPadding, horizontalPadding, verticalPadding),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isTrendingUp
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: isTrendingUp ? Color(0xFF10B981) : Color(0xFFEF4444),
              size: iconSize,
            ),
            Text(
              score.toStringAsFixed(0),
              style: theme.labelSmall.override(
                font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                color: accentColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.0,
                fontSize: fontSize,
              ),
            ),
            // Bounded and ellipsized rather than left to grow freely - this
            // badge sits in a Row next to other flexible content that can
            // already shrink to fit; an unbounded tier label here could
            // still overflow on a narrow phone with a long display name, so
            // it truncates instead.
            if (tier != null) ...[
              Text(
                ' · ',
                style: theme.labelSmall.override(
                  color: accentColor.withAlpha(0xAA),
                  fontSize: fontSize,
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: labelMaxWidth),
                child: Text(
                  tier.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.labelSmall.override(
                    font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.0,
                    fontSize: fontSize,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
