import '/auth/firebase_auth/auth_util.dart';
import '/components/kin_back_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/form_validation.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'sign_in_page_model.dart';
export 'sign_in_page_model.dart';

/// Create a premium dark-mode Log In page for a mobile directory app called
/// KIN that perfectly mirrors a companion signup page.
///
/// Layout & Theme Requirements:
/// - Background color: Deep matte dark charcoal/black (#0E0F0F or similar
/// deep black).
/// - Content container: Centered vertical column with comfortable padding on
/// the sides.
/// - Top navigation: Include a circular back arrow icon button wrapped in a
/// subtle dark green ring at the top left.
///
/// Typography & Content:
/// - Header 1 text: "Welcome Back" in a bold, clean sans-serif font using a
/// rich forest green color (#0B4632).
/// - Subtitle text: "Log in to support Black-owned businesses." in a warm
/// gold/muted amber color (#D4AF37 or #C5A059).
///
/// Form Input Fields:
/// - Create two distinct text fields: "Email Address" and "Password".
/// - Label text above each field should be in the same gold/muted amber
/// color.
/// - Field styling: Dark background matching the theme, rounded corners
/// (border-radius 12px), an icon on the far left inside the field
/// (person/email icon for email, lock icon for password), and muted grey
/// placeholder text ("Enter your email", "Enter your password").
///
/// Buttons & Footer:
/// - Primary Action Button: A wide, high-contrast button labeled "Log In"
/// with a right-facing arrow icon (Log In ->). The button background must be
/// solid deep forest green (#0B4632) with clean white or light gold text.
/// - Underneath the main button, include a "Forgot Password?" text link
/// styled in the muted gold color.
/// - Bottom Row: A clean row centered at the very bottom matching the
/// highlighted container design. Text reads: "Don't have an account? " in a
/// muted tan/gold, followed by an inline clickable Text or Button component
/// inside a clean layout container labeled "Sign Up" in forest green.
class SignInPageWidget extends StatefulWidget {
  const SignInPageWidget({super.key});

  static String routeName = 'SignInPage';
  static String routePath = '/signInPage';

  @override
  State<SignInPageWidget> createState() => _SignInPageWidgetState();
}

