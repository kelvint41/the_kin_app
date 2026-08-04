import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/launch_action_widget.dart';
import '/components/main_menu_button.dart';
import '/components/metric_card3_widget.dart';
import '/components/marketplace_item_card_widget.dart';
import '/components/business_image_widget.dart';
import '/components/image_upload_button.dart';
import '/components/feedback_sheet_widget.dart';
import '/components/promo_card_widget.dart';
import '/components/edit_bio_sheet.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/kin_bottom_nav2/kin_bottom_nav2_widget.dart';
import '/services/engagement_stats.dart';
import '/services/kin_services.dart';
import 'dart:ui';
import '/index.dart';
import '/services/feature_flags.dart';
import '/services/walkthrough_runner.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'customer_profile_page_model.dart';
export 'customer_profile_page_model.dart';

/// The three "Personal Milestones" figures, derived from the signed-in user's
/// own activity. See lib/services/engagement_stats.dart for the arithmetic.
class _MilestoneStats {
  const _MilestoneStats({
    required this.streakDays,
    required this.reviewCount,
    required this.kindexScore,
    required this.visitCount30d,
    this.isTrendingUp,
  });

  final int streakDays;
  final int reviewCount;
  final double? kindexScore;

  /// GPS-verified check-ins (uservisits) in the trailing 30 days - a real
  /// count of businesses physically visited, not the day-streak above.
  final int visitCount30d;

  /// Direction of the user's Kindex score, straight from the
  /// KindexScores row's is_trending_up. Null when they have no score yet,
  /// so the card shows no arrow rather than guessing one.
  final bool? isTrendingUp;
}

/// A Connection Stream promotion, already joined to its business.
class _PromoView {
  const _PromoView({
    required this.businessName,
    required this.deal,
    required this.countdown,
  });

  final String businessName;
  final String deal;
  final String countdown;
}

/// Generate a vibrant, premium dark-mode dashboard page named
/// "CustomerProfile_Engage" that gamifies community support.
///
/// The design must use deep-charcoal backgrounds with polished, glowing gold
/// and amber accents to match an existing luxury brand identity.
///
/// The screen layout must be a dynamic, scrollable page built with these
/// primary vertical blocks:
///
/// 1. Dynamic Identity & Level-Up Header:
/// - A prominent circular profile photo placeholder flanked by user name text
/// and location (San Antonio, TX).
/// - A prominent horizontal "Kin Score Progress Bar" (ProgressLinear widget).
/// - This bar visually maps a variable `CurrentScore` text against a fixed
/// `NextLevel` goal (e.g., "250/500 pts to Silver Tier"). Label this entire
/// section "Your Community Impact Journey."
///
/// 2. The Engagement Launchpad (Action Row):
/// - A row containing three identical, clean utility buttons styled as small
/// action cards with icons.
/// - Button 1: Icon "Map/Explore" with label "Explore Map".
/// - Button 2: Icon "Group/Feed" with label "The Exchange".
/// - Button 3: Icon "Rate/Comment" with label "Quick Review".
///
/// 3. My Analytics & Milestones:
/// - A horizontal scrolling row (ListView) containing high-impact gamified
/// metric cards.
/// - Card 1: Icon "Fire" with label "🔥 7-Day Support Streak" and a large
/// counter.
/// - Card 2: Icon "Award/Medal" with label "🏅 Milestones Unlocked" (e.g., "5
/// Total Reviews").
///
/// 4. Exclusive "Past Favorites" Promotion Feed:
/// - A clean vertical ListView displaying prioritized, targeted flash
/// notifications from businesses the user has historical check-in data for.
/// - Each list card displays the business name, logo, promotional message
/// (e.g., "Exclusive: Free item with your next visit!"), and a countdown
/// timer.
/// - The design of this feed must imply it is an exclusive, priority
/// connection stream driven by backend verification filters matching user
/// check-in history and premium business tiers.
///
/// Ensure all layout components use strict grid alignment, balanced padding
/// (16px standard), consistent modern typography hierarchy, and glowing
/// shadow effects on progress bars and buttons to make them pop.
class CustomerProfilePageWidget extends StatefulWidget {
  const CustomerProfilePageWidget({
    super.key,
    this.businessRef,
    this.scrollToMilestones = false,
  });

