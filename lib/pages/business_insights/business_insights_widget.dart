import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/kindex_trend_indicator.dart';
import '/components/main_menu_button.dart';
import '/components/support_bubble_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import '/pages/kin_bottom_nav2/kin_bottom_nav2_widget.dart';
import '/services/subscription_tiers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'business_insights_model.dart';
export 'business_insights_model.dart';

/// Owner-facing analytics dashboard - first section is real KIN Quest
/// check-in data (see BusinessInsightsModel.visitsFor / firestore.rules'
/// uservisits owner-read clause). Deliberately structured as a foundation
/// rather than a one-off page: this is meant to grow into a full tiered
/// dashboard (more sections unlocking at Pro/Elite tiers), not stay a
/// single check-in counter - see the locked "More Insights" card below.
///
/// Aggregate counts only, never a list of named visitors - a business
/// owner can't read another user's profile (users/{uid} is self-only
/// readable per firestore.rules), so this can only ever show "how many",
/// not "who".
class BusinessInsightsWidget extends StatefulWidget {
  const BusinessInsightsWidget({super.key});

  static String routeName = 'BusinessInsights';
  static String routePath = '/businessInsights';

  @override
  State<BusinessInsightsWidget> createState() =>
      _BusinessInsightsWidgetState();
}

class _BusinessInsightsWidgetState extends State<BusinessInsightsWidget> {
  late BusinessInsightsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BusinessInsightsModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final businessRef = currentUserDocument?.ownedBusiness;

    if (businessRef == null) {
      return Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        appBar: AppBar(
          backgroundColor: theme.primaryBackground,
          automaticallyImplyLeading: false,
          elevation: 0.0,
          actions: [Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: MainMenuButton(),
          )],
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Set up your business to see your insights dashboard.',
                  textAlign: TextAlign.center,
                  style: theme.bodyLarge.override(color: theme.secondaryText),
                ),
                SizedBox(height: 24.0),
                FFButtonWidget(
                  onPressed: () =>
                      context.pushNamed(BusinessSetupPageWidget.routeName),
                  text: 'Set Up Business',
                  options: FFButtonOptions(
                    height: 44.0,
                    padding:
                        EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                    color: theme.secondary,
                    textStyle:
                        theme.titleSmall.override(color: Colors.white),
                    elevation: 0.0,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const KinBottomNav2Widget(),
      );
    }

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.primaryBackground,
      floatingActionButton: const SupportBubbleWidget(),
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        automaticallyImplyLeading: false,
        title: Text(
          'Business Insights',
          style: theme.headlineMedium.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            color: theme.primaryText,
            letterSpacing: 0.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        elevation: 0.0,
        actions: [Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: MainMenuButton(),
        )],
      ),
      body: SafeArea(
        top: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel(theme, 'KIN Quest Check-Ins'),
              SizedBox(height: 10.0),
              FutureBuilder<List<UservisitsRecord>>(
                future: _model.visitsFor(businessRef),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(theme.primary),
                        ),
                      ),
                    );
                  }
                  final visits = snapshot.data!;
                  final uniqueCustomers = visits
                      .map((v) => v.userRef?.path)
                      .whereType<String>()
                      .toSet()
                      .length;
                  final thirtyDaysAgo =
                      DateTime.now().subtract(const Duration(days: 30));
                  final last30d = visits
                      .where((v) =>
                          v.visitTimestamp != null &&
                          v.visitTimestamp!.isAfter(thirtyDaysAgo))
                      .length;

                  return Row(
                    children: [
                      Expanded(
                        child: _statCard(
                            theme, 'Total Check-Ins', '${visits.length}'),
                      ),
                      SizedBox(width: 12.0),
                      Expanded(
                        child: _statCard(theme, 'Unique Customers',
                            '$uniqueCustomers'),
                      ),
                      SizedBox(width: 12.0),
                      Expanded(
                        child: _statCard(
                            theme, 'Check-Ins (30d)', '$last30d'),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 28.0),
              _sectionLabel(theme, 'Kindex Performance'),
              SizedBox(height: 10.0),
              StreamBuilder<BusinessesRecord>(
                stream: BusinessesRecord.getDocument(businessRef),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(theme.primary),
                        ),
                      ),
                    );
                  }
                  final business = snapshot.data!;
                  final rawTier = business.subscriptionTier;
                  final tierName = rawTier.isEmpty ? 'Community' : rawTier;
                  if (!tierAtLeast(tierName, 'Premium Local')) {
                    return _lockedCard(
                      theme,
                      'Your Kindex Score trend unlocks at Premium Local '
                      'and above.',
                    );
                  }
                  return Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: theme.secondaryBackground,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: theme.alternate, width: 1.0),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                business.kindexScore.round().toString(),
                                style: theme.headlineSmall.override(
                                  font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold),
                                  color: theme.primaryText,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.0),
                              Text(
                                'Kindex Score',
                                style: theme.labelSmall.override(
                                  color: theme.secondaryText,
                                  letterSpacing: 0.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        KindexTrendIndicator(
                            velocity: business.kindexVelocity),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 28.0),
              _sectionLabel(theme, 'More Insights'),
              SizedBox(height: 10.0),
              _lockedCard(
                theme,
                'Revenue trends and AI-generated weekly summaries are '
                'still in development.',
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const KinBottomNav2Widget(),
    );
  }

  Widget _sectionLabel(FlutterFlowTheme theme, String text) => Text(
        text,
        style: theme.titleSmall.override(
          font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
          color: theme.primaryText,
          letterSpacing: 0.0,
          fontWeight: FontWeight.bold,
        ),
      );

  Widget _statCard(FlutterFlowTheme theme, String label, String value) =>
      Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: theme.alternate, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.headlineSmall.override(
                font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                color: theme.primaryText,
                letterSpacing: 0.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.0),
            Text(
              label,
              style: theme.labelSmall.override(
                color: theme.secondaryText,
                letterSpacing: 0.0,
              ),
            ),
          ],
        ),
      );

  Widget _lockedCard(FlutterFlowTheme theme, String body) => Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: theme.alternate, width: 1.0),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline_rounded,
                color: theme.secondaryText, size: 20.0),
            SizedBox(width: 12.0),
            Expanded(
              child: Text(
                body,
                style: theme.bodySmall.override(
                  color: theme.secondaryText,
                  lineHeight: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
}
