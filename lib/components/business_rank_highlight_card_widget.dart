import '/components/business_image_widget.dart';
import '/components/kindex_tier_badge_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/business_profile_v2/business_profile_v2_widget.dart';
import '/services/kin_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A ranked business row in the KINDEX leaderboard's full list, styled as a
/// full-bleed photo card - reuses the visual language built for Marketplace
/// item cards (see marketplace_item_card_widget.dart) rather than the old
/// plain-text RankCardWidget rows, so a business's own photo carries the
/// card instead of a caption underneath a small thumbnail.
class BusinessRankHighlightCardWidget extends StatelessWidget {
  const BusinessRankHighlightCardWidget({
    super.key,
    required this.rank,
    required this.entry,
  });

  /// 1-indexed leaderboard position.
  final int rank;

  /// entry.businessRef must be non-null - customer entries render via
  /// CustomerRankHighlightCardWidget instead.
  final KindexTickerEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.pushNamed(
        BusinessProfileV2Widget.routeName,
        queryParameters: {
          'businessDocument':
              serializeParam(entry.businessRef, ParamType.DocumentReference),
        }.withoutNulls,
      ),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16.0)),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: 0.72,
          child: Stack(
            fit: StackFit.expand,
            children: [
              BusinessImage(
                imageUrl: entry.heroImage,
                fit: BoxFit.cover,
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.5, 1.0],
                      colors: [Colors.transparent, Color(0xCC000000)],
                    ),
                  ),
                ),
              ),
              // #1 gets the same gold accent business_preview_card_widget.dart
              // already uses for priority-pinned businesses, rather than a
              // new gold - #2/#3 stay a plain dark pill.
              Positioned(
                top: 8.0,
                left: 8.0,
                child: Container(
                  width: 28.0,
                  height: 28.0,
                  decoration: BoxDecoration(
                    color: rank == 1 ? theme.tertiary : Color(0x99000000),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '#$rank',
                    style: theme.labelSmall.override(
                      font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.0,
                      letterSpacing: 0.0,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8.0,
                right: 8.0,
                child: KindexTierBadge(
                  score: entry.score,
                  isTrendingUp: entry.isTrendingUp,
                  dense: false,
                ),
              ),
              Positioned(
                left: 10.0,
                right: 10.0,
                bottom: 10.0,
                child: Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyMedium.override(
                    font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
