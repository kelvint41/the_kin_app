import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/services/kin_services.dart';

/// Business Profile QR Code Generator (owner view).
///
/// Encodes the same canonical link KinServices.businessProfileUrl produces
/// - see its doc comment for the full scan-to-open-app story and what's
/// still missing (Universal/App Links verification on thekinapp.com
/// itself). `/business/:businessId` (see nav.dart) is a real route now,
/// so a tap that reaches the app - already installed, opened via the
/// thekinapp:// scheme, or a future web build - lands on this exact
/// business.
///
/// The QR code itself renders 100% client-side (qr_flutter, no network
/// call).
class BusinessQrCodeCard extends StatelessWidget {
  const BusinessQrCodeCard({super.key, required this.business});

  final BusinessesRecord business;

  String get _profileUrl =>
      KinServices.businessProfileUrl(business.reference);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
        border: Border.all(color: theme.alternate, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_2_rounded, color: theme.secondary, size: 20.0),
              SizedBox(width: 8.0),
              Text(
                'Your Business QR Code',
                style: theme.titleSmall.override(
                  font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  color: theme.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.0),
          Text(
            'Print it on a flyer, table tent, or receipt - a scan takes '
            'shoppers straight to your KIN profile.',
            style: theme.bodySmall.override(
              color: theme.secondaryText,
              lineHeight: 1.4,
            ),
          ),
          SizedBox(height: 16.0),
          Center(
            child: Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: QrImageView(
                data: _profileUrl,
                version: QrVersions.auto,
                size: 180.0,
                backgroundColor: Colors.white,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF0B3D2E),
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF0B3D2E),
                ),
              ),
            ),
          ),
          SizedBox(height: 12.0),
          Text(
            _profileUrl,
            textAlign: TextAlign.center,
            style: theme.labelSmall.override(color: theme.secondaryText),
          ),
          SizedBox(height: 16.0),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final box = context.findRenderObject() as RenderBox?;
                await KinServices.shareApp(
                  text: '${business.businessName} on KIN - $_profileUrl',
                  sharePositionOrigin: box == null
                      ? null
                      : box.localToGlobal(Offset.zero) & box.size,
                  businessRef: business.reference,
                );
              },
              icon: Icon(Icons.share_rounded, size: 16.0, color: theme.primary),
              label: Text(
                'Share Link',
                style: theme.labelMedium.override(
                  font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  color: theme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.primary, width: 1.0),
                padding: EdgeInsets.symmetric(vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
