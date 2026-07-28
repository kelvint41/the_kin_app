import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/animated_kin_logo_widget.dart';
import '/components/marquee_ticker_widget.dart';
import '/services/kin_services.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'onboarding_selection_card_model.dart';
export 'onboarding_selection_card_model.dart';

/// Create a premium, high-impact, and eye-catching mobile onboarding landing
/// page for a community platform called "The KIN App".
///
/// The page must be a full-screen layout with absolutely NO bottom navigation
/// bar and NO tab bars.  Color Palette & Visuals: - Main Background: A
/// full-screen background container. It needs a subtle, looping motion or
/// clean video/lottie background showing abstract connecting neon lines,
/// digital network nodes, and community silhouettes moving dynamically to
/// reflect collective economic growth. - Theme: Deep dark mode background
/// (solid rich black) contrasted with high-visibility vibrant electric
/// green/neon lime accents. - Typography: Crisp white for main headings,
/// clean bright silver-gray for subtitles.  Key Components from Top to
/// Bottom:  1. Stock Market Ticker Header: A thin, 36px high horizontal bar
/// spanning 100% width with a black background at the absolute top of the
/// page. Inside, show a row mimicking a financial index feed: "KNDX 1.24 ▲
/// +14.7%  |  HMDN 14.70 ▲ +8.5%  |  KNVST 2.10 ▲ +12.3%". Symbols are white,
/// numbers are silver, arrows and percentages are electric green. 2. Centered
/// Logo Window: A clean, circular placeholder container for the main app
/// logo, centered beautifully below the ticker bar. 3. High-Impact Titles: A
/// large, bold white headline reading "Invest in Community." followed by a
/// clean silver subtitle reading "Empowering local independent Black-owned
/// businesses through collective loyalty." 4. Triple-Action Button Stack: In
/// the lower third, stack three large, rounded full-width buttons (height
/// 55px) vertically:    - Button 1 (Top): Solid electric green background
/// fill with dark text, labeled "I'm a Shopper / Customer".    - Button 2
/// (Middle): Outlined style with an electric green border, transparent
/// background, and white text, labeled "I'm a Business Owner / Founder".    -
/// Button 3 (Bottom): Outlined style with a thin silver border, transparent
/// background, and silver text, labeled "I'm a Business Director". 5. Footer:
/// A small, centered text link at the absolute bottom reading "New to
/// Kinvest? Create an account".  Ensure clean structural padding (24px side
/// margins) and a minimalist but vibrant aesthetic organized within a single
/// main column.
class OnboardingSelectionCardWidget extends StatefulWidget {
  const OnboardingSelectionCardWidget({super.key});

  static String routeName = 'Onboarding_Selection_Card';
  static String routePath = '/onboardingSelectionCard';

  @override
  State<OnboardingSelectionCardWidget> createState() =>
      _OnboardingSelectionCardWidgetState();
}

