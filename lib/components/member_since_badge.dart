import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// "KIN member since 2026" - a small tenure/trust signal for wherever a
/// customer's own profile or impact stats live (Community Impact
/// Dashboard, Customer Profile).
///
/// Reads `users.created_time`, set once at account creation for every
/// account going forward (see backend.dart's createAccountIfNeeded - "the
/// single point every new account is created regardless of sign-in
/// method"). Renders nothing for the rare pre-existing account that
/// predates that field, rather than guessing a year or showing a
/// placeholder.
class MemberSinceBadge extends StatelessWidget {
  const MemberSinceBadge({super.key, this.color, this.iconColor});

  /// Text color override. The Community Impact hero card sits on a fixed
  /// dark green gradient regardless of theme, so it needs a fixed light
  /// color there rather than the theme's normal secondaryText.
  final Color? color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final createdTime = currentUserDocument?.createdTime;
    if (createdTime == null) return const SizedBox.shrink();
    final theme = FlutterFlowTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.verified_rounded,
          size: 13.0,
          color: iconColor ?? color ?? theme.secondary,
        ),
        SizedBox(width: 4.0),
        Text(
          'KIN member since ${createdTime.year}',
          style: theme.labelSmall.override(
            font: GoogleFonts.plusJakartaSans(),
            color: color ?? theme.secondaryText,
            letterSpacing: 0.0,
          ),
        ),
      ],
    );
  }
}