class _SignInPageWidgetState extends State<SignInPageWidget> {
  late SignInPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SignInPageModel());

    _model.emailFieldTextController ??= TextEditingController();
    _model.emailFieldFocusNode ??= FocusNode();

    _model.passwordFieldTextController ??= TextEditingController();
    _model.passwordFieldFocusNode ??= FocusNode();
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
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        // Without this the back button sat level with the status-bar clock.
        // bottom: false - the page's own 32pt padding already clears that
        // edge, and a second inset would push the content up.
        body: SafeArea(
          bottom: false,
          child: Padding(
          padding: EdgeInsets.all(32.0),
          // The page had no scroll wrapper at all - on a shorter screen or
          // a larger system font size, the back button, heading, two text
          // fields, button, and links plus eight 32px gaps between them
          // don't all fit, which overflowed vertically (a different bug
          // from the horizontal Row overflow fixed above in the "Don't
          // have an account" link). mainAxisSize must be min here - max
          // would try to fill the now-unbounded height a scroll view
          // gives its child, which throws rather than overflows.
          child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // safePop rather than pushing onboarding: pushing grew
                  // the stack on every back tap, so repeatedly moving
                  // between here and onboarding left an unbounded history
                  // behind the user. safePop also covers the case this page
                  // is the only route - arriving here from sign-out
                  // replaces the stack - by going to '/', which renders
                  // onboarding while logged out. (KinBackButton's default
                  // onPressed already does this.)
                  KinBackButton(),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).secondaryText,
                          fontSize: 32.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                          lineHeight: 1.4,
                        ),
                  ),
                  Text(
                    'Log in to support Black-owned businesses.',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.plusJakartaSans(
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).primaryText,
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                          lineHeight: 1.4,
                        ),
                  ),
                ].divide(SizedBox(height: 8.0)),
              ),
              Container(
                width: 200.0,
                child: TextFormField(
                  controller: _model.emailFieldTextController,
                  focusNode: _model.emailFieldFocusNode,
                  autofocus: false,
                  enabled: true,
                  obscureText: false,
                  decoration: InputDecoration(
                    isDense: true,
                    labelStyle:
                        FlutterFlowTheme.of(context).labelMedium.override(
                              font: GoogleFonts.plusJakartaSans(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .fontStyle,
                              ),
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .fontStyle,
                            ),
                    hintText: 'Email Address',
                    hintStyle:
                        FlutterFlowTheme.of(context).labelMedium.override(
                              font: GoogleFonts.plusJakartaSans(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .fontStyle,
                              ),
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .fontStyle,
                            ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0x00000000),
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0x00000000),
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).error,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).error,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                  ),
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.plusJakartaSans(
                          fontWeight: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                  cursorColor: FlutterFlowTheme.of(context).primaryText,
                  enableInteractiveSelection: true,
                  validator: _model.emailFieldTextControllerValidator
                      .asValidator(context),
                ),
              ),
              Container(
                width: 200.0,
                child: TextFormField(
                  controller: _model.passwordFieldTextController,
                  focusNode: _model.passwordFieldFocusNode,
                  autofocus: false,
                  enabled: true,
                  obscureText: !_model.passwordFieldVisibility,
                  decoration: InputDecoration(
                    isDense: true,
                    labelStyle:
                        FlutterFlowTheme.of(context).labelMedium.override(
                              font: GoogleFonts.plusJakartaSans(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .fontStyle,
                              ),
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .fontStyle,
                            ),
                    hintText: 'Password',
                    hintStyle:
                        FlutterFlowTheme.of(context).labelMedium.override(
                              font: GoogleFonts.plusJakartaSans(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .fontStyle,
                              ),
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .fontStyle,
                            ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0x00000000),
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0x00000000),
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).error,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).error,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                    suffixIcon: InkWell(
                      onTap: () async {
                        safeSetState(() => _model.passwordFieldVisibility =
                            !_model.passwordFieldVisibility);
                      },
                      focusNode: FocusNode(skipTraversal: true),
                      child: Icon(
                        _model.passwordFieldVisibility
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 22,
                      ),
                    ),
                  ),
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.plusJakartaSans(
                          fontWeight: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                  cursorColor: FlutterFlowTheme.of(context).primaryText,
                  enableInteractiveSelection: true,
                  validator: _model.passwordFieldTextControllerValidator
                      .asValidator(context),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    alignment: AlignmentDirectional(1.0, 0.0),
                    child: InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        if (_model.emailFieldTextController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Email required!',
                              ),
                            ),
                          );
                          return;
                        }
                        await authManager.resetPassword(
                          email: _model.emailFieldTextController.text,
                          context: context,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Reset email sent successfully',
                              style: TextStyle(
                                color: FlutterFlowTheme.of(context).primaryText,
                              ),
                            ),
                            duration: Duration(milliseconds: 4000),
                            backgroundColor:
                                FlutterFlowTheme.of(context).secondary,
                          ),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: FlutterFlowTheme.of(context).labelLarge.override(
                              font: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w500,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .labelLarge
                                    .fontStyle,
                              ),
                              color: FlutterFlowTheme.of(context).primaryText,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w500,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelLarge
                                  .fontStyle,
                              lineHeight: 1.4,
                            ),
                      ),
                    ),
                  ),
                ].divide(SizedBox(height: 24.0)),
              ),
              FFButtonWidget(
                onPressed: () async {
                  // Checked before prepareAuthEvent so an empty form never
                  // starts an auth event it can't finish.
                  final problem = authFormError(
                    email: _model.emailFieldTextController.text,
                    password: _model.passwordFieldTextController.text,
                  );
                  if (problem != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(problem)),
                    );
                    return;
                  }

                  GoRouter.of(context).prepareAuthEvent();

                  final user = await authManager.signInWithEmail(
                    context,
                    _model.emailFieldTextController.text.trim(),
                    _model.passwordFieldTextController.text,
                  );
                  if (user == null) {
                    return;
                  }

                  // An existing owner who came in through the business path
                  // should land on business setup, not the map - otherwise
                  // logging in silently abandons what they set out to do.
                  // Same signupType handoff the sign-up page uses, cleared
                  // on the way out so it can't leak into a later session.
                  final wasBusiness = FFAppState().signupType == 'business';
                  FFAppState().signupType = '';
                  context.goNamedAuth(
                      wasBusiness
                          ? BusinessSetupPageWidget.routeName
                          : GoogleMapPageWidget.routeName,
                      context.mounted);
                },
                // Was 'Welcome Back!', a duplicate of the page heading. A
                // submit control should name its action.
                text: 'Log In',
                options: FFButtonOptions(
                  height: 40.0,
                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                  iconPadding:
                      EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                  color: FlutterFlowTheme.of(context).primary,
                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                        font: GoogleFonts.plusJakartaSans(
                          fontWeight: FlutterFlowTheme.of(context)
                              .titleSmall
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).titleSmall.fontStyle,
                        ),
                        // Was secondaryText, a body-text token (near-black
                        // in light mode) never meant for text on a colored
                        // fill - on the dark green button it read as
                        // near-illegible in light mode. onPrimary is white
                        // in both themes and built for exactly this.
                        color: FlutterFlowTheme.of(context).onPrimary,
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).titleSmall.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).titleSmall.fontStyle,
                      ),
                  elevation: 0.0,
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              Container(
                decoration: BoxDecoration(),
                // Was a Row of two Text widgets, which can't wrap between
                // each other and overflowed (yellow/black stripes) on
                // narrower screens or larger font scale. A single RichText
                // wraps naturally, like the signup page's reverse link does.
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Don\'t have an account? ',
                        style:
                            FlutterFlowTheme.of(context).bodyMedium.override(
                                  font: GoogleFonts.plusJakartaSans(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color: FlutterFlowTheme.of(context).secondary,
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
                      TextSpan(
                        text: 'Click Here!',
                        style:
                            FlutterFlowTheme.of(context).bodyMedium.override(
                                  font: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic,
                                  decoration: TextDecoration.underline,
                                ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => context
                              .pushNamed(CustomersignupPageWidget.routeName),
                      ),
                    ],
                  ),
                ),
              ),
              // Was Spacer(), which pushed this box to the bottom of the
              // screen - that only works inside a bounded-height flex
              // parent, and this Column now scrolls (unbounded height), so
              // it's a fixed gap instead.
              SizedBox(height: 40.0),
              Container(
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 24.0),
                  child: Container(
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14.0),
                            shape: BoxShape.rectangle,
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 8.0, 16.0, 8.0),
                            child: Container(),
                          ),
                        ),
                      ].divide(SizedBox(width: 4.0)),
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
    );
  }
}
