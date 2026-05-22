import '/components/ticker_card_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'premium_mobile_user_page_model.dart';
export 'premium_mobile_user_page_model.dart';

/// A premium mobile app user interface design for an onboarding screen,
/// displayed as a sharp, front-facing smartphone mockup on a clean black
/// background.
///
/// The app layout features a true pitch-black theme (#000000). At the top
/// center, The KIN App logo emblem is boldly displayed with glowing gold and
/// vibrant emerald green leaf details. Directly below the logo, a minimalist
/// dashboard component showcases a "KINDEX LIVE TICKER". The ticker layout
/// features a clean vertical separation: the top section displays bold, crisp
/// numbers in refined Gold (#C5A039) representing registered businesses, and
/// the bottom section displays scrolling numbers in bright Kindex Green
/// (#1E8131) representing active customers. In the lower third of the screen,
/// there are two large, high-contrast, rounded rectangles serving as buttons:
/// a vibrant green button that reads "I'M A SHOPPER" in clean white
/// typography, and a warm gold button that reads "I'M A BUSINESS OWNER".
/// Modern, ultra-clean aesthetic, high-end neo-noir lighting, perfectly
/// centered, no generic stock photos or messy backgrounds.
class PremiumMobileUserPageWidget extends StatefulWidget {
  const PremiumMobileUserPageWidget({super.key});

  static String routeName = 'PremiumMobileUserPage';
  static String routePath = '/premiumMobileUserPage';

  @override
  State<PremiumMobileUserPageWidget> createState() =>
      _PremiumMobileUserPageWidgetState();
}

class _PremiumMobileUserPageWidgetState
    extends State<PremiumMobileUserPageWidget> {
  late PremiumMobileUserPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PremiumMobileUserPageModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.black,
        body: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(24.0, 40.0, 24.0, 40.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 20.0, 0.0, 40.0),
                child: Container(
                  child: Container(
                    width: 120.0,
                    height: 120.0,
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: Stack(
                      alignment: AlignmentDirectional(-1.0, -1.0),
                      children: [
                        ClipRect(
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: 40.0,
                              sigmaY: 40.0,
                            ),
                            child: Container(
                              width: 80.0,
                              height: 80.0,
                              decoration: BoxDecoration(
                                color: Color(0x33C5A039),
                                borderRadius: BorderRadius.circular(9999.0),
                                shape: BoxShape.rectangle,
                              ),
                            ),
                          ),
                        ),
                        CachedNetworkImage(
                          fadeInDuration: Duration(milliseconds: 0),
                          fadeOutDuration: Duration(milliseconds: 0),
                          imageUrl:
                              'https://dimg.dreamflow.cloud/v1/image/premium%20circular%20emblem%20with%20gold%20and%20emerald%20green%20leaf%20details',
                          width: 100.0,
                          height: 100.0,
                          fit: BoxFit.contain,
                          alignment: Alignment(0.0, 0.0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'KINDEX LIVE TICKER',
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).labelLarge.override(
                          font: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelLarge
                                .fontStyle,
                          ),
                          color: Color(0xFFC5A039),
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                          fontStyle:
                              FlutterFlowTheme.of(context).labelLarge.fontStyle,
                          lineHeight: 1.4,
                        ),
                  ),
                  wrapWithModel(
                    model: _model.tickerCardModel1,
                    updateCallback: () => safeSetState(() {}),
                    child: TickerCardWidget(
                      title: 'NETWORK GROWTH',
                      value: '1,284',
                      color: Color(0xFFC5A039),
                      label: 'REGISTERED BUSINESSES',
                    ),
                  ),
                  wrapWithModel(
                    model: _model.tickerCardModel2,
                    updateCallback: () => safeSetState(() {}),
                    child: TickerCardWidget(
                      title: 'COMMUNITY REACH',
                      value: '42,903',
                      color: Color(0xFF1E8131),
                      label: 'ACTIVE CUSTOMERS',
                    ),
                  ),
                ].divide(SizedBox(height: 16.0)),
              ),
              Spacer(),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 40.0, 0.0, 0.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF1E8131),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 16.0,
                            color: Color(0x441E8131),
                            offset: Offset(
                              0.0,
                              8.0,
                            ),
                            spreadRadius: 0.0,
                          )
                        ],
                        borderRadius: BorderRadius.circular(24.0),
                        shape: BoxShape.rectangle,
                      ),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            0.0, 20.0, 0.0, 20.0),
                        child: Container(
                          child: Container(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_bag_rounded,
                                  size: 24.0,
                                ),
                                Text(
                                  'I\'M A SHOPPER',
                                  style: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .override(
                                        font: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleMedium
                                                  .fontStyle,
                                        ),
                                        color: Colors.white,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .fontStyle,
                                        lineHeight: 1.4,
                                      ),
                                ),
                              ].divide(SizedBox(width: 16.0)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFC5A039),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 16.0,
                            color: Color(0x44C5A039),
                            offset: Offset(
                              0.0,
                              8.0,
                            ),
                            spreadRadius: 0.0,
                          )
                        ],
                        borderRadius: BorderRadius.circular(24.0),
                        shape: BoxShape.rectangle,
                      ),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            0.0, 20.0, 0.0, 20.0),
                        child: Container(
                          child: Container(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.store_rounded,
                                  color: Colors.black,
                                  size: 24.0,
                                ),
                                Text(
                                  'I\'M A BUSINESS OWNER',
                                  style: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .override(
                                        font: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleMedium
                                                  .fontStyle,
                                        ),
                                        color: Colors.black,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .fontStyle,
                                        lineHeight: 1.4,
                                      ),
                                ),
                              ].divide(SizedBox(width: 16.0)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ].divide(SizedBox(height: 24.0)),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 20.0, 0.0, 0.0),
                child: Container(
                  child: Text(
                    'THE KIN APP • PREMIUM COMMERCE',
                    style: FlutterFlowTheme.of(context).labelSmall.override(
                          font: GoogleFonts.plusJakartaSans(
                            fontWeight: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontStyle,
                          ),
                          color: Color(0x6614181B),
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .labelSmall
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).labelSmall.fontStyle,
                          lineHeight: 1.4,
                        ),
                  ),
                ),
              ),
            ].divide(SizedBox(height: 32.0)),
          ),
        ),
      ),
    );
  }
}
