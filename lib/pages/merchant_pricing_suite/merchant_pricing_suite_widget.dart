import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/tier_card_widget.dart';
import '/components/main_menu_button.dart';
import '/components/kin_back_button.dart';
import '/services/kin_services.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/revenue_cat_util.dart' as revenue_cat;
import 'dart:math';
import 'dart:ui';
import '/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'merchant_pricing_suite_model.dart';
export 'merchant_pricing_suite_model.dart';

// RevenueCat Offering identifiers - one Offering per tier, each holding a
// "monthly" and an "annual" Package. Pricing: Founder $29/mo ($288/yr),
// Founding Local $59/mo ($588/yr), Premium Local $99/mo ($950/yr),
// Elite $149/mo ($1,430/yr). Annual packages include 20% discount.
//
// Note the app falls back to the literal "test_nlIQSnnGvtvhLZnWwgHRKoDnhsN"
// SDK key for both platforms when REVENUECAT_APPLE_KEY/REVENUECAT_GOOGLE_KEY
// aren't passed at build time (see main.dart) - that's not a real SDK key,
// so getOfferings returns nothing and every upgrade button no-ops until
// real keys are supplied.
const _kFounderOffering = 'founder';
const _kFoundingLocalOffering = 'founding_local';
const _kPremiumLocalOffering = 'premium_local';
const _kEliteOffering = 'elite';

/// Create a high-fidelity mobile pricing subscription page for a premium
/// local discovery app.
///
/// Theme & Aesthetic: - Ultra-premium dark mode. Deep charcoal (#121212) or
/// rich black background. - Typography and accents should use a luxury
/// metallic gold gradient (#D4AF37) for headers and interactive highlights.
/// White or light gray for high-readability body text. - Clean, rounded
/// modern card layout components with subtle glassmorphic background blurs.
/// Layout Structure (Vertical Scroll): 1. Page Header:    - A bold, elegant
/// title: "Choose Your Growth & Impact Plan".    - A clean subtitle: "Empower
/// your business and connect with conscious shoppers."  2. Tier Cards
/// (Stacked or side-scrollable mobile cards):     - Card 1: Community Tier
///   - Price Badge: "$0 / Month" (Label: Free Community Tier)      - Core
/// Bullet Points:        * Access to public community forums        * Basic
/// business profile page on the local directory        * Up to 3 active local
/// connections     - Card 2: Pro Growth Tier (Highly Recommended)      -
/// Border: Outlined with a glowing gold metallic stroke.      - Price Badge:
/// "$19 / Month"      - Core Bullet Points:        * Standard interactive map
/// placement in San Antonio        * Clutter-free promotion updates on 'The
/// Exchange' social feed        * Access to premium performance analytics
/// dashboard        * Priority community support ticket handling     - Card
/// 3: Elite AR Navigator Tier (Premium Tier)      - Background: Luxurious
/// deep dark gradient with gold accents.      - Price Badge: "$99 / Month"
///   - Core Bullet Points:        * Augmented Reality Camera Placement (Live
/// 3D neon floating pin over physical location)        * Interactive K-Index
/// dynamic ticker badge        * Geo-Fenced Flash Beacons (Push 1-hour flash
/// alert notifications to users within a 3-block radius)        * Priority
/// Glowing Visual Map Pinning for ultimate discovery visibility  3. Call to
/// Action:    - A prominent, beautiful gold gradient button at the bottom
/// labeled "Activate Your Plan".    - A clear, small cancel-anytime
/// reassurance note below the primary button.
class MerchantPricingSuiteWidget extends StatefulWidget {
  const MerchantPricingSuiteWidget({
    super.key,
    required this.businessRef,
  });

  final DocumentReference? businessRef;

  static String routeName = 'MerchantPricingSuite';
  static String routePath = '/merchantPricingSuite';

  @override
  State<MerchantPricingSuiteWidget> createState() =>
      _MerchantPricingSuiteWidgetState();
}

