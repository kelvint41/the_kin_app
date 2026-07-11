import '/components/launch_action_widget.dart';
import '/components/metric_card3_widget.dart';
import '/components/promo_card_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'customer_profile_page_model.dart';
export 'customer_profile_page_model.dart';

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
  });

  final DocumentReference? businessRef;

  static String routeName = 'CustomerProfilePage';
  static String routePath = '/customerProfilePage';

  @override
  State<CustomerProfilePageWidget> createState() =>
      _CustomerProfilePageWidgetState();
}

class _CustomerProfilePageWidgetState extends State<CustomerProfilePageWidget> {
  late CustomerProfilePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CustomerProfilePageModel());
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
        body: SingleChildScrollView(
          primary: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 100.0,
                height: 100.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primaryBackground,
                ),
                child: Stack(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Icon(
                              Icons.arrow_back,
                              color: FlutterFlowTheme.of(context).primaryText,
                              size: 24.0,
                            ),
                          ],
                        ),
                      ],
                    ),
                    Align(
                      alignment: AlignmentDirectional(0.0, 1.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.asset(
                          'assets/images/Untitled_design_(1).png',
                          width: 120.0,
                          height: 120.0,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Engagement Launchpad',
                      style: FlutterFlowTheme.of(context).titleSmall.override(
                            font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).secondaryText,
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
                              context.pushNamed(GoogleMapPageWidget.routeName);
                            },
                            child: wrapWithModel(
                              model: _model.launchActionModel1,
                              updateCallback: () => safeSetState(() {}),
                              child: LaunchActionWidget(
                                icon: Icon(
                                  Icons.map_rounded,
                                  color: Color(0xFFFFD700),
                                  size: 28.0,
                                ),
                                label: 'Explore Map',
                              ),
                            ),
                          ),
                        ),
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
                                  color: Color(0xFFFFD700),
                                  size: 28.0,
                                ),
                                label: 'The Exchange',
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              context
                                  .pushNamed(CommunityPrestigeWidget.routeName);
                            },
                            child: wrapWithModel(
                              model: _model.launchActionModel3,
                              updateCallback: () => safeSetState(() {}),
                              child: LaunchActionWidget(
                                icon: Icon(
                                  Icons.rate_review_rounded,
                                  color: Color(0xFFFFD700),
                                  size: 28.0,
                                ),
                                label: 'Community Prestige',
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
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    child: Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(24.0, 24.0, 0.0, 0.0),
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
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                wrapWithModel(
                                  model: _model.metricCardModel1,
                                  updateCallback: () => safeSetState(() {}),
                                  child: MetricCard3Widget(
                                    icon: Icon(
                                      Icons.local_fire_department_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      size: 20.0,
                                    ),
                                    tint: Color(0xFFFF8C00),
                                    label: '7-Day Support Streak',
                                    value: '14 🔥',
                                  ),
                                ),
                                wrapWithModel(
                                  model: _model.metricCardModel2,
                                  updateCallback: () => safeSetState(() {}),
                                  child: MetricCard3Widget(
                                    icon: Icon(
                                      Icons.workspace_premium_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      size: 20.0,
                                    ),
                                    tint: Color(0xFFFFD700),
                                    label: 'Milestones Unlocked',
                                    value: '5 Reviews',
                                  ),
                                ),
                                wrapWithModel(
                                  model: _model.metricCardModel3,
                                  updateCallback: () => safeSetState(() {}),
                                  child: MetricCard3Widget(
                                    icon: Icon(
                                      Icons.volunteer_activism_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      size: 20.0,
                                    ),
                                    tint: Color(0xFFFFD700),
                                    label: 'Impact Score',
                                    value: 'Top 5%',
                                  ),
                                ),
                              ].divide(SizedBox(width: 16.0)),
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
                            color: FlutterFlowTheme.of(context).secondaryText,
                            size: 18.0,
                          ),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          wrapWithModel(
                            model: _model.promoCardModel1,
                            updateCallback: () => safeSetState(() {}),
                            child: PromoCardWidget(
                              initial: 'IC',
                              business: 'The Iron Cactus',
                              time: '2h 14m',
                              deal:
                                  'Exclusive: Free appetizer with your next visit!',
                            ),
                          ),
                          wrapWithModel(
                            model: _model.promoCardModel2,
                            updateCallback: () => safeSetState(() {}),
                            child: PromoCardWidget(
                              initial: 'PB',
                              business: 'Pearl Brewery',
                              time: '5h 45m',
                              deal:
                                  'Premium Tier: 20% off all craft selections tonight.',
                            ),
                          ),
                          wrapWithModel(
                            model: _model.promoCardModel3,
                            updateCallback: () => safeSetState(() {}),
                            child: PromoCardWidget(
                              initial: 'EC',
                              business: 'Estate Coffee Co.',
                              time: '0h 42m',
                              deal:
                                  'Loyalty Perk: Double Kin points on all espresso orders.',
                            ),
                          ),
                        ].divide(SizedBox(height: 16.0)),
                      ),
                    ].divide(SizedBox(height: 16.0)),
                  ),
                ),
              ),
              Container(
                height: 40.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
