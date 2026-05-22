import '/components/policy_section_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'terms_of_service_page_model.dart';
export 'terms_of_service_page_model.dart';

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
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          title: Text(
            'Terms of Service',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.plusJakartaSans(
                    fontWeight:
                        FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                  ),
                  color: Colors.white,
                  fontSize: 22.0,
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                  fontStyle:
                      FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                ),
          ),
          actions: [],
          centerTitle: false,
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              wrapWithModel(
                model: _model.policySectionModel1,
                updateCallback: () => safeSetState(() {}),
                child: PolicySectionWidget(
                  title: '1. Acceptance of Terms',
                  content:
                      'Welcome to The KIN App. By creating an account or accessing our directory, you agree to comply with our community standards and networking guidelines. If you do not agree, please do not use our services.',
                ),
              ),
              wrapWithModel(
                model: _model.policySectionModel2,
                updateCallback: () => safeSetState(() {}),
                child: PolicySectionWidget(
                  title: '2. Business Tickers & Intellectual Property',
                  content:
                      'All unique 4-letter business ticker symbols (e.g., \$HMDN) are leased identifiers managed exclusively by the platform to safely protect local independent brand identities. KINVEST GUIDANCE LLC reserves the right to reassign or revoke any ticker symbol violating community trademarks or rules.',
                ),
              ),
              wrapWithModel(
                model: _model.policySectionModel3,
                updateCallback: () => safeSetState(() {}),
                child: PolicySectionWidget(
                  title: '3. Premium Plans & Billing',
                  content:
                      'Premium growth plan subscriptions provide enhanced marketing exposure across our key launch regions. All transactions and financial verification processing are securely handled off-device through Stripe. Subscriptions automatically renew monthly unless canceled.',
                ),
              ),
              wrapWithModel(
                model: _model.policySectionModel4,
                updateCallback: () => safeSetState(() {}),
                child: PolicySectionWidget(
                  title: '4. Limitation of Liability',
                  content:
                      'The Kindex metrics and geofenced directory coordinates are provided strictly on an \'as-is\' basis for community networking and visibility support. We do not guarantee absolute data accuracy or commercial outcomes resulting from platform usage.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
