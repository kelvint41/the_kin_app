import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/tier_card_widget.dart';
import '/services/kin_services.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/revenue_cat_util.dart' as revenue_cat;
import 'dart:math';
import 'dart:ui';
import '/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'merchant_pricing_suite_model.dart';
export 'merchant_pricing_suite_model.dart';

// TODO: Replace with the real RevenueCat package identifiers once the
// corresponding products are configured in the RevenueCat dashboard.
//
// Note the app currently initialises RevenueCat with the literal
// "test_nlIQSnnGvtvhLZnWwgHRKoDnhsN" for BOTH platforms (see main.dart),
// which is not a real SDK key - real ones start appl_ and goog_ and differ
// per platform. Until those are set, getOfferings returns nothing,
// purchasePackage finds no package, and every upgrade button does nothing
// on a real device as well as in the Simulator.
const _kFoundingLocalMonthly = 'founding_local_monthly';
const _kProGrowthMonthly = 'pro_growth_monthly';
const _kEliteGrowthMonthly = 'elite_growth_monthly';

// Annual equivalents. These need creating as separate products in App Store
// Connect and Google Play and attaching to the same RevenueCat offering -
// the stores treat monthly and annual as distinct products, not as one
// product billed differently.
const _kFoundingLocalYearly = 'founding_local_yearly';
const _kProGrowthYearly = 'pro_growth_yearly';
const _kEliteGrowthYearly = 'elite_growth_yearly';

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

  String _packageFor(String monthly, String yearly) =>
      _yearly ? yearly : monthly;

  /// The store's own localised price for the selected billing period,
  /// falling back to the literal when offerings have not loaded.
  String _priceFor(String monthly, String yearly, String fallbackMonthly,
          String fallbackYearly) =>
      revenue_cat.storePriceFor(_packageFor(monthly, yearly)) ??
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
                          height: 280.0,
                          child: Stack(
                            alignment: AlignmentDirectional(-1.0, -1.0),
                            children: [
                              ClipRRect(
                                child: Container(
                                  height: 280.0,
                                  child: Opacity(
                                    opacity: 0.4,
                                    child: CachedNetworkImage(
                                      fadeInDuration: Duration(milliseconds: 0),
                                      fadeOutDuration:
                                          Duration(milliseconds: 0),
                                      imageUrl:
                                          'https://dimg.dreamflow.cloud/v1/image/luxury%20dark%20abstract%20gold%20waves%20background',
                                      fit: BoxFit.cover,
                                      alignment: Alignment(0.0, 0.0),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      FlutterFlowTheme.of(context).primary
                                    ],
                                    stops: [0.0, 1.0],
                                    begin: AlignmentDirectional(0.0, -1.0),
                                    end: AlignmentDirectional(0, 1.0),
                                  ),
                                  shape: BoxShape.rectangle,
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
                                      Stack(
                                        children: [],
                                      ),
                                      FlutterFlowIconButton(
                                        borderRadius: 8.0,
                                        buttonSize: 37.4,
                                        fillColor: Colors.transparent,
                                        icon: Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          size: 24.0,
                                        ),
                                        onPressed: () {
                                          context.safePop();
                                        },
                                      ),
                                      Container(
                                        height: 8.0,
                                      ),
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
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
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
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
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
                                    BusinessProfileOwnerWidget.routeName,
                                    queryParameters: {
                                      'businessRef': serializeParam(
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
                                    packageId: _packageFor(_kFoundingLocalMonthly, _kFoundingLocalYearly),
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
                                    BusinessProfileOwnerWidget.routeName,
                                    queryParameters: {
                                      'businessRef': serializeParam(
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
                                    title: 'Founding Local',
                                    badgeLabel: 'Founding Member Tier',
                                    price: _priceFor(_kFoundingLocalMonthly, _kFoundingLocalYearly, '\$19', '\$190'),
                                    f1: 'Verified Founding Member trust badge',
                                    f2: 'Up to 5 gallery photos on profile',
                                    f3: 'Basic profile analytics (views & trends)',
                                    f4: 'Post 1 promotion per month on The Exchange',
                                    beaconText: 'Upgrade',
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
                                          packageId: _packageFor(_kProGrowthMonthly, _kProGrowthYearly),
                                          tierName: 'Pro Growth',
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
                                          BusinessProfileOwnerWidget.routeName,
                                          queryParameters: {
                                            'businessRef': serializeParam(
                                              businessRef,
                                              ParamType.DocumentReference,
                                            ),
                                          }.withoutNulls,
                                        );
                                      },
                                      child: wrapWithModel(
                                        model: _model.tierCardModel3,
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                        child: TierCardWidget(
                                          isPro: true,
                                          isElite: false,
                                          title: 'Pro Growth',
                                          badgeLabel: 'Standard Business',
                                          price: _priceFor(_kProGrowthMonthly, _kProGrowthYearly, '\$29', '\$290'),
                                          f1: 'Standard interactive map placement in San Antonio',
                                          f2: 'Clutter-free promotion updates on \'The Exchange\'',
                                          f3: 'Premium performance analytics dashboard',
                                          f4: 'Priority support ticket handling',
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
                                    packageId: _packageFor(_kEliteGrowthMonthly, _kEliteGrowthYearly),
                                    tierName: 'Elite Growth',
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
                                    BusinessProfileOwnerWidget.routeName,
                                    queryParameters: {
                                      'businessRef': serializeParam(
                                        businessRef,
                                        ParamType.DocumentReference,
                                      ),
                                    }.withoutNulls,
                                  );
                                },
                                child: wrapWithModel(
                                  model: _model.tierCardModel4,
                                  updateCallback: () => safeSetState(() {}),
                                  child: TierCardWidget(
                                    isPro: false,
                                    isElite: true,
                                    title: 'Elite Growth',
                                    badgeLabel: 'Ultimate Exposure',
                                    price: _priceFor(_kEliteGrowthMonthly, _kEliteGrowthYearly, '\$59', '\$590'),
                                    f1: 'Augmented Reality Camera Placement (3D Pins)',
                                    f2: 'Interactive KINDEX dynamic ticker badge',
                                    f3: 'Geo-Fenced Flash Beacons (3-block radius)',
                                    f4: 'Priority Glowing Visual Map Pinning',
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
                                        'Secure encrypted checkout',
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
                                ].divide(SizedBox(height: 4.0)),
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
