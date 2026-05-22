import '/models/kin_business_profile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Renders independent ownership badges. Both can appear together.
class KinBusinessOwnershipBadges extends StatelessWidget {
  const KinBusinessOwnershipBadges({
    super.key,
    required this.profile,
    this.compact = false,
  });

  final KinBusinessProfile profile;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!profile.isBlackOwned &&
        !profile.isVeteran &&
        !profile.isBobVerified) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: compact ? 6.0 : 8.0,
      runSpacing: compact ? 4.0 : 6.0,
      children: [
        if (profile.isBlackOwned)
          _OwnershipBadge(
            label: compact ? 'Black-owned' : 'Black-owned',
            color: const Color(0xFF1A3A5C),
            compact: compact,
          ),
        if (profile.isVeteran)
          _OwnershipBadge(
            label: compact ? 'Veteran-owned' : 'Veteran-owned',
            color: const Color(0xFF2E5077),
            compact: compact,
          ),
        if (profile.isBobVerified)
          _OwnershipBadge(
            label: compact ? 'KIN Verified' : 'KIN Verified',
            color: const Color(0xFFE87040),
            compact: compact,
          ),
      ],
    );
  }
}

class _OwnershipBadge extends StatelessWidget {
  const _OwnershipBadge({
    required this.label,
    required this.color,
    required this.compact,
  });

  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6.0 : 8.0,
        vertical: compact ? 3.0 : 4.0,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: compact ? 9.0 : 10.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
