import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/kin_back_button.dart';
import '/components/kindex_gauge.dart';
import '/components/kindex_score_history_row_widget.dart';
import '/components/kindex_trend_indicator.dart';
import '/components/main_menu_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/kin_bottom_nav2/kin_bottom_nav2_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'kindex_score_history_model.dart';
export 'kindex_score_history_model.dart';

/// Daily KINDEX score ledger - part 2 of the KINDEX visibility suite (see
/// firestore.rules' kindex_score_history rule for part 1). One screen
/// serves both sides of the app: passing [businessDocument] renders the
/// owner's view of that business's history; leaving it null renders the
/// signed-in customer's own history. There is no third combination - an
/// owner viewing another business's history isn't something firestore.rules
/// allows (the read rule is scoped to that business's own owner_ref), so
/// this never needs to guard against it beyond what the rule already does.
///
/// Reached by pushNamed only (Business Insights' Kindex Performance card,
/// Customer Profile's KINDEX Score metric card), never from the bottom nav
/// - hence the KinBackButton rather than automaticallyImplyLeading.
class KindexScoreHistoryWidget extends StatefulWidget {
  const KindexScoreHistoryWidget({super.key, this.businessDocument});

  final DocumentReference? businessDocument;

  static String routeName = 'KindexScoreHistory';
  static String routePath = '/kindexScoreHistory';

  @override
  State<KindexScoreHistoryWidget> createState() =>
      _KindexScoreHistoryWidgetState();
}

class _KindexScoreHistoryWidgetState extends State<KindexScoreHistoryWidget> {
  late KindexScoreHistoryModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => KindexScoreHistoryModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final businessRef = widget.businessDocument;
    final businessMode = businessRef != null;
    final userRef = currentUserReference;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 0.0, 0.0),
          child: KinBackButton(floating: true),
        ),
        title: Text(
          businessMode ? 'Kindex Score History' : 'My Kindex History',
          style: theme.headlineSmall.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            color: theme.primaryText,
            letterSpacing: 0.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        elevation: 0.0,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: MainMenuButton(),
          ),
        ],
      ),
      body: SafeArea(
        top: true,
        child: businessMode
            ? _businessBody(theme, businessRef)
            : _customerBody(theme, userRef),
      ),
      bottomNavigationBar: const KinBottomNav2Widget(),
    );
  }

  Widget _businessBody(FlutterFlowTheme theme, DocumentReference businessRef) {
    return StreamBuilder<BusinessesRecord>(
      stream: BusinessesRecord.getDocument(businessRef),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _loadingIndicator(theme);
        }
        final business = snapshot.data!;
        return _historyList(
          theme,
          header: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KindexGauge(
                score: business.kindexScore,
                maxScore: business.isPremium ? 900 : 750,
                label: 'Current Kindex Score',
              ),
              SizedBox(height: 10.0),
              KindexTrendIndicator(velocity: business.kindexVelocity),
            ],
          ),
          future: _model.historyFor(businessRef: businessRef),
        );
      },
    );
  }

  Widget _customerBody(FlutterFlowTheme theme, DocumentReference? userRef) {
    if (userRef == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Sign in to see your Kindex Score history.',
            textAlign: TextAlign.center,
            style: theme.bodyLarge.override(color: theme.secondaryText),
          ),
        ),
      );
    }
    return FutureBuilder<List<KindexScoresRecord>>(
      future: queryKindexScoresRecordOnce(
        queryBuilder: (q) => q.where('user_ref', isEqualTo: userRef),
        limit: 1,
      ),
      builder: (context, scoreSnapshot) {
        if (!scoreSnapshot.hasData) {
          return _loadingIndicator(theme);
        }
        final scores = scoreSnapshot.data!;
        final currentScore = scores.isEmpty ? 0.0 : scores.first.score;
        final isTrendingUp =
            scores.isEmpty || !scores.first.hasIsTrendingUp()
                ? null
                : scores.first.isTrendingUp;
        return _historyList(
          theme,
          header: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KindexGauge(
                score: currentScore,
                maxScore: 850,
                label: 'Current Kindex Score',
              ),
              SizedBox(height: 10.0),
              KindexTrendIndicator.fromTrend(isTrendingUp: isTrendingUp),
            ],
          ),
          future: _model.historyFor(userRef: userRef),
        );
      },
    );
  }

  Widget _historyList(
    FlutterFlowTheme theme, {
    required Widget header,
    required Future<List<KindexScoreHistoryRecord>> future,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: header),
          SizedBox(height: 28.0),
          Text(
            'Daily Ledger',
            style: theme.titleSmall.override(
              font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              color: theme.primaryText,
              letterSpacing: 0.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10.0),
          FutureBuilder<List<KindexScoreHistoryRecord>>(
            future: future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: _loadingIndicator(theme),
                );
              }
              final entries = snapshot.data!;
              if (entries.isEmpty) {
                return Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: theme.secondaryBackground,
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(color: theme.alternate, width: 1.0),
                  ),
                  child: Text(
                    // The nightly job runs once a day, so a brand-new
                    // account or business has nothing here until tomorrow
                    // night - not an error state, just too soon.
                    'Your score history starts tracking after tonight\'s '
                    'update.',
                    style: theme.bodySmall.override(
                      color: theme.secondaryText,
                      lineHeight: 1.4,
                    ),
                  ),
                );
              }
              return Column(
                children: entries
                    .map((entry) => KindexScoreHistoryRow(entry: entry))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _loadingIndicator(FlutterFlowTheme theme) => Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
          ),
        ),
      );
}
