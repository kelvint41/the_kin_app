import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/services/kin_services.dart';
import '/services/nearby_feed.dart';
import '/services/seasonal_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'kin_quest_model.dart';
export 'kin_quest_model.dart';

/// A customer-facing page for discovering and checking in at nearby
/// businesses, with Rare and Hidden Gem spots called out and worth bonus
/// Quest Points.
///
/// Deliberately customer-only: it is reachable from the map's hamburger
/// menu and the bottom nav (both general-browsing surfaces, not owner
/// tooling), and never linked from Owner Profile, Executive Dashboard, or
/// any other owner-facing page. Distinct from the owner-facing
/// mystery-reward system (MysteryRewardPanelWidget /
/// mystery_reward_engine.js), which rewards an *owner* for discovering
/// other businesses to add to the directory. This page is about a
/// *customer* physically visiting businesses - it reuses the same
/// GPS-verified check-in path (KinServices.checkInToBusiness /
/// recordVerifiedVisit) that already backs Kindex-eligible reviews, and
/// awards scavenger_points on top, scaled by each business's
/// points_multiplier (see visit_verification.js).
///
/// First visit shows a one-time intro/consent screen (what the Quest is,
/// why it exists, and the ground rules) gated on
/// UsersRecord.kinQuestTermsAcceptedAt - see _introScreen.
class KinQuestWidget extends StatefulWidget {
  const KinQuestWidget({super.key});

  static String routeName = 'KinQuest';
  static String routePath = '/kinQuest';

  @override
  State<KinQuestWidget> createState() => _KinQuestWidgetState();
}

class _KinQuestWidgetState extends State<KinQuestWidget> {
  late KinQuestModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  /// Same default as NearbyFeedWidget - downtown San Antonio - so a denied
  /// or unavailable location fix still shows something instead of an empty
  /// page.
  static const LatLng _defaultLocation = LatLng(29.4241, -98.4936);

  /// Local-only until the intro screen's button is tapped, at which point
  /// it's persisted server-side (see _acceptTerms). Doesn't need to be
  /// read anywhere else - the StreamBuilder in build() re-renders off the
  /// real field the moment the write lands.
  bool _agreedToGuidelines = false;
  bool _acceptingTerms = false;

  /// True while re-showing the intro/consent screen from the "View Quest
  /// Rules" link on the list, as opposed to the real first-time gate.
  /// Purely local - re-viewing never touches
  /// kin_quest_terms_accepted_at, so it can't un-accept anything.
  bool _viewingRulesAgain = false;