  final DocumentReference? businessRef;

  /// Opens the page scrolled to "Personal Milestones" instead of the top.
  ///
  /// Set by the bottom nav's Loyalty tab. Loyalty has no page of its own -
  /// the streak, review count and Kindex score on this page are the whole
  /// of it - so rather than send that tab to CommunityPrestige, which
  /// renders invented figures and reads nothing from Firestore, it lands
  /// here on the real ones.
  final bool scrollToMilestones;

  static String routeName = 'CustomerProfilePage';
  static String routePath = '/customerProfilePage';

  @override
  State<CustomerProfilePageWidget> createState() =>
      _CustomerProfilePageWidgetState();
}

class _CustomerProfilePageWidgetState extends State<CustomerProfilePageWidget> {
  late CustomerProfilePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Kicked off once in initState rather than inside build - a FutureBuilder
  // handed a future created during build re-queries on every rebuild.
  late final Future<_MilestoneStats> _statsFuture;
  late final Future<List<_PromoView>> _promosFuture;
  late final Future<List<BusinessItemsRecord>> _recommendedFuture;

  /// Anchors the "Personal Milestones" block for [_scrollToMilestones].
  final _milestonesKey = GlobalKey();

  /// Anchors the KINDEX Score card for the 'kindex_explainer' walkthrough
  /// (see WalkthroughRunner) - explains what the score means and that it
  /// moves with real engagement, shown once the first time a signed-in
  /// customer sees their own score here.
  final _kindexScoreKey = GlobalKey();
  late final WalkthroughRunner _walkthroughRunner;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CustomerProfilePageModel());
    _statsFuture = _loadStats();
    _promosFuture = _loadPromos();
    _recommendedFuture = currentUserReference == null
        ? Future.value(<BusinessItemsRecord>[])
        : KinServices.fetchRecommendedItems(userRef: currentUserReference!);

    // Constructed here, not as a lazy `late final` initializer only
    // touched inside the post-frame callback below - its constructor
    // registers a ShowcaseView synchronously, which the Showcase widget
    // wrapping the KINDEX Score card needs to already exist by the time
    // this State's first build() runs. See WalkthroughRunner's
    // constructor doc comment.
    _walkthroughRunner = WalkthroughRunner(
      walkthroughKey: 'kindex_explainer',
      targetKeys: {'kindex_score': _kindexScoreKey},
    );

    if (widget.scrollToMilestones) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToMilestones();
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_walkthroughRunner.maybeStart(
        context: context,
        userRef: currentUserReference,
        seenWalkthroughs: currentUserDocument?.seenWalkthroughs ?? const [],
        onStepsLoaded: () => safeSetState(() {}),
      ));
    });
  }

  /// Brings the milestones block into view once the first frame has laid
  /// the page out.
  ///
  /// Guarded on `mounted` and on the key having a context: the user can
  /// leave before the frame lands, and the block sits below a FutureBuilder
  /// whose loading state is shorter than this page but not guaranteed to
  /// be, so the anchor may not be attached yet. Either way, failing to
  /// scroll just leaves the page at the top, which is the old behaviour.
  void _scrollToMilestones() {
    if (!mounted) return;
    final anchor = _milestonesKey.currentContext;
    if (anchor == null) return;
    Scrollable.ensureVisible(
      anchor,
      duration: Duration(milliseconds: 400),
      curve: Curves.easeOut,
      alignment: 0.0,
    );
  }

  /// Reads the signed-in user's activity, reviews and Kindex score.
  ///
  /// Each of the three is independent, so a failure in one (a missing index,
  /// a rules denial) should not blank the other two - they are caught
  /// separately and degrade to a zero/null rather than throwing the whole
  /// card row away.
  Future<_MilestoneStats> _loadStats() async {
    final userRef = currentUserReference;
    if (userRef == null) {
      return const _MilestoneStats(
          streakDays: 0, reviewCount: 0, kindexScore: null, visitCount30d: 0);
    }

    Future<T> orDefault<T>(Future<T> future, T fallback) =>
        future.catchError((_) => fallback);

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    final results = await Future.wait([
      orDefault(
        queryActivityLogsRecordOnce(
          queryBuilder: (q) => q.where('user_ref', isEqualTo: userRef),
        ),
        <ActivityLogsRecord>[],
      ),
      orDefault(
        queryReviewsRecordOnce(
          queryBuilder: (q) => q.where('user_ref', isEqualTo: userRef),
        ),
        <ReviewsRecord>[],
      ),
      orDefault(
        queryKindexScoresRecordOnce(
          queryBuilder: (q) => q.where('user_ref', isEqualTo: userRef),
          limit: 1,
        ),
        <KindexScoresRecord>[],
      ),
      orDefault(
        queryUservisitsRecordOnce(
          queryBuilder: (q) => q
              .where('user_ref', isEqualTo: userRef)
              .where('visit_timestamp', isGreaterThanOrEqualTo: thirtyDaysAgo),
        ),
        <UservisitsRecord>[],
      ),
    ]);

    final activity = results[0] as List<ActivityLogsRecord>;
    final reviews = results[1] as List<ReviewsRecord>;
    final scores = results[2] as List<KindexScoresRecord>;
    final visits = results[3] as List<UservisitsRecord>;

    final timestamps = activity
        .map((a) => a.timestamp)
        .whereType<DateTime>()
        .toList(growable: false);

    return _MilestoneStats(
      streakDays: supportStreakDays(timestamps, now: DateTime.now()),
      reviewCount: reviews.length,
      kindexScore: scores.isEmpty ? null : scores.first.score,
      visitCount30d: visits.length,
      isTrendingUp: scores.isEmpty || !scores.first.hasIsTrendingUp()
          ? null
          : scores.first.isTrendingUp,
    );
  }

  /// Reads live promotions and joins each to the business offering it.
  ///
  /// Promotions without an expiry, already lapsed, or whose business_ref is
  /// missing or dangling are dropped: the card's whole premise is a named
  /// business making a time-limited offer, and it cannot honestly render
  /// without both halves.
  Future<List<_PromoView>> _loadPromos() async {
    final List<ExchangePromotionsRecord> promotions;
    try {
      promotions = await queryExchangePromotionsRecordOnce(limit: 20);
    } catch (_) {
      return const [];
    }

    final now = DateTime.now();
    final views = <_PromoView>[];
    for (final promo in promotions) {
      final countdown = countdownLabel(promo.expiresAt, now: now);
      if (countdown == null) continue;
      final businessRef = promo.businessRef;
      if (businessRef == null) continue;

      BusinessesRecord business;
      try {
        business = await BusinessesRecord.getDocumentOnce(businessRef);
      } catch (_) {
        continue;
      }
      if (business.businessName.isEmpty) continue;

      views.add(_PromoView(
        businessName: business.businessName,
        deal: promo.body.isNotEmpty ? promo.body : promo.title,
        countdown: countdown,
      ));
    }
    return views;
  }

  @override
  void dispose() {
    _walkthroughRunner.dispose();
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
        // Only the header block above is SafeArea-protected - once scrolled
        // far enough that later content (e.g. the "Engagement Launchpad"
        // cards) becomes the top-most thing on screen, it renders straight
        // behind the status bar's time/battery icons with no scrim to
        // separate them. This pinned strip stays above the scroll view at
        // all times so scrolled content always stops below it.
        body: Stack(
          children: [
            SingleChildScrollView(
              primary: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The header was a 100x100 Container holding a 120x120 image,
                  // outside any SafeArea - so the logo overflowed its box and ran
                  // under the status bar and notch. The Stack now sizes to the
                  // logo, and SafeArea keeps it clear of the inset.
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(8.0, 8.0, 8.0, 0.0),
                      child: Stack(
                        alignment: AlignmentDirectional(0.0, 0.0),
                        children: [
                          // The page's own spec called for "a prominent circular
                          // profile photo" and it was the KIN logo asset for
                          // everyone - users.photo_url was only ever populated by
                          // Google sign-in, and nothing in the app could set it,
                          // so anyone who signed up with an email had no picture
                          // and no way to add one.
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999.0),
                                child: SizedBox(
                                  width: 104.0,
                                  height: 104.0,
                                  child: BusinessImage(
                                    imageUrl: currentUserPhoto,
                                    width: 104.0,
                                    height: 104.0,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 10.0, 0.0, 0.0),
                                child: ImageUploadButton(
                                  label: currentUserPhoto.isEmpty
                                      ? 'Add your photo'
                                      : 'Change photo',
                                  onUploaded: (url) async {
                                    final ref = currentUserReference;
                                    if (ref == null) return;
                                    await ref.update({'photo_url': url});
                                    if (mounted) safeSetState(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                          Align(
                            alignment: AlignmentDirectional(1.0, -1.0),
                            child: MainMenuButton(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (currentUserDocument?.displayName.isNotEmpty ?? false)
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(24.0, 8.0, 24.0, 0.0),
                      child: Text(
                        currentUserDocument!.displayName,
                        textAlign: TextAlign.center,
                        style: FlutterFlowTheme.of(context).headlineSmall,
                      ),
                    ),
                  _bioSection(context),
                  Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Engagement Launchpad',
                          style: FlutterFlowTheme.of(context)
                              .titleSmall
                              .override(
                                font: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.bold,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .fontStyle,
                              ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 1,
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  context
                                      .pushNamed(GoogleMapPageWidget.routeName);
                                },
                                child: wrapWithModel(
                                  model: _model.launchActionModel1,
                                  updateCallback: () => safeSetState(() {}),
                                  child: LaunchActionWidget(
                                    icon: Icon(
                                      Icons.map_rounded,
                                      // Was a hardcoded bright yellow - this card
                                      // fills with secondaryBackground (white in
                                      // light mode), so that read at ~1.4:1 and
                                      // was nearly invisible. Same fix as the
                                      // Executive Dashboard card below.
                                      color: FlutterFlowTheme.of(context)
                                          .accentOnSurface,
                                      size: 28.0,
                                    ),
                                    label: 'Explore Map',
                                  ),
                                ),
                              ),
                            ),
                            // Hidden while the social layer is unfinished; the
                            // route is gated too (nav.dart).
                            if (FeatureFlags.exchangeEnabled)
                              Expanded(
                                flex: 1,
                                child: InkWell(
                                  splashColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () async {
                                    context.pushNamed(
                                      TheExchangeWidget.routeName,
                                      queryParameters: {
                                        'businessRef': serializeParam(
                                          widget!.businessRef,
                                          ParamType.DocumentReference,
                                        ),
                                      }.withoutNulls,
                                    );
                                  },
                                  child: wrapWithModel(
                                    model: _model.launchActionModel2,
                                    updateCallback: () => safeSetState(() {}),
                                    child: LaunchActionWidget(
                                      icon: Icon(
                                        Icons.groups_rounded,
                                        color: FlutterFlowTheme.of(context)
                                            .accentOnSurface,
                                        size: 28.0,
                                      ),
                                      label: 'The Exchange',
                                    ),
                                  ),
                                ),
                              ),
                            // Was a third card pointing at CommunityPrestigeWidget
                            // - the v2/v3 rewards mockup, which reads nothing from
                            // Firestore. This was its third entry point, after the
                            // hamburger menu and the bottom nav's Loyalty tab.
                            //
                            // In its place, the admin route to the Executive
                            // Dashboard. That page already existed and already
                            // self-guards on isAdmin, but its only link lived deep
                            // inside Owner Profile - which returns early for
                            // anyone who doesn't own a business, so an admin
                            // without one could not reach the dashboard at all,
                            // and an admin with one had to scroll past Get
                            // Support to find it. This puts it one tap from the
                            // profile, and renders for nobody else.
                            if (currentUserDocument?.isAdmin == true)
                              Expanded(
                                flex: 1,
                                child: InkWell(
                                  splashColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () async {
                                    context.pushNamed(
                                        ExecutiveDashboardWidget.routeName);
                                  },
                                  child: wrapWithModel(
                                    model: _model.launchActionModel3,
                                    updateCallback: () => safeSetState(() {}),
                                    child: LaunchActionWidget(
                                      icon: Icon(
                                        Icons.insights_rounded,
                                        color: FlutterFlowTheme.of(context)
                                            .accentOnSurface,
                                        size: 28.0,
                                      ),
                                      label: 'Executive Dashboard',
                                    ),
                                  ),
                                ),
                              ),
                          ].divide(SizedBox(width: 16.0)),
                        ),
                      ].divide(SizedBox(height: 16.0)),
                    ),
                  ),
                  Column(
                    key: _milestonesKey,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              24.0, 24.0, 0.0, 0.0),
                          child: Container(
                            child: Text(
                              'Personal Milestones',
                              style: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Container(
                                // These three were the literals '14 🔥',
                                // '5 Reviews' and 'Top 5%', so every account saw
                                // the same numbers regardless of what it had
                                // done. They now come from the user's own
                                // activity_logs, reviews and KindexScores rows.
                                child: FutureBuilder<_MilestoneStats>(
                                  future: _statsFuture,
                                  builder: (context, snapshot) {
                                    final stats = snapshot.data;
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        wrapWithModel(
                                          model: _model.metricCardModel1,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: MetricCard3Widget(
                                            icon: Icon(
                                              Icons
                                                  .local_fire_department_rounded,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              size: 20.0,
                                            ),
                                            tint: Color(0xFFFF8C00),
                                            label: 'Support Streak',
                                            value: stats == null
                                                ? '--'
                                                : '${stats.streakDays} 🔥',
                                          ),
                                        ),
                                        wrapWithModel(
                                          model: _model.metricCardModel2,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: MetricCard3Widget(
                                            icon: Icon(
                                              Icons.workspace_premium_rounded,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              size: 20.0,
                                            ),
                                            tint: Color(0xFFFFD700),
                                            label: 'Milestones Unlocked',
                                            value: stats == null
                                                ? '--'
                                                : reviewMilestoneLabel(
                                                    stats.reviewCount),
                                          ),
                                        ),
                                        Showcase(
                                          key: _kindexScoreKey,
                                          scope: _walkthroughRunner.walkthroughKey,
                                          title: _walkthroughRunner
                                                  .stepFor('kindex_score')
                                                  ?.title ??
                                              'KINDEX Score',
                                          description: _walkthroughRunner
                                                  .stepFor('kindex_score')
                                                  ?.body ??
                                              'Your KINDEX score reflects real '
                                              'engagement with Black-owned '
                                              'businesses - it grows with '
                                              'activity and can decrease over '
                                              'time if you go quiet, so keep '
                                              'showing up to keep it climbing.',
                                          child: wrapWithModel(
                                            model: _model.metricCardModel3,
                                            updateCallback: () =>
                                                safeSetState(() {}),
                                            child: MetricCard3Widget(
                                              icon: Icon(
                                                Icons
                                                    .volunteer_activism_rounded,
                                                color: FlutterFlowTheme.of(
                                                        context)
                                                    .primaryText,
                                                size: 20.0,
                                              ),
                                              tint: Color(0xFFFFD700),
                                              label: 'KINDEX Score',
                                              value: stats == null
                                                  ? '--'
                                                  : impactScoreLabel(
                                                      stats.kindexScore),
                                              isTrendingUp:
                                                  stats?.isTrendingUp,
                                              // The one card here that has a
                                              // direction; streak and
                                              // milestones are counts.
                                              showTrend: true,
                                            ),
                                          ),
                                        ),
                                        wrapWithModel(
                                          model: _model.metricCardModel4,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: MetricCard3Widget(
                                            icon: Icon(
                                              Icons.storefront_rounded,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              size: 20.0,
                                            ),
                                            tint: Color(0xFFFFD700),
                                            label: 'Visits (30d)',
                                            value: stats == null
                                                ? '--'
                                                : '${stats.visitCount30d}',
                                          ),
                                        ),
                                      ].divide(SizedBox(width: 16.0)),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ].divide(SizedBox(height: 16.0)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(24.0),
                    child: SingleChildScrollView(
                      primary: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Exclusive Connection Stream',
                                style: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .override(
                                      font: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                              ),
                              Icon(
                                Icons.verified_user_rounded,
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                size: 18.0,
                              ),
                            ],
                          ),
                          // These three cards were hardcoded offers attributed to
                          // The Iron Cactus, Pearl Brewery and Estate Coffee Co.
                          // Those are real San Antonio businesses, and the deals
                          // were invented - so the page was publishing
                          // promotional claims on their behalf that they never
                          // made. Now driven by exchange_promotions, with an
                          // empty state when there is nothing live.
                          FutureBuilder<List<_PromoView>>(
                            future: _promosFuture,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24.0),
                                  child: Center(
                                    child: SizedBox(
                                      width: 28.0,
                                      height: 28.0,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          FlutterFlowTheme.of(context)
                                              .secondaryText,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final promos = snapshot.data!;
                              if (promos.isEmpty) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24.0),
                                  child: Text(
                                    'No live offers right now. Check back after '
                                    'you visit a few more local businesses.',
                                    textAlign: TextAlign.center,
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                        ),
                                  ),
                                );
                              }

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: promos
                                    .map((promo) => PromoCardWidget(
                                          initial: businessInitials(
                                              promo.businessName),
                                          business: promo.businessName,
                                          time: promo.countdown,
                                          deal: promo.deal,
                                        ))
                                    .toList()
                                    .divide(SizedBox(height: 16.0)),
                              );
                            },
                          ),
                        ].divide(SizedBox(height: 16.0)),
                      ),
                    ),
                  ),
                  _recommendedForYouCarousel(context),
                  _shareKinPrompt(context),
                  _supportChatPrompt(context),
                  _feedbackPrompt(context),
                  _accountSection(context),
                  Container(
                    height: 40.0,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0.0,
              left: 0.0,
              right: 0.0,
              child: Container(
                height: MediaQuery.of(context).padding.top,
                color: FlutterFlowTheme.of(context).primaryBackground,
              ),
            ),
          ],
        ),
        // Without this the Directory tab was a dead end: no nav bar, and the
        // back arrow above was decorative, so the only way out was the
        // system back-swipe gesture.
        //
        // This one widget serves both the Home and Loyalty tabs (Loyalty
        // just scrolls it to Personal Milestones - see scrollToMilestones
        // above), so which base tab the nav bar swaps out for Hunt depends
        // on which one brought the user here.
        bottomNavigationBar: KinBottomNav2Widget(
          currentPage:
              widget.scrollToMilestones ? KinNavPage.loyalty : KinNavPage.home,
        ),
      ),
    );
  }

  /// A short, self-authored "About Me" blurb. Tapping opens [EditBioSheet];
  /// the sheet returns the saved text so this can update immediately rather
  /// than waiting on the next currentUserDocument refresh.
  Widget _bioSection(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final bio = currentUserDocument?.bio ?? '';

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(24.0, 8.0, 24.0, 0.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () async {
          final saved = await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => EditBioSheet(currentBio: bio),
          );
          if (saved != null && mounted) safeSetState(() {});
        },
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  bio.isEmpty ? 'Add a short bio about yourself' : bio,
                  textAlign: TextAlign.center,
                  style: theme.bodySmall.override(
                    font: GoogleFonts.plusJakartaSans(
                      fontStyle:
                          bio.isEmpty ? FontStyle.italic : FontStyle.normal,
                    ),
                    color: theme.secondaryText,
                    letterSpacing: 0.0,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(4.0, 2.0, 0.0, 0.0),
                child: Icon(
                  Icons.edit_rounded,
                  color: theme.secondaryText,
                  size: 14.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A lightweight "more like what you liked" shelf, not real ML - see
  /// KinServices.fetchRecommendedItems for the category-based heuristic.
  /// Hidden entirely (no loading spinner, no empty state) until there's
  /// something real to show, same "empty shelf beats fabricated content"
  /// precedent as Marketplace's "Popular near you" rail.
  Widget _recommendedForYouCarousel(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return FutureBuilder<List<BusinessItemsRecord>>(
      future: _recommendedFuture,
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsetsDirectional.fromSTEB(24.0, 8.0, 24.0, 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recommended for you',
                style: theme.labelLarge.override(
                  font:
                      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  color: theme.secondaryText,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: items
                      .map((item) => MarketplaceItemCardWidget(item: item))
                      .toList()
                      .divide(SizedBox(width: 12.0)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Customers' only invite/share mechanism - owners already have one via
  /// Owner Profile's "Promote" button. Reuses the same [KinServices.shareApp]
  /// -> UserEngagementEvent -> kindex_engine.js pipeline with generic text
  /// and no businessRef; that pipeline already scores by user, not by
  /// caller, so it needs no changes to pick this up.
  Widget _shareKinPrompt(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(24.0, 8.0, 24.0, 0.0),
      child: Builder(
        builder: (context) => InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () async {
            await KinServices.shareApp(
              text: 'Discover Black-owned businesses near you with KIN. '
                  'Download the app: $kPlayStoreUrl',
              sharePositionOrigin: getWidgetBoundingBox(context),
            );
          },
          child: Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: theme.alternate, width: 1.0),
            ),
            child: Row(
              children: [
                Icon(Icons.share_rounded,
                    color: theme.accentOnSurface, size: 22.0),
                Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(12, 0, 8, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share KIN',
                          style: theme.bodyMedium.override(
                            font: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold),
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Invite friends to discover Black-owned businesses.',
                          style: theme.bodySmall.override(
                            font: GoogleFonts.plusJakartaSans(),
                            color: theme.secondaryText,
                            letterSpacing: 0.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: theme.secondaryText, size: 20.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Entry point to [SupportChatWidget] - answers questions in-line rather
  /// than the one-way "send it and wait" shape of [_feedbackPrompt] below.
  /// Kept as a separate row rather than folded into that one: the two
  /// write to different collections (support_chat_logs vs bug_reports) and
  /// serve different intents (get an answer now vs. flag something for the
  /// team to see later).
  Widget _supportChatPrompt(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(24.0, 8.0, 24.0, 0.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: () => context.pushNamed(SupportChatWidget.routeName),
        child: Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: theme.alternate, width: 1.0),
          ),
          child: Row(
            children: [
              Icon(Icons.headset_mic_rounded,
                  color: theme.accentOnSurface, size: 22.0),
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(12, 0, 8, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Get Support',
                        style: theme.bodyMedium.override(
                          font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold),
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Ask a question and get an answer right away.',
                        style: theme.bodySmall.override(
                          font: GoogleFonts.plusJakartaSans(),
                          color: theme.secondaryText,
                          letterSpacing: 0.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.secondaryText, size: 20.0),
            ],
          ),
        ),
      ),
    );
  }

  /// Entry point to [FeedbackSheetWidget].
  ///
  /// Sits at the foot of the profile rather than in the Engagement
  /// Launchpad at the top. The launchpad is for things people came here to
  /// do; feedback is what they reach for once something has already
  /// annoyed them, and a prompt at the end of a scroll catches that
  /// without competing with the actions above it.
  Widget _feedbackPrompt(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(24.0, 8.0, 24.0, 0.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) =>
              FeedbackSheetWidget(originPage: 'CustomerProfilePage'),
        ),
        child: Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: theme.alternate, width: 1.0),
          ),
          child: Row(
            children: [
              // accentOnSurface rather than `primary` - the dark brand
              // green all but disappears against this card in dark mode.
              Icon(Icons.campaign_rounded,
                  color: theme.accentOnSurface, size: 22.0),
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(12, 0, 8, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Something off, or an idea?',
                        style: theme.bodyMedium.override(
                          font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold),
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Tell us - it goes straight to the team.',
                        style: theme.bodySmall.override(
                          font: GoogleFonts.plusJakartaSans(),
                          color: theme.secondaryText,
                          letterSpacing: 0.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.secondaryText, size: 20.0),
            ],
          ),
        ),
      ),
    );
  }

  /// This is the only screen a logged-in customer reliably reaches - there
  /// is no separate Settings page - so it's where the store-required
  /// account deletion control lives. Styled in the error color rather than
  /// matching [_feedbackPrompt]/[_supportChatPrompt] above: those are
  /// invitations, this is a warning, and it should read as one at a
  /// glance rather than blend in as just another utility row.
  Widget _accountSection(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(24.0, 8.0, 24.0, 0.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: () => confirmDeleteAccount(context),
        child: Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: theme.error, width: 1.0),
          ),
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded,
                  color: theme.error, size: 22.0),
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(12, 0, 8, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delete Account',
                        style: theme.bodyMedium.override(
                          font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold),
                          color: theme.error,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Permanently delete your account and data.',
                        style: theme.bodySmall.override(
                          font: GoogleFonts.plusJakartaSans(),
                          color: theme.secondaryText,
                          letterSpacing: 0.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: theme.error, size: 20.0),
            ],
          ),
        ),
      ),
    );
  }
}
