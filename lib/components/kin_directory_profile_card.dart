import '/models/kin_business_profile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KinDirectoryProfileCard extends StatelessWidget {
  const KinDirectoryProfileCard({
    super.key,
    required this.profile,
  });

  final KinBusinessProfile profile;

  @override
  Widget build(BuildContext context) {
    final imageUrl = profile.primaryImageUrl;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            blurRadius: 10.0,
            color: Color(0x1A1A3A5C),
            offset: Offset(0.0, 3.0),
          ),
        ],
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 72.0,
                          height: 72.0,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 72.0,
                          height: 72.0,
                          color: const Color(0xFF1A3A5C),
                          alignment: Alignment.center,
                          child: Text(
                            profile.displayName.isNotEmpty
                                ? profile.displayName.characters.first
                                : 'K',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24.0,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              profile.displayName,
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF1A3A5C),
                                fontWeight: FontWeight.bold,
                                fontSize: 17.0,
                              ),
                            ),
                          ),
                          if ((profile.tickerSymbol ?? '').isNotEmpty)
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F4F8),
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                                vertical: 2.0,
                              ),
                              child: Text(
                                profile.tickerSymbol!,
                                style: GoogleFonts.playfairDisplay(
                                  color: const Color(0xFF1A3A5C),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.0,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (profile.category.isNotEmpty) ...[
                        const SizedBox(height: 4.0),
                        Text(
                          profile.category,
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF6B7C8F),
                            fontSize: 13.0,
                          ),
                        ),
                      ],
                      if (profile.formattedAddress.isNotEmpty) ...[
                        const SizedBox(height: 6.0),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14.0,
                              color: Color(0xFF6B7C8F),
                            ),
                            const SizedBox(width: 4.0),
                            Expanded(
                              child: Text(
                                profile.formattedAddress,
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF6B7C8F),
                                  fontSize: 12.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kindex Score',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF6B7C8F),
                        fontSize: 11.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      profile.kindexScore.toStringAsFixed(0),
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF1A3A5C),
                        fontSize: 28.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (profile.reviews.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFCC00),
                            size: 16.0,
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            profile.averageReviewRating.toStringAsFixed(1),
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF1A3A5C),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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
            ),
            if (profile.isBlackOwned || profile.isBobVerified) ...[
              const SizedBox(height: 10.0),
              Wrap(
                spacing: 8.0,
                children: [
                  if (profile.isBlackOwned)
                    _badge('Black-owned', const Color(0xFF1A3A5C)),
                  if (profile.isBobVerified)
                    _badge('KIN Verified', const Color(0xFFE87040)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 10.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
