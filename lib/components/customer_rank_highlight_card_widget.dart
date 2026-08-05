import '/components/kindex_tier_badge_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/services/kin_services.dart';
import '/services/kindex_tiers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A ranked customer row in the KINDEX leaderboard's full list. Customers
/// have no photo anywhere in the app (unlike businesses, which get
/// BusinessRankHighlightCardWidget's full-bleed treatment), so this keeps
/// the row shape of the old RankCardWidget but with a bigger, tier-colored
/// initials avatar and the shared KindexTierBadge in place of the old plain
/// gold score pill.
///
/// This also fixes a real bug in RankCardWidget, where the avatar circle
/// rendered the customer's full name as text instead of a single initial -
/// this widget only ever reads `entry.name[0]`.
class CustomerRankHighlightCardWidget extends StatelessWidget {
  const CustomerRankHighlightCardWidget({
    super.key,
    required this.rank,
    required this.entry,
  });

  /// 1-indexed leaderboard position.
  final int rank;

  /// entry.businessRef must be null - business entries render via
  /// BusinessRankHighlightCardWidget instead.
  final KindexTickerEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final initial =
        entry.name.trim().isNotEmpty ? entry.name.trim()[0].toUpperCase() : '?';
    final ringColor = kindexTierForScore(entry.score)?.color ?? Color(0xFFFFD700);

    return Container(
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: theme.alternate, width: 1.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 24.0,
              child: Text(
                '$rank',
                style: theme.titleMedium.override(
                  font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  color: theme.secondaryText,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              width: 56.0,
              height: 56.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.secondaryBackground,
                border: Border.all(color: ringColor, width: 2.0),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: theme.titleMedium.override(
                  font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  color: theme.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 12.0),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodyLarge.override(
                      font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                      color: theme.primaryText,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Community Member',
                    style: theme.labelSmall.override(
                      font: GoogleFonts.plusJakartaSans(),
                      color: theme.secondaryText,
                      letterSpacing: 0.0,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.0),
            KindexTierBadge(
              score: entry.score,
              isTrendingUp: entry.isTrendingUp,
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
}