class _OnboardingSelectionCardWidgetState
    extends State<OnboardingSelectionCardWidget> {
  late OnboardingSelectionCardModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  LatLng? currentUserLocationValue;
  List<KindexTickerEntry> _businessKindexEntries = [];
  List<KindexTickerEntry> _customerKindexEntries = [];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => OnboardingSelectionCardModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      FFAppState().sessionId =
          '${getCurrentTimestamp.millisecondsSinceEpoch.toString()}';
      safeSetState(() {});
    });

    getCurrentUserLocation(defaultLocation: LatLng(0.0, 0.0), cached: true)
        .then((loc) => safeSetState(() => currentUserLocationValue = loc));

    KinServices.fetchTopBusinessKindex().then((result) {
      if (result.isSuccess && result.data != null && mounted) {
        safeSetState(() => _businessKindexEntries = result.data!);
      }
    });

    KinServices.fetchTopCustomerKindex().then((result) {
      if (result.isSuccess && result.data != null && mounted) {
        safeSetState(() => _customerKindexEntries = result.data!);
      }
    });
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    if (currentUserLocationValue == null) {
      return Container(
        color: FlutterFlowTheme.of(context).primaryBackground,
        child: Center(
          child: SizedBox(
            width: 50.0,
            height: 50.0,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                FlutterFlowTheme.of(context).secondaryText,
              ),
            ),
          ),
        ),
      );
    }

    return StreamBuilder<List<BusinessesRecord>>(
      stream: queryBusinessesRecord(
        queryBuilder: (businessesRecord) => businessesRecord
            .where(
              'city',
              isEqualTo: currentUserLocationValue?.toString(),
            )
            .orderBy('kindex_score', descending: true),
        limit: 3,
      ),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).secondaryText,
                  ),
                ),
              ),
            ),
          );
        }
        List<BusinessesRecord> onboardingSelectionCardBusinessesRecordList =
            snapshot.data!;

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            // The ticker was the first thing in an unpadded Column, so it
            // rendered underneath the status bar - the clock, battery and
            // signal icons sat directly on top of the scrolling scores.
            // SafeArea drops it clear of the notch. bottom: false because
            // the buttons below already carry their own padding and would
            // otherwise gain a second inset.
            body: SafeArea(
              bottom: false,
              child: Column(
              children: [
                MarqueeTickerWidget(
                  businessEntries: _businessKindexEntries,
                  customerEntries: _customerKindexEntries,
                ),
                Expanded(
                  child: Stack(
                    alignment: AlignmentDirectional(-1.0, -1.0),
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) =>
                            SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                minHeight: constraints.maxHeight),
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Was a static Image.asset at 200x208.1
                                  // with BoxFit.cover, which cropped the
                                  // mark slightly. AnimatedKinLogo uses
                                  // BoxFit.contain inside a square box, so
                                  // it also shows the whole logo.
                                  const AnimatedKinLogo(size: 208.0),
                                  SizedBox(height: 32.0),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Align(
                                        alignment:
                                            AlignmentDirectional(0.0, 0.0),
                                        child: Text(
                                          'Invest in Community.',
                                          textAlign: TextAlign.center,
                                          style: FlutterFlowTheme.of(context)
                                              .headlineLarge
                                              .override(
                                                font:
                                                    GoogleFonts.plusJakartaSans(
                                                  fontWeight: FontWeight.w800,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .headlineLarge
                                                          .fontStyle,
                                                ),
                                                color: Colors.white,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w800,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .headlineLarge
                                                        .fontStyle,
                                                lineHeight: 1.4,
                                              ),
                                        ),
                                      ),
                                      Text(
                                        'Empowering local independent Black-owned businesses through collective loyalty.',
                                        textAlign: TextAlign.center,
                                        style: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .override(
                                              font: GoogleFonts.plusJakartaSans(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .titleMedium
                                                        .fontWeight,
                                                fontStyle: FontStyle.italic,
                                              ),
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontWeight,
                                              fontStyle: FontStyle.italic,
                                              lineHeight: 1.5,
                                            ),
                                      ),
                                    ].divide(SizedBox(height: 16.0)),
                                  ),
                                  InkWell(
                                    splashColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    onTap: () async {
                                      FFAppState().signupType = 'customer';
                                      safeSetState(() {});

                                      context.pushNamed(
                                          CustomersignupPageWidget.routeName);
                                    },
                                    child: Container(
                                      height: 55.0,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                        boxShadow: [
                                          BoxShadow(
                                            blurRadius: 15.0,
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            offset: Offset(
                                              0.0,
                                              4.0,
                                            ),
                                            spreadRadius: 0.0,
                                          )
                                        ],
                                        borderRadius:
                                            BorderRadius.circular(24.0),
                                        shape: BoxShape.rectangle,
                                      ),
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      child: Text(
                                        'I\'m a Shopper / Customer',
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
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                              lineHeight: 1.4,
                                            ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    splashColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    onTap: () async {
                                      FFAppState().signupType = 'business';
                                      safeSetState(() {});

                                      // Business setup registers against the
                                      // signed-in user - registerBusiness
                                      // fails outright without one. Sending a
                                      // signed-out visitor straight there
                                      // meant filling the whole form (name,
                                      // category, address picker, phone,
                                      // description) only to be told to sign
                                      // in on submit, with all of it lost and
                                      // no route to an account from that
                                      // screen. Account first, then setup.
                                      //
                                      // signupType is what carries the intent
                                      // across: it was already being set here
                                      // and on the customer button, and read
                                      // nowhere.
                                      context.pushNamed(loggedIn
                                          ? BusinessSetupPageWidget.routeName
                                          : CustomersignupPageWidget.routeName);
                                    },
                                    child: Container(
                                      height: 55.0,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        borderRadius:
                                            BorderRadius.circular(24.0),
                                        shape: BoxShape.rectangle,
                                        border: Border.all(
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          width: 2.0,
                                        ),
                                      ),
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      child: Text(
                                        'I\'m a Black-Owned Business',
                                        style: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .override(
                                              font: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w600,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleMedium
                                                        .fontStyle,
                                              ),
                                              color: Colors.white,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                              lineHeight: 1.4,
                                            ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    splashColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    onTap: () async {
                                      context.pushNamed(
                                          SignInPageWidget.routeName);
                                    },
                                    // The InkWell wrapped the Text directly,
                                    // so the tap target was exactly the glyph
                                    // bounds - about 20pt tall, well under
                                    // the 44pt minimum, and easy to miss on
                                    // the one control that returning users
                                    // need. Padding inside the InkWell grows
                                    // the target; outside it would not.
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12.0, horizontal: 16.0),
                                      child: Text(
                                      'Already have an account?',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.plusJakartaSans(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                    ),
                                  ),
                                ].divide(SizedBox(height: 32.0)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              ),
            ),
          ),
        );
      },
    );
  }
}
