import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => OnboardingSelectionCardModel());
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
        backgroundColor: FlutterFlowTheme.of(context).primary,
        body: Stack(
          alignment: AlignmentDirectional(-1.0, -1.0),
          children: [
            Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(0.0),
                          child: Image.asset(
                            'assets/images/splash_logo_1024_transparent.png',
                            width: 200.0,
                            height: 208.1,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Spacer(),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Align(
                              alignment: AlignmentDirectional(0.0, 0.0),
                              child: Text(
                                'Invest in Community.',
                                textAlign: TextAlign.center,
                                style: FlutterFlowTheme.of(context)
                                    .headlineLarge
                                    .override(
                                      font: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .headlineLarge
                                            .fontStyle,
                                      ),
                                      color: Colors.white,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w800,
                                      fontStyle: FlutterFlowTheme.of(context)
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
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontWeight,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
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

                            context
                                .pushNamed(LegalCompliancePageWidget.routeName);
                          },
                          child: Container(
                            height: 55.0,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).secondary,
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 15.0,
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  offset: Offset(
                                    0.0,
                                    4.0,
                                  ),
                                  spreadRadius: 0.0,
                                )
                              ],
                              borderRadius: BorderRadius.circular(24.0),
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
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                    ),
                                    color:
                                        FlutterFlowTheme.of(context).onPrimary,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
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

                            context
                                .pushNamed(LegalCompliancePageWidget.routeName);
                          },
                          child: Container(
                            height: 55.0,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).secondary,
                              borderRadius: BorderRadius.circular(24.0),
                              shape: BoxShape.rectangle,
                              border: Border.all(
                                color: FlutterFlowTheme.of(context).primaryText,
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
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                    ),
                                    color: Colors.white,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
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
                            context.pushNamed(SignInPageWidget.routeName);
                          },
                          child: Text(
                            'Already have an account?',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.plusJakartaSans(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color:
                                      FlutterFlowTheme.of(context).onSecondary,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                          ),
                        ),
                        Spacer(flex: 2),
                      ].divide(SizedBox(height: 32.0)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
