import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationBeaconBadgeWidget extends StatelessWidget {
  const LocationBeaconBadgeWidget({
    super.key,
    required this.location,
    required this.expiresAt,
  });

  final String location;
  final DateTime? expiresAt;

  String _formatTimeRemaining(DateTime expiresAt) {
    final now = DateTime.now();
    final duration = expiresAt.difference(now);

    if (duration.isNegative) return 'Expired';
    if (duration.inHours > 0) return '${duration.inHours}h left';
    if (duration.inMinutes > 0) return '${duration.inMinutes}m left';
    return 'Expiring soon';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).success,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '🚨 Now Serving',
                  style: FlutterFlowTheme.of(context).labelSmall.override(
                        font: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                        ),
                        color: Colors.white,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  location,
                  style: FlutterFlowTheme.of(context).labelSmall.override(
                        font: GoogleFonts.plusJakartaSans(),
                        color: Colors.white,
                        letterSpacing: 0.0,
                      ),
                ),
              ],
            ),
            if (expiresAt != null) ...[
              const SizedBox(height: 4.0),
              Text(
                '🚐 Live • ${_formatTimeRemaining(expiresAt!)}',
                style: FlutterFlowTheme.of(context).labelSmall.override(
                      font: GoogleFonts.plusJakartaSans(),
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11.0,
                      letterSpacing: 0.0,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
