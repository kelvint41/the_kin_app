import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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
        // Theme tokens, not the hardcoded 0xFF121212 / 0xFF0D3B31 this page
        // was built with. Those two colours belonged to no palette in the
        // app - the forest-green header in particular appeared nowhere else
        // - so the one screen everyone is asked to read before agreeing to
        // anything looked like it came from a different product.
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SafeArea, because a fixed 64px bar with no inset put the title
            // under the status bar and the Dynamic Island ate the middle of
            // it. The header also stacked two back buttons - a centred
            // FlutterFlowIconButton and a left-aligned InkWell - one of
            // which sat directly on top of the title.
            SafeArea(
              bottom: false,
              child: Container(
                height: 56.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  border: Border(
                    bottom: BorderSide(
                      color: FlutterFlowTheme.of(context).alternate,
                      width: 1.0,
                    ),
                  ),
                ),
                child: Stack(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  children: [
                    Align(
                      alignment: AlignmentDirectional(0.0, 0.0),
                      child: Text(
                        'Terms of Service',
                        style: FlutterFlowTheme.of(context).titleMedium.override(
                              font: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold),
                              color: FlutterFlowTheme.of(context).primaryText,
                              fontSize: 18.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional(-1.0, 0.0),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(4, 0, 0, 0),
                        child: FlutterFlowIconButton(
                          borderRadius: 20.0,
                          buttonSize: 44.0,
                          fillColor: Colors.transparent,
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: FlutterFlowTheme.of(context).accentOnSurface,
                            size: 24.0,
                          ),
                          onPressed: () => context.safePop(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                primary: false,
                padding: EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _intro(context),
                    _section(context, '1. Accepting these Terms',
                        'The KIN App is a directory of Black-owned businesses and a '
                        'community space called The Exchange. These Terms apply to '
                        'everyone who uses it - customers browsing the directory and '
                        'business owners listing on it alike. By creating an account '
                        'or using the app, you agree to them. If you do not agree, '
                        'please do not use the app.'),
                    _section(context, '2. Your account',
                        'You need one KIN account to use the app, and you are '
                        'responsible for what happens under it. Keep your password to '
                        'yourself.\n\n'
                        'We never see your password - it is stored only in encrypted '
                        'form by our authentication provider, and nobody at KIN can '
                        'read it or tell you what it is. If you are locked out, use '
                        '"Forgot Password?" on the sign-in screen to set a new one by '
                        'email. That is the only way in, by design.'),
                    _section(context, '3. The Exchange: how we expect you to behave',
                        'The Exchange is for supporting local businesses and the '
                        'people behind them. Anyone with a KIN account can read it, '
                        'and anyone can post - you do not need to own a business.\n\n'
                        'Before you post for the first time you will be asked to '
                        'agree to these Terms. When you post, you agree not to: '
                        'harass, threaten or abuse anyone; post spam or repetitive '
                        'promotional content; make false claims about a business or '
                        'its owner; post content that is unlawful, hateful, or that '
                        'you do not have the right to share.\n\n'
                        'You keep ownership of what you post. You give us permission '
                        'to display it in the app so that other members can see it. '
                        'You can delete your own posts at any time. We may remove '
                        'content or suspend an account that breaks these rules.'),
                    _section(context, '4. Business listings and claiming',
                        'Many listings are imported from public and certification '
                        'sources, so details may be incomplete or out of date until an '
                        'owner claims the listing.\n\n'
                        'If you claim a business you confirm you are authorised to act '
                        'for it and that the information you give us is accurate. '
                        'Claims are reviewed before they are approved, and we may '
                        'decline or reverse a claim.'),
                    _section(context, '5. Business tickers',
                        'Each business can hold a unique 4-letter ticker symbol (for '
                        'example \$HMDN). Tickers are identifiers we license to you '
                        'for use in the app - you do not own them, and holding one '
                        'gives you no trademark rights. KINVEST GUIDANCE LLC may '
                        'reassign or revoke a ticker that infringes someone else\'s '
                        'mark or breaks these Terms.'),
                    _section(context, '6. Subscriptions and billing',
                        'Business owners can subscribe to a paid growth plan for extra '
                        'marketing exposure and features.\n\n'
                        'Subscriptions are sold and processed through the Apple App '
                        'Store or Google Play, depending on your device. KIN never '
                        'receives or stores your card details. Plans renew '
                        'automatically for the period you chose unless you cancel, and '
                        'you cancel or request refunds through your Apple or Google '
                        'account, not through us.'),
                    _section(context, '7. KINDEX scores and directory data',
                        'KINDEX scores, business locations and other directory data '
                        'are provided as-is, to help people find and support local '
                        'businesses. They are calculated from activity in the app and '
                        'are not a rating of quality, creditworthiness, or a '
                        'recommendation to spend money anywhere.\n\n'
                        'We do not guarantee that a listing is accurate or current, and '
                        'we do not promise any commercial outcome from using the app.'),
                    _section(context, '8. Changes to these Terms',
                        'We may update these Terms. When we make a change that affects '
                        'what you have agreed to, you will be asked to review and '
                        'accept the new version before you post in The Exchange again. '
                        'Continuing to use the app after a change means you accept it.'),
                    _section(context, '9. Contact',
                        'Questions about these Terms can be sent to '
                        'kelvin@kinvestguidance.com.'),
                    _lastUpdated(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The short framing that used to be missing entirely - the page opened
  /// straight into "1. Acceptance of Terms" with no indication of who the
  /// document was for or how long it would take to read.
  Widget _intro(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 28),
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: theme.alternate, width: 1.0),
        ),
        child: Text(
          'The plain-English version: browse freely, be decent to people in '
          'The Exchange, and only claim a business that is actually yours. '
          'The detail is below.',
          style: theme.bodyMedium.override(
            font: GoogleFonts.plusJakartaSans(),
            color: theme.secondaryText,
            letterSpacing: 0.0,
            lineHeight: 1.5,
          ),
        ),
      ),
    );
  }

  /// One numbered clause.
  ///
  /// Replaces LegalSectionWidget, which needed a model instance per section
  /// - the page had exactly four because the model declared exactly four,
  /// which is a poor reason for a legal document to be four clauses long.
  Widget _section(BuildContext context, String title, String body) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 3.0,
                height: 18.0,
                decoration: BoxDecoration(
                  color: theme.accentOnSurface,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(10, 0, 0, 0),
                  child: Text(
                    title,
                    style: theme.titleSmall.override(
                      font: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold),
                      color: theme.accentOnSurface,
                      fontSize: 16.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(13, 10, 0, 0),
            child: Text(
              body,
              style: theme.bodyMedium.override(
                font: GoogleFonts.plusJakartaSans(),
                color: theme.primaryText,
                letterSpacing: 0.0,
                lineHeight: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Read from legal_config/exchange_terms rather than hardcoded.
  ///
  /// The page said "Last Updated: October 2023" - close to three years
  /// stale, and contradicting the current_version the posting rule actually
  /// enforces. Sourcing it from the same document that gates posting means
  /// the two cannot drift apart again: bumping current_version to re-prompt
  /// everyone also updates the date they see.
  Widget _lastUpdated(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('legal_config')
          .doc('exchange_terms')
          .get(),
      builder: (context, snapshot) {
        final version = snapshot.data?.data()?['current_version'];
        return Text(
          version is String && version.isNotEmpty
              ? 'Last updated: $version'
              : 'Last updated: -',
          textAlign: TextAlign.center,
          style: theme.labelSmall.override(
            font: GoogleFonts.plusJakartaSans(),
            color: theme.secondaryText,
            letterSpacing: 0.0,
          ),
        );
      },
    );
  }
}