  /// Resolved once per build rather than cached in initState, so the page
  /// picks up a season change immediately on the next navigation to it
  /// rather than needing the whole app relaunched.
  SeasonalTheme get _season => currentSeasonalTheme();
  Color get _accent => _season.accent;
  Color get _accentBright =>
      Color.lerp(_accent, Colors.white, 0.35) ?? _accent;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => KinQuestModel());
    getCurrentUserLocation(defaultLocation: _defaultLocation, cached: true)
        .then((loc) {
      if (!mounted) return;
      safeSetState(() {
        _model.userLocation = loc;
        _model.locationResolved = true;
      });
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  bool _isRare(BusinessesRecord b) =>
      b.rarityTier == 'Rare' || b.rarityTier == 'Hidden Gem';

  Future<void> _acceptTerms(DocumentReference userRef) async {
    if (_acceptingTerms) return;
    safeSetState(() => _acceptingTerms = true);
    try {
      await userRef.update(createUsersRecordData(
        kinQuestTermsAcceptedAt: getCurrentTimestamp,
      ));
    } finally {
      if (mounted) safeSetState(() => _acceptingTerms = false);
    }
  }

  Future<void> _checkIn(BusinessesRecord business) async {
    if (_model.checkingIn) return;
    safeSetState(() => _model.checkingIn = true);
    final result = await KinServices.checkInToBusiness(
      businessRef: business.reference,
    );
    if (!mounted) return;
    safeSetState(() => _model.checkingIn = false);

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
      return;
    }

    final checkIn = result.data!;
    final message = checkIn.alreadyCheckedIn
        ? "You've already checked in here recently."
        : checkIn.rarityTier == 'Standard'
            ? 'Checked in! +${checkIn.pointsAwarded} points.'
            : "${checkIn.rarityTier} find! +${checkIn.pointsAwarded} points.";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            checkIn.alreadyCheckedIn || checkIn.rarityTier == 'Standard'
                ? null
                : _accent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final theme = FlutterFlowTheme.of(context);
    final userRef = currentUserReference;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        automaticallyImplyLeading: false,
        leading: FlutterFlowIconButton(
          borderRadius: 8.0,
          buttonSize: 40.0,
          fillColor: Colors.transparent,
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.primaryText,
            size: 20.0,
          ),
          onPressed: () => context.safePop(),
        ),
        title: Text(
          'The KIN Quest',
          style: theme.headlineMedium.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            color: theme.primaryText,
            letterSpacing: 0.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        elevation: 0.0,
      ),
      body: SafeArea(
        top: true,
        child: userRef == null
            ? _emptyState(
                theme,
                'Sign in required',
                'Sign in to start The KIN Quest.',
              )
            : StreamBuilder<UsersRecord>(
                stream: UsersRecord.getDocument(userRef),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return _centeredSpinner(theme);
                  if (_viewingRulesAgain) {
                    return _introScreen(theme, userRef, isReview: true);
                  }
                  if (userSnapshot.data!.kinQuestTermsAcceptedAt == null) {
                    return _introScreen(theme, userRef);
                  }
                  return Column(
                    children: [
                      _rulesLinkRow(theme),
                      Expanded(child: _questList(theme)),
                    ],
                  );
                },
              ),
      ),
      bottomNavigationBar:
          const KinBottomNav2Widget(currentPage: KinNavPage.quest),
    );
  }

  Widget _rulesLinkRow(FlutterFlowTheme theme) => Padding(
        padding: EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 16.0, 0.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () =>
                  context.pushNamed(KinQuestSearchWidget.routeName),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.travel_explore_rounded, size: 16.0, color: _accent),
                  SizedBox(width: 4.0),
                  Text(
                    'Traveling? Search anywhere',
                    style: theme.labelSmall.override(
                      font: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600),
                      color: _accent,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => safeSetState(() => _viewingRulesAgain = true),
              child: Text(
                'View Quest Rules',
                style: theme.labelSmall.override(
                  font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                  color: _accent,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _questList(FlutterFlowTheme theme) {
    return !_model.locationResolved
        ? _centeredSpinner(theme)
        : FutureBuilder<List<BusinessesRecord>>(
            future: _model.businesses(),
            builder: (context, businessSnapshot) {
              if (!businessSnapshot.hasData) {
                return _centeredSpinner(theme);
              }

              final nearby = selectNearby(
                businessSnapshot.data!,
                originLat: _model.userLocation!.latitude,
                originLng: _model.userLocation!.longitude,
                latOf: (b) => b.businessLocation?.latitude,
                lngOf: (b) => b.businessLocation?.longitude,
              );

              if (nearby.isEmpty) {
                return _emptyState(
                  theme,
                  'Nothing nearby yet',
                  "We couldn't find any KIN businesses within "
                      '${kNearbyFeedRadiusKm.round()} km of you.',
                );
              }

              final rareNearby = nearby.where(_isRare).toList();
              final standardNearby = nearby.where((b) => !_isRare(b)).toList();

              return ListView(
                padding: EdgeInsets.all(16.0),
                children: [
                  _pointsHeader(theme),
                  SizedBox(height: 20.0),
                  if (rareNearby.isNotEmpty) ...[
                    _sectionLabel(theme, '✨ Rare Finds Nearby'),
                    SizedBox(height: 10.0),
                    ...rareNearby.map(
                      (b) => Padding(
                        padding: EdgeInsets.only(bottom: 12.0),
                        child: _rareCard(theme, b),
                      ),
                    ),
                    SizedBox(height: 20.0),
                  ],
                  _sectionLabel(theme, 'Nearby Businesses'),
                  SizedBox(height: 10.0),
                  ...standardNearby.map(
                    (b) => Padding(
                      padding: EdgeInsets.only(bottom: 10.0),
                      child: _standardRow(theme, b),
                    ),
                  ),
                ],
              );
            },
          );
  }

  /// One-time intro + consent screen, shown before a user's first Quest
  /// list and never again once kin_quest_terms_accepted_at is set. Three
  /// jobs: explain the concept, explain why it exists, and get informed
  /// agreement to the ground rules before anyone starts navigating to
  /// real-world addresses on our say-so.
  Widget _introScreen(
    FlutterFlowTheme theme,
    DocumentReference userRef, {
    bool isReview = false,
  }) {
    Widget sectionTitle(String text) => Text(
          text,
          style: theme.titleMedium.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            color: theme.primaryText,
            letterSpacing: 0.0,
            fontWeight: FontWeight.bold,
          ),
        );

    Widget body(String text) => Text(
          text,
          style: theme.bodyMedium.override(
            font: GoogleFonts.plusJakartaSans(),
            color: theme.secondaryText,
            letterSpacing: 0.0,
            lineHeight: 1.5,
          ),
        );

    Widget rule(String text) => Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.circle, size: 5.0, color: theme.secondaryText),
              SizedBox(width: 10.0),
              Expanded(child: body(text)),
            ],
          ),
        );

    // Stages the four blocks of the intro in one after another, so the
    // "vision" reads as a short beat-by-beat sequence rather than a wall of
    // text appearing all at once. Only on the real first-time gate -
    // re-visiting via "View Quest Rules" (isReview) shows everything
    // instantly, since re-reading shouldn't replay an intro animation every
    // time.
    Widget reveal(Widget child, int step) {
      if (isReview) return child;
      return child
          .animate(delay: (250 * step).ms)
          .fadeIn(duration: 420.ms, curve: Curves.easeOut)
          .slideY(begin: 0.08, end: 0, duration: 420.ms, curve: Curves.easeOut);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          reveal(
            Container(
              width: 64.0,
              height: 64.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [_accentBright, _accent]),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.explore_rounded,
                  color: Colors.white, size: 32.0),
            ),
            0,
          ),
          SizedBox(height: 16.0),
          reveal(
            Text(
              'Welcome to The KIN Quest',
              style: theme.headlineSmall.override(
                font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                color: theme.primaryText,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w800,
              ),
            ),
            0,
          ),
          SizedBox(height: 20.0),
          reveal(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionTitle('What it is'),
                SizedBox(height: 6.0),
                body(
                  'The KIN Quest turns exploring your city into a way to support '
                  'it. Check in at KIN businesses near you - in person, with '
                  'your real location - to earn Quest Points. Spots flagged '
                  'Rare or Hidden Gem are worth bonus points and get a glowing '
                  'marker of their own.',
                ),
              ],
            ),
            1,
          ),
          SizedBox(height: 20.0),
          reveal(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionTitle('Why it matters'),
                SizedBox(height: 6.0),
                body(
                  'Every KIN business exists because someone chose to build it '
                  'in their own community. Black-owned businesses in '
                  'particular often get discovered the slowest and lose '
                  'customers the fastest when visibility dries up. Every '
                  'check-in you log is a real, verified visit - it raises that '
                  'business\'s standing in the app (their KINDEX score) and '
                  'helps the next person find them. The Quest is just a game '
                  'on the surface; underneath it, it\'s a running, visible '
                  'record of a community choosing to show up for its own.',
                ),
                SizedBox(height: 10.0),
                body(
                  'The points are a reason to explore, not the goal itself. A '
                  'check-in with nothing behind it doesn\'t help the business '
                  'you just visited - buying something does, leaving an honest '
                  'review does, and posting about them on The Exchange so '
                  'someone else discovers them does. Treat the Quest as a '
                  'nudge to actually patronize and recommend the businesses '
                  'you find, not a list of boxes to tap.',
                ),
              ],
            ),
            2,
          ),
          SizedBox(height: 20.0),
          reveal(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionTitle('Before you start'),
                SizedBox(height: 10.0),
                rule(
                  'You\'re responsible for following all local laws, '
                  'ordinances, and posted rules wherever you are - '
                  'trespassing, parking, curfews, and business hours '
                  'included. KIN doesn\'t override any of that.',
                ),
                rule(
                  'A listing on KIN isn\'t a guarantee the business is open, '
                  'reachable, or accurately located - check before you '
                  'travel far out of your way.',
                ),
                rule(
                  'Check-ins use your device\'s location only to confirm '
                  'you\'re physically at the business - see the Privacy '
                  'Policy for how that\'s handled.',
                ),
                rule(
                  'Be a good guest, not just a checked-in one: buy something '
                  'when you can, leave a real review, and share standout '
                  'spots on The Exchange so other people find them too. This '
                  'app exists to send real customers to real businesses, not '
                  'foot traffic that shows up only to earn points and '
                  'leaves.',
                ),
              ],
            ),
            3,
          ),
          SizedBox(height: 16.0),
          // Reviewing later means this was already agreed to - re-showing
          // the checkbox/ToS row would imply re-consent is needed, which
          // it isn't. Only the first-time gate asks for it.
          if (!isReview) ...[
            GestureDetector(
              onTap: () => safeSetState(
                  () => _agreedToGuidelines = !_agreedToGuidelines),
              behavior: HitTestBehavior.opaque,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreedToGuidelines,
                    activeColor: _accent,
                    onChanged: (v) =>
                        safeSetState(() => _agreedToGuidelines = v ?? false),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 12.0),
                      child: RichText(
                        text: TextSpan(
                          style: theme.bodySmall.override(
                            font: GoogleFonts.plusJakartaSans(),
                            color: theme.secondaryText,
                            letterSpacing: 0.0,
                            lineHeight: 1.4,
                          ),
                          children: [
                            TextSpan(
                                text: 'I\'ve read the guidelines above and '
                                    'agree to the '),
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                color: _accent,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => context.pushNamed(
                                    TermsOfServicePageWidget.routeName),
                            ),
                            TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.0),
          ],
          InkWell(
            onTap: isReview
                ? () => safeSetState(() => _viewingRulesAgain = false)
                : (_agreedToGuidelines && !_acceptingTerms)
                    ? () => _acceptTerms(userRef)
                    : null,
            borderRadius: BorderRadius.circular(999.0),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 14.0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isReview || _agreedToGuidelines
                    ? _accent
                    : theme.alternate,
                borderRadius: BorderRadius.circular(999.0),
              ),
              child: _acceptingTerms
                  ? SizedBox(
                      width: 20.0,
                      height: 20.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : Text(
                      isReview ? 'Close' : 'I Agree & Start My Quest',
                      style: theme.titleSmall.override(
                        font: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold),
                        color: isReview || _agreedToGuidelines
                            ? Colors.black
                            : theme.secondaryText,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pointsHeader(FlutterFlowTheme theme) {
    final userRef = currentUserReference;
    return Container(
      padding: EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        // A seasonal tint on the brand-green base rather than a full
        // replacement - the page should still read as KIN first,
        // in-season second.
        gradient: LinearGradient(
          colors: [
            Color.lerp(theme.primary, _accent, 0.25) ?? theme.primary,
            const Color(0xFF06251B),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        children: [
          Container(
            width: 52.0,
            height: 52.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [_accentBright, _accent]),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.explore_rounded, color: Colors.white, size: 26.0),
          ),
          SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Quest Points',
                  style: theme.labelSmall.override(
                    font: GoogleFonts.plusJakartaSans(),
                    color: Colors.white70,
                    letterSpacing: 0.0,
                  ),
                ),
                userRef == null
                    ? Text(
                        '0',
                        style: theme.headlineSmall.override(
                          font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800),
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : StreamBuilder<UsersRecord>(
                        stream: UsersRecord.getDocument(userRef),
                        builder: (context, snapshot) => Text(
                          '${snapshot.data?.scavengerPoints ?? 0}',
                          style: theme.headlineSmall.override(
                            font: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800),
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _rareCard(FlutterFlowTheme theme, BusinessesRecord business) {
    final isHiddenGem = business.rarityTier == 'Hidden Gem';
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(
          color: isHiddenGem ? _accent : _accent.withAlpha(140),
          width: isHiddenGem ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withAlpha(60),
            blurRadius: 16.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44.0,
            height: 44.0,
            decoration: BoxDecoration(
              gradient: RadialGradient(colors: [_accentBright, _accent]),
              // A diamond, not a circle - the "rare find" marker this
              // section exists to show off.
              borderRadius: BorderRadius.circular(4.0),
            ),
            transform: Matrix4.rotationZ(0.785398), // 45deg
            alignment: Alignment.center,
            child: Transform.rotate(
              angle: -0.785398,
              // In season, the novelty emoji replaces the diamond/star
              // glyph inside the same rotated badge. Seasons with no
              // rareMarkerEmoji (everything but Halloween today - see
              // seasonal_theme.dart for why) keep the default glyph.
              child: _season.rareMarkerEmoji != null
                  ? Text(_season.rareMarkerEmoji!,
                      style: TextStyle(fontSize: 20.0))
                  : Icon(
                      isHiddenGem ? Icons.diamond_rounded : Icons.star_rounded,
                      color: Colors.white,
                      size: 20.0,
                    ),
            ),
          ),
          SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        business.businessName,
                        overflow: TextOverflow.ellipsis,
                        style: theme.titleSmall.override(
                          font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold),
                          color: theme.primaryText,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${business.rarityTier} · ${business.pointsMultiplier.toStringAsFixed(0)}x points',
                  style: theme.labelSmall.override(
                    font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                    color: _accent,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.0),
          _checkInButton(theme, business, filled: true),
        ],
      ),
    );
  }

  Widget _standardRow(FlutterFlowTheme theme, BusinessesRecord business) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(14.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  business.businessName,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyMedium.override(
                    font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                    color: theme.primaryText,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  business.category,
                  style: theme.labelSmall.override(
                    font: GoogleFonts.plusJakartaSans(),
                    color: theme.secondaryText,
                    letterSpacing: 0.0,
                  ),
                ),
              ],
            ),
          ),
          _checkInButton(theme, business, filled: false),
        ],
      ),
    );
  }

  Widget _checkInButton(
    FlutterFlowTheme theme,
    BusinessesRecord business, {
    required bool filled,
  }) {
    return InkWell(
      onTap: _model.checkingIn ? null : () => _checkIn(business),
      borderRadius: BorderRadius.circular(999.0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: filled ? _accent : Colors.transparent,
          border: filled ? null : Border.all(color: theme.alternate),
          borderRadius: BorderRadius.circular(999.0),
        ),
        child: Text(
          'Check In',
          style: theme.labelSmall.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            color: filled ? Colors.black : theme.primaryText,
            letterSpacing: 0.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _centeredSpinner(FlutterFlowTheme theme) => Center(
        child: SizedBox(
          width: 40.0,
          height: 40.0,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
          ),
        ),
      );

  Widget _emptyState(FlutterFlowTheme theme, String title, String body) => Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.titleMedium.override(
                  font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  color: theme.primaryText,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.bodyMedium.override(
                  font: GoogleFonts.plusJakartaSans(),
                  color: theme.secondaryText,
                  letterSpacing: 0.0,
                  lineHeight: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
}
