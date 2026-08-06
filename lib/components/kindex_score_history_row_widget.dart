import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// One day's row on the KINDEX score-history screen. Shared by the
/// business-owner and customer variants (KindexScoreHistoryWidget) - the
/// two sides write different "why" fields onto the same
/// kindex_score_history row (see kindex_score_history_record.dart), so
/// this reads entry.entityType to decide which ones to surface rather than
/// the caller passing a mode flag.
class KindexScoreHistoryRow extends StatelessWidget {
  const KindexScoreHistoryRow({super.key, required this.entry});

  final KindexScoreHistoryRecord entry;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final delta = entry.scoreAfter - entry.scoreBefore;
    final up = delta > 0;
    final down = delta < 0;
    // Brand green/red rather than theme.success/error - this sits on a
    // card in both light and dark mode and needs to read the same way
    // KindexTrendIndicator's arrows do elsewhere in the app, not shift
    // with the theme token.
    final deltaColor = up
        ? const Color(0xFF2ECC71)
        : down
            ? const Color(0xFFE74C3C)
            : theme.secondaryText;
    final deltaLabel = up
        ? '+${delta.round()}'
        : down
            ? '${delta.round()}'
            : '±0';

    return Container(
      padding: EdgeInsets.all(16.0),
      margin: EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: theme.alternate, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateTimeFormat('MMM d, y', entry.recordedAt),
                  style: theme.bodyMedium.override(
                    font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600),
                    color: theme.primaryText,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  _reasonLine(entry),
                  style: theme.bodySmall.override(
                    color: theme.secondaryText,
                    letterSpacing: 0.0,
                    lineHeight: 1.35,
                  ),
                ),
                if (entry.capped) ...[
                  SizedBox(height: 2.0),
                  Text(
                    'Capped at tier maximum',
                    style: theme.bodySmall.override(
                      color: theme.secondaryText,
                      letterSpacing: 0.0,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 12.0),
          Container(
            padding:
                EdgeInsetsDirectional.fromSTEB(10.0, 4.0, 10.0, 4.0),
            decoration: BoxDecoration(
              color: deltaColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              deltaLabel,
              style: theme.bodyMedium.override(
                font:
                    GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                color: deltaColor,
                letterSpacing: 0.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Turns whichever "why" fields are non-zero on this row into a single
  /// human-readable line. Decay wins over gains when both are present on
  /// the same row (shouldn't normally co-occur - a row either has activity
  /// or is decaying, see applyNightlyMovement in
  /// kindex_scoring_dynamics.js - but decay is the more important thing to
  /// surface if it ever does).
  String _reasonLine(KindexScoreHistoryRecord entry) {
    if (entry.decayApplied > 0) {
      final weeks = entry.inactivityWeeks;
      return '${entry.decayApplied.round()} pts decayed · '
          '$weeks week${weeks == 1 ? '' : 's'} inactive';
    }

    if (entry.entityType == 'business') {
      final parts = <String>[];
      if (entry.verifiedVisitCount > 0) {
        parts.add('${entry.verifiedVisitCount} verified visit'
            '${entry.verifiedVisitCount == 1 ? '' : 's'}');
      }
      if (entry.qualifyingReviewCount > 0) {
        parts.add('${entry.qualifyingReviewCount} review'
            '${entry.qualifyingReviewCount == 1 ? '' : 's'}');
      }
      if (entry.activePosterBonusApplied) {
        parts.add('+${entry.activePosterBonusPoints.round()} active-poster '
            'bonus (${entry.activePosterDays}d posting streak)');
      }
      return parts.isEmpty ? 'No qualifying activity' : parts.join(' · ');
    }

    // Customer rows.
    if (entry.qualifyingEventCount > 0) {
      final businesses = entry.distinctBusinessesEngaged;
      return '${entry.qualifyingEventCount} engagement event'
          '${entry.qualifyingEventCount == 1 ? '' : 's'} across '
          '$businesses business${businesses == 1 ? '' : 'es'}';
    }
    return 'No qualifying activity';
  }
}