class _MerchantPricingSuiteWidgetState extends State<MerchantPricingSuiteWidget>
    with TickerProviderStateMixin {
  late MerchantPricingSuiteModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MerchantPricingSuiteModel());

    // Re-fetch offerings when the paywall actually opens rather than relying
    // solely on the background load kicked off at app launch - so a stale
    // dashboard change (a repriced package, a paused offering) shows up
    // without requiring an app restart. Cards already render sensible
    // literal fallback prices while this is in flight.
    revenue_cat.loadOfferings().then((_) {
      if (mounted) safeSetState(() {});
    });

    animationsMap.addAll({
      'tierCardOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'tierCardOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
    });
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  /// Monthly or annual. Community is unaffected - it is free, so there is
  /// nothing to bill either way, and it keeps no toggle.
  bool _yearly = false;

  String get _packageId => _yearly ? 'annual' : 'monthly';

  /// Guards against a double-tap firing two startFoundingLocalTrial calls
  /// before the first round-trip lands. The callable itself is the real
  /// guard (has_used_trial is checked in a transaction) - this just stops
  /// the second tap from surfacing a confusing "already used" error.
  bool _startingTrial = false;

  /// Whole days remaining before [endsAt], floored at zero.
  int _trialDaysLeft(DateTime endsAt) {
    final remaining = endsAt.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  /// The status line under the Founding Local feature list while a trial
  /// is running. Mirrors the in-app reminder copy that the nightly sweep
  /// (founding_local_trial.js) stages via trial_reminder_stage.
  String? _trialBannerText(BusinessesRecord business) {
    if (business.trialStatus != 'active') return null;
    switch (business.trialReminderStage) {
      case 'day10':
        return "You've got 3 days left on your Founding Local trial. Right now "
            'you have your Verified Founding Member badge, 5 gallery photos, '
            'and basic analytics live on your profile. Keep them going for '
            '\$59/mo — cancel anytime.';
      case 'day13':
        return 'Your trial ends tomorrow. After that, your profile drops back '
            'to the free Community tier — no trust badge, limited photos, no '
            'analytics. Lock in Founding Local now for \$19/mo, or you\'ll '
            'automatically move to the free tier with no charge.';
      default:
        final endsAt = business.trialEndAt;
        if (endsAt == null) return null;
        final days = _trialDaysLeft(endsAt);
        return days == 1
            ? '1 day left in your trial'
            : '$days days left in your trial';
    }
  }

  /// Trial button label, or null to hide the button entirely.
  ///
  /// Three states: never trialed (offer it), mid-trial (convert to paid),
  /// and used-up (nothing - the card's own upgrade tap is the only path
  /// left, so a second trial can never be started from the UI).
  String? _trialCtaLabel(BusinessesRecord business) {
    if (business.trialStatus == 'active') {
      return 'Keep my Founding Local tier';
    }
    if (business.hasUsedTrial) return null;
    return 'Start your 14-day trial';
  }

  /// Mirrors SubscriptionManagementRow's restore flow (Owner Profile page) -
  /// duplicated here rather than shared because someone deciding whether to
  /// buy, right here on the paywall, is exactly who needs "I already paid
  /// for this on another device/a reinstall" surfaced without having to
  /// find it elsewhere first.
  bool _restoring = false;

  Future<void> _restorePurchases() async {
    safeSetState(() => _restoring = true);
    final restored = await revenue_cat.restorePurchases();
    if (!mounted) return;
    safeSetState(() => _restoring = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(restored
            ? 'Your subscription has been restored.'
            : 'No previous purchases found for this account.'),
      ),
    );
  }

  Future<void> _startTrial(DocumentReference businessRef) async {
    if (_startingTrial) return;
    safeSetState(() => _startingTrial = true);
    try {
      final result =
          await KinServices.startFoundingLocalTrial(businessRef: businessRef);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.isSuccess
              ? 'Your 14-day Founding Local trial has started.'
              : result.error!),
        ),
      );
    } finally {
      if (mounted) safeSetState(() => _startingTrial = false);
    }
  }

  /// The store's own localised price for the selected billing period,
  /// falling back to the literal when offerings have not loaded.
  String _priceFor(
          String offeringId, String fallbackMonthly, String fallbackYearly) =>
      revenue_cat.storePriceFor(offeringId, _packageId) ??
      (_yearly ? fallbackYearly : fallbackMonthly);

  /// Monthly / Yearly switch.
  ///
  /// Annual billing is the one payment option that genuinely can be added
  /// here. Klarna and Afterpay cannot: a subscription unlocking in-app
  /// features is a digital good, so Apple requires IAP and Google requires
  /// Play Billing, and neither accepts an external BNPL provider. That is
  /// policy rather than a technical gap. BNPL belongs on App Studio, which
  /// is a real-world service delivered outside the app.
  Widget _billingToggle(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    Widget option(String label, bool yearly) {
      final selected = _yearly == yearly;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(999.0),
          onTap: () => safeSetState(() => _yearly = yearly),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            decoration: BoxDecoration(
              color: selected ? theme.accent1 : Colors.transparent,
              borderRadius: BorderRadius.circular(999.0),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: theme.labelMedium.override(
                font: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600),
                color: selected ? theme.primary : theme.secondaryText,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 20),
      child: Container(
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(999.0),
          border: Border.all(color: theme.alternate),
        ),
        child: Row(
          children: [
            option('Monthly', false),
            option('Yearly', true),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Some navigation call sites push this route without a businessRef
    // (e.g. when the signed-in user has no claimed business yet). This
    // page always means "the signed-in owner's own business", so fall
    // back to that instead of crashing on a null reference.
    final businessRef =
        widget!.businessRef ?? currentUserDocument?.ownedBusiness;
    if (businessRef == null) {
      return Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Center(
          child: Text(
            'This business could not be found.',
            style: FlutterFlowTheme.of(context).bodyLarge,
          ),
        ),
      );
    }

    return StreamBuilder<BusinessesRecord>(
      stream: BusinessesRecord.getDocument(businessRef),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).secondaryText,
                  ),
                ),
              ),
            ),
          );
        }

        final merchantPricingSuiteBusinessesRecord = snapshot.data!;

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            appBar: AppBar(
              backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
              automaticallyImplyLeading: true,
              // Was a one-off 60px button, twice the size of the back
              // control everywhere else in the app.
              leading: KinBackButton(),
              actions: [
                MainMenuButton(),
              ],
              centerTitle: true,
              title: Text(
                'Choose Your Plan',
                style: FlutterFlowTheme.of(context).titleMedium.override(
                      font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                      ),
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              elevation: 0.0,
            ),
            body: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  SingleChildScrollView(
                    primary: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          // Was a fixed height: 280.0 on both this Container
                          // and the gradient behind it. That's a fine
                          // estimate for the collapsed two-line headline +
                          // two-line subtitle at default text scale, but at
                          // larger system font sizes (Dynamic Type / display
                          // scaling) the same four lines render taller than
                          // 280px and get clipped - the debug overlay showed
                          // this as "BOTTOM OVERFLOWED BY 62 PIXELS" eating
                          // into "& Impact Plan". Sizing to content (via the
                          // Stack's Positioned.fill gradient below, rather
                          // than a magic-number height) means the header
                          // simply grows with the text instead of clipping it.
                          child: Stack(
                            alignment: AlignmentDirectional(-1.0, -1.0),
                            children: [
                              // Was a CachedNetworkImage pointed at a
                              // dreamflow.cloud AI-generated placeholder
                              // ("luxury dark abstract gold waves") - a
                              // scaffolding artifact never swapped for a
                              // real asset, and prone to rendering as a
                              // busy, uncontrolled speckle pattern (or
                              // nothing at all if the request failed). A
                              // plain brand gradient can't fail to load and
                              // can't look like noise.
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        FlutterFlowTheme.of(context).primary,
                                        const Color(0xFF06251B),
                                      ],
                                      stops: [0.0, 1.0],
                                      begin: AlignmentDirectional(1.0, -1.0),
                                      end: AlignmentDirectional(-1.0, 1.0),
                                    ),
                                    shape: BoxShape.rectangle,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional(-1.0, 1.0),
                                child: Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Choose Your Growth\n& Impact Plan',
                                        style: FlutterFlowTheme.of(context)
                                            .headlineLarge
                                            .override(
                                              font: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w800,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .headlineLarge
                                                        .fontStyle,
                                              ),
                                              color: Colors.white,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w800,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .headlineLarge
                                                      .fontStyle,
                                              lineHeight: 1.4,
                                            ),
                                      ),
                                      Text(
                                        'Empower your business and connect with conscious shoppers.',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.plusJakartaSans(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                              color: Colors.white70,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                              lineHeight: 1.4,
                                            ),
                                      ),
                                    ].divide(SizedBox(height: 8.0)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _billingToggle(context),
                        Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  // Free tier: no purchase needed, just reset
                                  // the business back to the unpaid Community
                                  // plan.
                                  final businessRef =
                                      currentUserDocument?.ownedBusiness;
                                  if (businessRef == null) {
                                    return;
                                  }
                                  final result =
                                      await KinServices.downgradeToCommunity(
                                    businessRef: businessRef,
                                  );
                                  if (!result.isSuccess) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text(result.error!)),
                                      );
                                    }
                                    return;
                                  }

                                  context.pushNamed(
                                    BusinessProfileV2Widget.routeName,
                                    queryParameters: {
                                      'businessDocument': serializeParam(
                                        businessRef,
                                        ParamType.DocumentReference,
                                      ),
                                    }.withoutNulls,
                                  );
                                },
                                child: wrapWithModel(
                                  model: _model.tierCardModel1,
                                  updateCallback: () => safeSetState(() {}),
                                  child: TierCardWidget(
                                    isPro: false,
                                    isElite: false,
                                    title: 'Community',
                                    badgeLabel: 'Free Community Tier',
                                    price: '\$0',
                                    f1: 'Access to public community forums',
                                    f2: 'Basic business profile page on local directory',
                                    f3: 'Up to 3 active local connections',
                                    f4: 'Basic community support',
                                    beaconText: 'Free',
                                  ),
                                ),
                              ),
                              InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  final businessRef =
                                      currentUserDocument?.ownedBusiness;
                                  if (businessRef == null) {
                                    return;
                                  }

                                  final result =
                                      await KinServices.upgradeBusinessTier(
                                    businessRef: businessRef,
                                    offeringId: _kFounderOffering,
                                    isYearly: _yearly,
                                    tierName: 'Founder',
                                    isPremium: true,
                                  );
                                  if (!result.isSuccess) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text(result.error!)),
                                      );
                                    }
                                    return;
                                  }

                                  context.pushNamed(
                                    BusinessProfileV2Widget.routeName,
                                    queryParameters: {
                                      'businessDocument': serializeParam(
                                        businessRef,
                                        ParamType.DocumentReference,
                                      ),
                                    }.withoutNulls,
                                  );
                                },
                                child: wrapWithModel(
                                  model: _model.tierCardModel2,
                                  updateCallback: () => safeSetState(() {}),
                                  child: TierCardWidget(
                                    isPro: false,
                                    isElite: false,
                                    title: 'Founder',
                                    badgeLabel: 'Founder Tier',
                                    valueTag: 'Get visibility early.',
                                    price: _priceFor(_kFounderOffering, '\$29', '\$288'),
                                    isYearly: _yearly,
                                    yearlyTeaser: _yearly ? null : 'or \$288/yr - save \$60',
                                    f1: 'Weekly carousel rotations',
                                    f2: 'Basic business profile analytics',
                                    f3: 'Post 1 promotion per month on The Exchange',
                                    f4: 'Community support',
                                    beaconText: 'Upgrade',
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 8.0, 0.0, 16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Choose your growth level.',
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            font: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.bold,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.bold,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                    Text(
                                      'Every tier gets you on the map. Higher tiers get you seen first.',
                                      style: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .override(
                                            font: GoogleFonts.plusJakartaSans(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmall
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmall
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontStyle,
                                            lineHeight: 1.4,
                                          ),
                                    ),
                                  ].divide(SizedBox(height: 4.0)),
                                ),
                              ),
                              InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  final businessRef =
                                      currentUserDocument?.ownedBusiness;
                                  if (businessRef == null) {
                                    return;
                                  }

                                  // Trial-eligible: the card's whole tap
                                  // area starts the trial rather than a
                                  // purchase, same as tapping the button
                                  // inside it - two InkWells stacked on the
                                  // same tap don't reliably give the inner
                                  // one exclusive priority in Flutter, so
                                  // this has to branch the same way the
                                  // button does rather than relying on the
                                  // button "winning".
                                  if (merchantPricingSuiteBusinessesRecord
                                              .trialStatus !=
                                          'active' &&
                                      !merchantPricingSuiteBusinessesRecord
                                          .hasUsedTrial) {
                                    await _startTrial(businessRef);
                                    return;
                                  }

                                  final result =
                                      await KinServices.upgradeBusinessTier(
                                    businessRef: businessRef,
                                    offeringId: _kFoundingLocalOffering,
                                    isYearly: _yearly,
                                    tierName: 'Founding Local',
                                    isPremium: true,
                                  );
                                  if (!result.isSuccess) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text(result.error!)),
                                      );
                                    }
                                    return;
                                  }

                                  context.pushNamed(
                                    BusinessProfileV2Widget.routeName,
                                    queryParameters: {
                                      'businessDocument': serializeParam(
                                        businessRef,
                                        ParamType.DocumentReference,
                                      ),
                                    }.withoutNulls,
                                  );
                                },
                                child: wrapWithModel(
                                  model: _model.tierCardModel3,
                                  updateCallback: () => safeSetState(() {}),
                                  child: TierCardWidget(
                                    isPro: false,
                                    isElite: false,
                                    title: 'Founding Local',
                                    badgeLabel: 'Entry-Level Tier',
                                    valueTag: 'Get discovered by your community.',
                                    price: _priceFor(_kFoundingLocalOffering, '\$59', '\$588'),
                                    isYearly: _yearly,
                                    yearlyTeaser: _yearly ? null : 'or \$588/yr - save \$120',
                                    f1: 'Verified Founding Member trust badge',
                                    f2: 'Up to 5 gallery photos on profile',
                                    f3: 'Basic profile analytics (views & trends)',
                                    f4: 'Post 1 promotion per month on The Exchange',
                                    beaconText: 'Upgrade',
                                    // Founding Local is the only trial-
                                    // eligible tier in this pass - Pro
                                    // Growth and Elite Growth deliberately
                                    // pass none of these.
                                    trialBannerText: _trialBannerText(
                                        merchantPricingSuiteBusinessesRecord),
                                    trialCtaLabel: _trialCtaLabel(
                                        merchantPricingSuiteBusinessesRecord),
                                    onStartTrial: merchantPricingSuiteBusinessesRecord
                                                .trialStatus ==
                                            'active'
                                        // Mid-trial the CTA converts to a
                                        // real paid plan, which is the same
                                        // purchase the card tap already does.
                                        ? () async => await KinServices
                                            .upgradeBusinessTier(
                                              businessRef: businessRef,
                                              offeringId:
                                                  _kFoundingLocalOffering,
                                              isYearly: _yearly,
                                              tierName: 'Founding Local',
                                              isPremium: true,
                                            )
                                        : () async =>
                                            await _startTrial(businessRef),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional(0.0, 0.0),
                                child: StreamBuilder<List<BusinessesRecord>>(
                                  stream: queryBusinessesRecord(
                                    queryBuilder: (businessesRecord) =>
                                        businessesRecord.where(
                                      'owner_ref',
                                      isEqualTo: currentUserReference,
                                    ),
                                    singleRecord: true,
                                  ),
                                  builder: (context, snapshot) {
                                    // Customize what your widget looks like when it's loading.
                                    if (!snapshot.hasData) {
                                      return Center(
                                        child: SizedBox(
                                          width: 50.0,
                                          height: 50.0,
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              FlutterFlowTheme.of(context)
                                                  .primary,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    List<BusinessesRecord>
                                        tierCardBusinessesRecordList =
                                        snapshot.data!;
                                    // Return an empty Container when the item does not exist.
                                    if (snapshot.data!.isEmpty) {
                                      return Container();
                                    }
                                    final tierCardBusinessesRecord =
                                        tierCardBusinessesRecordList.isNotEmpty
                                            ? tierCardBusinessesRecordList.first
                                            : null;

                                    return InkWell(
                                      splashColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        final businessRef =
                                            tierCardBusinessesRecord?.reference;
                                        if (businessRef == null) {
                                          return;
                                        }
                                        final result = await KinServices
                                            .upgradeBusinessTier(
                                          businessRef: businessRef,
                                          offeringId: _kPremiumLocalOffering,
                                          isYearly: _yearly,
                                          tierName: 'Premium Local',
                                          isPremium: true,
                                        );
                                        if (!result.isSuccess) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(result.error!)),
                                            );
                                          }
                                          return;
                                        }

                                        context.pushNamed(
                                          BusinessProfileV2Widget.routeName,
                                          queryParameters: {
                                            'businessDocument': serializeParam(
                                              businessRef,
                                              ParamType.DocumentReference,
                                            ),
                                          }.withoutNulls,
                                        );
                                      },
                                      child: wrapWithModel(
                                        model: _model.tierCardModel4,
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                        child: TierCardWidget(
                                          isPro: true,
                                          isElite: false,
                                          title: 'Premium Local',
                                          badgeLabel: 'Premium Business Tier',
                                          valueTag: 'Get featured with location beacons.',
                                          price: _priceFor(_kPremiumLocalOffering, '\$99', '\$950'),
                                          isYearly: _yearly,
                                          yearlyTeaser: _yearly ? null : 'or \$950/yr - save \$238',
                                          f1: 'Premium interactive map carousel placement',
                                          f2: 'Location Beacon feature (broadcast your location)',
                                          f3: 'Advanced performance analytics & insights',
                                          f4: 'Priority support + featured business badge',
                                          beaconText: 'Upgrade',
                                        ),
                                      ),
                                    ).animateOnPageLoad(animationsMap[
                                        'tierCardOnPageLoadAnimation1']!);
                                  },
                                ),
                              ),
                              InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  final businessRef = widget!.businessRef;
                                  if (businessRef == null) {
                                    return;
                                  }
                                  final result =
                                      await KinServices.upgradeBusinessTier(
                                    businessRef: businessRef,
                                    offeringId: _kEliteOffering,
                                    isYearly: _yearly,
                                    tierName: 'Elite',
                                    isPremium: true,
                                    isPriorityPinned: true,
                                    hasFlashBeacon: true,
                                  );
                                  if (!result.isSuccess) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text(result.error!)),
                                      );
                                    }
                                    return;
                                  }

                                  context.pushNamed(
                                    BusinessProfileV2Widget.routeName,
                                    queryParameters: {
                                      'businessDocument': serializeParam(
                                        businessRef,
                                        ParamType.DocumentReference,
                                      ),
                                    }.withoutNulls,
                                  );
                                },
                                child: wrapWithModel(
                                  model: _model.tierCardModel5,
                                  updateCallback: () => safeSetState(() {}),
                                  child: TierCardWidget(
                                    isPro: false,
                                    isElite: true,
                                    title: 'Elite',
                                    badgeLabel: 'Premium Flagship Tier',
                                    valueTag: 'Always featured, maximum visibility.',
                                    price: _priceFor(_kEliteOffering, '\$149', '\$1430'),
                                    isYearly: _yearly,
                                    yearlyTeaser: _yearly ? null : 'or \$1,430/yr - save \$358',
                                    f1: 'Always featured on carousel (daily visibility)',
                                    f2: 'Unlimited Location Beacons for mobile services',
                                    f3: 'Priority support + account manager',
                                    f4: 'Custom branding & co-marketing opportunities',
                                    beaconText: 'Upgrade',
                                  ),
                                ),
                              ).animateOnPageLoad(animationsMap[
                                  'tierCardOnPageLoadAnimation2']!),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Cancel or switch plans anytime.',
                                    style: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .override(
                                          font: GoogleFonts.plusJakartaSans(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelSmall
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          fontSize: 18.0,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .labelSmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelSmall
                                                  .fontStyle,
                                          lineHeight: 1.4,
                                        ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.security_rounded,
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                        size: 12.0,
                                      ),
                                      Text(
                                        // Was 'Secure encrypted checkout' -
                                        // there is no custom checkout to
                                        // secure. Purchases go through
                                        // Apple/Google IAP, so this says
                                        // what actually happens instead of
                                        // implying a payment system KIN
                                        // built itself.
                                        'Billed securely through the App Store',
                                        style: FlutterFlowTheme.of(context)
                                            .labelSmall
                                            .override(
                                              font: GoogleFonts.plusJakartaSans(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .labelSmall
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelSmall
                                                        .fontStyle,
                                              ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .accent3,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .fontStyle,
                                              lineHeight: 1.4,
                                            ),
                                      ),
                                    ].divide(SizedBox(width: 4.0)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      children: [
                                        Text(
                                          'By subscribing you agree to our ',
                                          style: FlutterFlowTheme.of(context)
                                              .labelSmall
                                              .override(
                                                font:
                                                    GoogleFonts.plusJakartaSans(),
                                                color: FlutterFlowTheme.of(
                                                        context)
                                                    .secondaryText,
                                                letterSpacing: 0.0,
                                              ),
                                        ),
                                        InkWell(
                                          onTap: () => context.pushNamed(
                                              TermsOfServicePageWidget
                                                  .routeName),
                                          child: Text(
                                            'Terms of Service',
                                            style: FlutterFlowTheme.of(context)
                                                .labelSmall
                                                .override(
                                                  font: GoogleFonts
                                                      .plusJakartaSans(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primary,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.bold,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          ' and ',
                                          style: FlutterFlowTheme.of(context)
                                              .labelSmall
                                              .override(
                                                font:
                                                    GoogleFonts.plusJakartaSans(),
                                                color: FlutterFlowTheme.of(
                                                        context)
                                                    .secondaryText,
                                                letterSpacing: 0.0,
                                              ),
                                        ),
                                        InkWell(
                                          onTap: () => context.pushNamed(
                                              PrivacyPolicyPageWidget
                                                  .routeName),
                                          child: Text(
                                            'Privacy Policy',
                                            style: FlutterFlowTheme.of(context)
                                                .labelSmall
                                                .override(
                                                  font: GoogleFonts
                                                      .plusJakartaSans(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primary,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.bold,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          '. Plans renew automatically until cancelled.',
                                          style: FlutterFlowTheme.of(context)
                                              .labelSmall
                                              .override(
                                                font:
                                                    GoogleFonts.plusJakartaSans(),
                                                color: FlutterFlowTheme.of(
                                                        context)
                                                    .secondaryText,
                                                letterSpacing: 0.0,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ].divide(SizedBox(height: 4.0)),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: TextButton(
                                  onPressed:
                                      _restoring ? null : _restorePurchases,
                                  child: Text(
                                    _restoring
                                        ? 'Restoring...'
                                        : 'Restore Purchases',
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          decoration:
                                              TextDecoration.underline,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
