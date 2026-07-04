import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'mobile_sign_up_page_model.dart';
export 'mobile_sign_up_page_model.dart';

/// Create a mobile sign-up page called 'JoinKinCommunity' with a solid deep
/// charcoal background #121212.
///
/// Use generous spacing throughout with 24 pixels of horizontal padding on
/// the page body and comfortable vertical gaps between all elements so the
/// layout feels open and uncramped.
///
/// Wrap the entire page body in a SingleChildScrollView containing a Column
/// with crossAxisAlignment stretch.
///
/// At the top, after 48 pixels of top padding, place a circular logo
/// placeholder Container 72x72 pixels centered with a gold background #d4af37
/// and a community icon in dark color inside it. Below the logo add 24 pixels
/// of spacing.
///
/// Below that place a bold white headline Text 'Join the KIN Community' size
/// 26 centered. Below it add a grey subtitle Text 'Support Black-owned
/// businesses in San Antonio and beyond.' size 14 centered with color
/// #9e9e9e. Add 36 pixels of spacing below the subtitle.
///
/// Add three TextFields stacked vertically with 16 pixels of spacing between
/// each. Each TextField has a dark fill background #1e1e1e, rounded corners
/// radius 12, white input text, grey hint text #9e9e9e, no visible border,
/// and internal content padding of 16. Field one is labeled 'Full Name' with
/// a person icon in gold on the left. Field two is labeled 'Email Address'
/// with an email icon in gold on the left and keyboard type email. Field
/// three is labeled 'Password' with a lock icon in gold on the left and
/// obscure text enabled.
///
/// Add 32 pixels of spacing, then place a full-width 'Sign Up' button with a
/// gold background #d4af37, dark bold text #0d1a14 size 16, height 54, and
/// rounded corners radius 12.
///
/// At the bottom add 24 pixels of spacing then a centered Row containing grey
/// Text 'Already have an account?' size 14 color #9e9e9e and a gold Text link
/// 'Login' size 14 bold color #d4af37 with a small left gap between them.
///
/// Add 32 pixels of bottom padding so nothing is clipped by the device
/// navigation bar.
class MobileSignUpPageWidget extends StatefulWidget {
  const MobileSignUpPageWidget({super.key});

  static String routeName = 'MobileSignUpPage';
  static String routePath = '/mobileSignUpPage';

  @override
  State<MobileSignUpPageWidget> createState() => _MobileSignUpPageWidgetState();
}

class _MobileSignUpPageWidgetState extends State<MobileSignUpPageWidget> {
  late MobileSignUpPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MobileSignUpPageModel());
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
        backgroundColor: Color(0xFF121212),
        body: SingleChildScrollView(
          primary: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(24.0, 48.0, 24.0, 32.0),
                child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        alignment: AlignmentDirectional(0.0, 0.0),
                        child: Container(
                          width: 72.0,
                          height: 72.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).primaryText,
                            borderRadius: BorderRadius.circular(9999.0),
                            shape: BoxShape.rectangle,
                          ),
                          alignment: AlignmentDirectional(0.0, 0.0),
                          child: Icon(
                            Icons.groups_rounded,
                            color: Color(0xFF0D1A14),
                            size: 36.0,
                          ),
                        ),
                      ),
                      Container(
                        height: 24.0,
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Join the KIN Community',
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color: Colors.white,
                                  fontSize: 26.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                  lineHeight: 1.4,
                                ),
                          ),
                          Text(
                            'Support Black-owned businesses in San Antonio and beyond.',
                            textAlign: TextAlign.center,
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
                                  color: Color(0xFF9E9E9E),
                                  fontSize: 14.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                  lineHeight: 1.4,
                                ),
                          ),
                        ].divide(SizedBox(height: 4.0)),
                      ),
                      Container(
                        height: 36.0,
                      ),
                      Container(
                        height: 32.0,
                      ),
                      Container(
                        height: 24.0,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
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
                                  color: Color(0xFF9E9E9E),
                                  fontSize: 14.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                  lineHeight: 1.4,
                                ),
                          ),
                          Text(
                            'Login',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  fontSize: 14.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                  lineHeight: 1.4,
                                ),
                          ),
                        ].divide(SizedBox(width: 4.0)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
