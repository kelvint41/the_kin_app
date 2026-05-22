import '/components/kin_business_ownership_badges.dart';
import '/models/kin_business_profile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Compact bottom preview shown when a map pin is tapped.
/// Reads [profile.kindexScore] from the parent rebuild so scores stay live.
class KinMapProfilePreview extends StatelessWidget {
  const KinMapProfilePreview({
    super.key,
    required this.profile,
    required this.onDismiss,
  });

  final KinBusinessProfile profile;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final imageUrl = profile.primaryImageUrl;
    final kindexLabel = profile.kindexScore.toStringAsFixed(0);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: const [
            BoxShadow(
              blurRadius: 16.0,
              color: Color(0x331A3A5C),
              offset: Offset(0.0, 4.0),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14.0, 10.0, 10.0, 14.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E6ED),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              const SizedBox(height: 10.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: 56.0,
                            height: 56.0,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 56.0,
                            height: 56.0,
                            color: const Color(0xFF1A3A5C),
                            alignment: Alignment.center,
                            child: Text(
                              profile.displayName.isNotEmpty
                                  ? profile.displayName.characters.first
                                  : 'K',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20.0,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                profile.displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF1A3A5C),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            _KindexScoreBadge(scoreLabel: kindexLabel),
                          ],
                        ),
                        if (profile.category.isNotEmpty) ...[
                          const SizedBox(height: 4.0),
                          Text(
                            profile.category,
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF6B7C8F),
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                        if (profile.isBlackOwned ||
                            profile.isVeteran ||
                            profile.isBobVerified) ...[
                          const SizedBox(height: 6.0),
                          KinBusinessOwnershipBadges(
                            profile: profile,
                            compact: true,
                          ),
                        ],
                        if (profile.formattedAddress.isNotEmpty) ...[
                          const SizedBox(height: 4.0),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 13.0,
                                color: Color(0xFF6B7C8F),
                              ),
                              const SizedBox(width: 3.0),
                              Expanded(
                                child: Text(
                                  profile.formattedAddress,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF6B7C8F),
                                    fontSize: 11.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (profile.reviews.isNotEmpty) ...[
                          const SizedBox(height: 6.0),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFCC00),
                                size: 15.0,
                              ),
                              const SizedBox(width: 3.0),
                              Text(
                                profile.averageReviewRating.toStringAsFixed(1),
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF1A3A5C),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.0,
                                ),
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                '${profile.reviews.length} reviews',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF6B7C8F),
                                  fontSize: 11.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32.0,
                      minHeight: 32.0,
                    ),
                    onPressed: onDismiss,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20.0,
                      color: Color(0xFF6B7C8F),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KindexScoreBadge extends StatelessWidget {
  const _KindexScoreBadge({required this.scoreLabel});

  final String scoreLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 52.0),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A3A5C),
            Color(0xFF2E5077),
          ],
        ),
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: const [
          BoxShadow(
            blurRadius: 6.0,
            color: Color(0x331A3A5C),
            offset: Offset(0.0, 2.0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Kindex',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xCCFFFFFF),
              fontSize: 9.0,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          Text(
            scoreLabel,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
