import '/backend/backend.dart';
import '/services/kin_services.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'clean_elegant_mobile_model.dart';
export 'clean_elegant_mobile_model.dart';

/// Create a clean, elegant mobile app Bottom Sheet component named
/// "ModernBottomSheet".
///
/// The background must be a very dark charcoal color (#1A1D1E or #1E2222).
///
/// At the top center, include a subtle, horizontal drag-handle indicator bar.
/// Underneath, add a centered title header that says "Order Delivery via KIN"
/// styled with an authoritative, deep gold color.
///
/// Below the header, stack three large, full-width pill-shaped buttons with
/// smooth, fully rounded corners (high border-radius). Each button must
/// contain a small gold "+" icon inline next to centered text, styled as
/// follows:
/// 1. Top Button: Background color deep rich forest green (#0B3D2E), text
/// says "DoorDash" in gold.
/// 2. Middle Button: Background color muted gold/tan (#C5A059), text says
/// "UberEats" in a dark color or charcoal.
/// 3. Bottom Button: Transparent background with a thin, subtle outline
/// border, text says "Grubhub" in gold.
///
/// Maintain clean spacing between each pill button, ensuring a premium,
/// minimalist user experience.
class CleanElegantMobileWidget extends StatefulWidget {
  const CleanElegantMobileWidget({
    super.key,
    required this.businessDoc,
  });

  final BusinessesRecord? businessDoc;

  @override
  State<CleanElegantMobileWidget> createState() =>
      _CleanElegantMobileWidgetState();
}

class _CleanElegantMobileWidgetState extends State<CleanElegantMobileWidget> {
  late CleanElegantMobileModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CleanElegantMobileModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.0),
          topRight: Radius.circular(32.0),
        ),
        shape: BoxShape.rectangle,
      ),
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(9999.0),
                  shape: BoxShape.rectangle,
                ),
              ),
              Text(
                'Delivery via The KIN App',
                textAlign: TextAlign.center,
                style: FlutterFlowTheme.of(context).titleMedium.override(
                      font: GoogleFonts.plusJakartaSans(
                        fontWeight:
                            FlutterFlowTheme.of(context).titleMedium.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).titleMedium.fontStyle,
                      ),
                      color: Color(0xFFD4AF37),
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).titleMedium.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).titleMedium.fontStyle,
                      lineHeight: 1.4,
                    ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Only rendered when we actually hold this
                  // platform's link. Every tile used to render
                  // unconditionally, so a business listed on one service
                  // still showed all three and two of them called
                  // launchURL('').
                  if (widget!.businessDoc!.doordashUrl.isNotEmpty)
                  InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () async {
                      await KinServices.launchBusinessLink(widget!.businessDoc!.doordashUrl);
                    },
                    child: Container(
                      height: 56.0,
                      decoration: BoxDecoration(
                        color: Color(0xFF0B3D2E),
                        borderRadius: BorderRadius.circular(9999.0),
                        shape: BoxShape.rectangle,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Container(
                          child: Container(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  color: Color(0xFFD4AF37),
                                  size: 18.0,
                                ),
                                Text(
                                  'DoorDash',
                                  style: FlutterFlowTheme.of(context)
                                      .labelLarge
                                      .override(
                                        font: GoogleFonts.plusJakartaSans(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .labelLarge
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelLarge
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFFD4AF37),
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .fontStyle,
                                        lineHeight: 1.4,
                                      ),
                                ),
                              ].divide(SizedBox(width: 8.0)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Only rendered when we actually hold this
                  // platform's link. Every tile used to render
                  // unconditionally, so a business listed on one service
                  // still showed all three and two of them called
                  // launchURL('').
                  if (widget!.businessDoc!.ubereatsUrl.isNotEmpty)
                  InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () async {
                      await KinServices.launchBusinessLink(widget!.businessDoc!.ubereatsUrl);
                    },
                    child: Container(
                      height: 56.0,
                      decoration: BoxDecoration(
                        color: Color(0xFFC5A059),
                        borderRadius: BorderRadius.circular(9999.0),
                        shape: BoxShape.rectangle,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Container(
                          child: Container(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  color: Color(0xFF1A1D1E),
                                  size: 18.0,
                                ),
                                Text(
                                  'UberEats',
                                  style: FlutterFlowTheme.of(context)
                                      .labelLarge
                                      .override(
                                        font: GoogleFonts.plusJakartaSans(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .labelLarge
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelLarge
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFF1A1D1E),
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .fontStyle,
                                        lineHeight: 1.4,
                                      ),
                                ),
                              ].divide(SizedBox(width: 8.0)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Only rendered when we actually hold this
                  // platform's link. Every tile used to render
                  // unconditionally, so a business listed on one service
                  // still showed all three and two of them called
                  // launchURL('').
                  if (widget!.businessDoc!.grubhubUrl.isNotEmpty)
                  InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () async {
                      await KinServices.launchBusinessLink(widget!.businessDoc!.grubhubUrl);
                    },
                    child: Container(
                      height: 56.0,
                      decoration: BoxDecoration(
                        color: Color(0xFFDF0808),
                        borderRadius: BorderRadius.circular(9999.0),
                        shape: BoxShape.rectangle,
                        border: Border.all(
                          color: Color(0x66D4AF37),
                          width: 1.0,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Container(
                          child: Container(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  color: Color(0xFFD4AF37),
                                  size: 18.0,
                                ),
                                Text(
                                  'Grubhub',
                                  style: FlutterFlowTheme.of(context)
                                      .labelLarge
                                      .override(
                                        font: GoogleFonts.plusJakartaSans(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .labelLarge
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelLarge
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFFD4AF37),
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .fontStyle,
                                        lineHeight: 1.4,
                                      ),
                                ),
                              ].divide(SizedBox(width: 8.0)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ].divide(SizedBox(height: 16.0)),
              ),
            ].divide(SizedBox(height: 24.0)),
          ),
        ),
      ),
    );
  }
}
