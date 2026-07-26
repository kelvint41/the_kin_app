import '/components/legal_section_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'terms_of_service_page_model.dart';
export 'terms_of_service_page_model.dart';

/// Create a professional, clean mobile Terms of Service legal page for a
/// premium app.
///
/// Theme & Aesthetic: - Background: Deep charcoal / solid off-black (#121212)
/// for an ultra-clean dark mode appearance. - Header Bar: A solid, elegant
/// dark forest green or deep teal rectangular header bar spanning the full
/// width at the very top of the viewport. The text inside the header bar
/// should read "Terms of Service" in crisp white, centered, bold, 18px font.
/// - Back Navigation: Include a clean white back-arrow icon on the far left
/// side of the green header bar.  Layout & Spacing: - The entire page body
/// below the header must use a ListView scroll container to allow smooth,
/// infinite vertical scrolling for dense text content. - Global Content
/// Padding: Apply a generous 16px padding on both the Left and Right sides of
/// the text elements so they never hug the edges of the device display
/// screen. - Vertical Element Spacing: Add 16px of bottom padding to each
/// section header, and 12px of bottom padding to each paragraph block to
/// create clean, breathable separation between legal clauses.  Typography &
/// Content Structure: - Section Titles (e.g., "1. Acceptance of Terms", "2.
/// Business Tickers & Intellectual Property"): Use a prominent, readable
/// medium-olive green or light gold color (#A3B899 or #D4AF37) to separate
/// sections clearly. Font weight should be Semi-Bold or Bold, sized at 16px.
/// Precede each title text string with a small vertical accent line container
/// matching the title text color. - Legal Body Text: Sized at 14px with a
/// clean line-height scale of 1.4 for excellent legibility. Font color should
/// be a high-contrast light gray or muted off-white (#E0E0E0) against the
/// black background.  Include the following placeholder text sections
/// vertically down the scroll view: 1. Acceptance of Terms: Welcome to The
/// KIN App. By creating an account or accessing our directory, you agree to
/// comply with our community standards and networking guidelines. If you do
/// not agree, please do not use our services. 2. Business Tickers &
/// Intellectual Property: All unique 4-letter business ticker symbols (e.g.,
/// $HMDN) are leased identifiers managed exclusively by the platform to
/// safely protect local independent brand identities. KINVEST GUIDANCE LLC
/// reserves the right to reassign or revoke any ticker symbol violating
/// community trademarks or rules. 3. Premium Plans & Billing: Premium growth
/// plan subscriptions provide enhanced marketing exposure across our key
/// launch regions. All transactions and financial verification processing are
/// securely handled off-device through Stripe. Subscriptions automatically
/// renew monthly unless canceled. 4. Limitation of Liability: The Kindex
/// metrics and geofenced directory coordinates are provided strictly on an
/// 'as-is' basis for community networking and visibility support. We do not
/// guarantee absolute data accuracy or commercial outcomes resulting from
/// platform usage.
class TermsOfServicePageWidget extends StatefulWidget {
  const TermsOfServicePageWidget({super.key});

  static String routeName = 'TermsOfServicePage';
  static String routePath = '/termsOfServicePage';

  @override
  State<TermsOfServicePageWidget> createState() =>
      _TermsOfServicePageWidgetState();
}

class _TermsOfServicePageWidgetState extends State<TermsOfServicePageWidget> {
  late TermsOfServicePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TermsOfServicePageModel());
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
        body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 64.0,
              decoration: BoxDecoration(
                color: Color(0xFF0D3B31),
                shape: BoxShape.rectangle,
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                child: Container(
                  child: Stack(
                    alignment: AlignmentDirectional(-1.0, -1.0),
                    children: [
                      Align(
                        alignment: AlignmentDirectional(0.0, 0.0),
                        child: Container(
                          child: FlutterFlowIconButton(
                            borderRadius: 8.0,
                            buttonSize: 40.0,
                            fillColor: Colors.transparent,
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 24.0,
                            ),
                            onPressed: () {
                              print('IconButton pressed ...');
                            },
                          ),
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional(0.0, 0.0),
                        child: Container(
                          child: Text(
                            'Terms of Service',
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
                                  fontSize: 18.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                  lineHeight: 1.4,
                                ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional(-1.0, 0.0),
                        child: InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            context.safePop();
                          },
                          child: Icon(
                            Icons.arrow_back,
                            color: FlutterFlowTheme.of(context).primaryText,
                            size: 24.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                child: SingleChildScrollView(
                  primary: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 24.0, 16.0, 24.0),
                        child: Container(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              wrapWithModel(
                                model: _model.legalSectionModel1,
                                updateCallback: () => safeSetState(() {}),
                                child: LegalSectionWidget(
                                  title: '1. Acceptance of Terms',
                                  body:
                                      'Welcome to The KIN App. By creating an account or accessing our directory, you agree to comply with our community standards and networking guidelines. If you do not agree, please do not use our services.',
                                ),
                              ),
                              wrapWithModel(
                                model: _model.legalSectionModel2,
                                updateCallback: () => safeSetState(() {}),
                                child: LegalSectionWidget(
                                  title:
                                      '2. Business Tickers & Intellectual Property',
                                  body:
                                      'All unique 4-letter business ticker symbols (e.g., \$HMDN) are leased identifiers managed exclusively by the platform to safely protect local independent brand identities. KINVEST GUIDANCE LLC reserves the right to reassign or revoke any ticker symbol violating community trademarks or rules.',
                                ),
                              ),
                              wrapWithModel(
                                model: _model.legalSectionModel3,
                                updateCallback: () => safeSetState(() {}),
                                child: LegalSectionWidget(
                                  title: '3. Premium Plans & Billing',
                                  body:
                                      'Premium growth plan subscriptions provide enhanced marketing exposure across our key launch regions. All transactions and financial verification processing are securely handled off-device through Stripe. Subscriptions automatically renew monthly unless canceled.',
                                ),
                              ),
                              wrapWithModel(
                                model: _model.legalSectionModel4,
                                updateCallback: () => safeSetState(() {}),
                                child: LegalSectionWidget(
                                  title: '4. Limitation of Liability',
                                  body:
                                      'The Kindex metrics and geofenced directory coordinates are provided strictly on an \'as-is\' basis for community networking and visibility support. We do not guarantee absolute data accuracy or commercial outcomes resulting from platform usage.',
                                ),
                              ),
                              Container(
                                height: 40.0,
                              ),
                              Text(
                                'Last Updated: October 2023',
                                textAlign: TextAlign.center,
                                style: FlutterFlowTheme.of(context)
                                    .labelSmall
                                    .override(
                                      font: GoogleFonts.plusJakartaSans(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelSmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelSmall
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontStyle,
                                      lineHeight: 1.4,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
