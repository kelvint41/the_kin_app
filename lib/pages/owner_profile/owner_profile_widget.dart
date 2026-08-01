import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/services/kin_services.dart';
import '/components/action_btn_widget.dart';
import '/components/metric_card4_widget.dart';
import '/components/power_hour_panel_widget.dart';
import '/components/mystery_reward_panel_widget.dart';
import '/components/add_business_discovery_dialog.dart';
import '/components/review_item_widget.dart';
import '/components/business_image_widget.dart';
import '/components/community_shoutout_carousel.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'owner_profile_model.dart';
export 'owner_profile_model.dart';

/// Create a scrollable mobile business owner dashboard page called
/// 'BusinessProfile_Owner'.
///
/// The overall design should use a dark forest green primary background color
/// #0b3d2e with gold accent color #d4af37 and white text. The layout should
/// feel premium, data-forward, and clean without being overwhelming.
///
/// At the very top of the page place a hero section with a large full-width
/// business cover image placeholder. Overlay the bottom of that image with a
/// gradient fade to dark showing the business name in large bold white text,
/// the business category in smaller gold text below it, and a small gold
/// verified badge icon next to the name if the business is verified.
///
/// Directly below the hero image place a horizontally scrollable row of four
/// metric stat cards. Each card has a dark charcoal background #242424,
/// rounded corners, a gold icon at the top, a large bold white number in the
/// middle, and a small grey label underneath. The four cards are labeled:
/// 'Profile Views' with an eye icon, 'K-Index Score' with a graph trending up
/// icon, 'Total Check-Ins' with a location pin icon, and 'Reviews' with a
/// star icon. All four numbers should be displayed as text placeholders ready
/// for Firestore data binding.
///
/// Below the metric cards place a section titled 'Your K-Index Score' in bold
/// gold text. Inside this section show a horizontal progress bar that is gold
/// colored on a dark background, filled to represent the current score out of
/// 750 maximum. Below the progress bar show two small text labels: one on the
/// left showing the current score number and one on the right showing '750
/// Max'. Below that add a small informational text line in grey that reads
/// 'Your score updates automatically based on customer reviews and community
/// activity.'
///
/// Below the K-Index section place a section titled 'Active Promotion' in
/// bold white text with a small lightning bolt icon. This section contains a
/// single card with a dark charcoal background. Inside the card show a toggle
/// switch labeled 'Power Hour Blast Active' at the top right. Below the
/// toggle show a text field placeholder for the promotion description, a row
/// with two time display fields labeled 'Start' and 'End', and a full-width
/// gold button at the bottom labeled 'Edit Promotion'.
///
/// Below the promotion section place a section titled 'Recent Customer
/// Reviews' in bold white text. Show a vertical list of three review item
/// rows. Each row has a circular avatar placeholder on the left, a star
/// rating display showing filled gold stars in the middle, a short review
/// text snippet below the stars, and a small grey timestamp on the right. Add
/// a small 'View All' text link in gold at the bottom right of this section.
///
/// Below the reviews section place a section titled 'Your Membership Tier' in
/// bold white text. Show a single large card with a gradient background going
/// from dark charcoal to deep green. In the top left show a tier badge label.
/// In the center show the current tier name in large bold gold text. Below
/// that show three bullet point feature lines describing what the current
/// tier includes using a gold checkmark icon for each bullet. At the bottom
/// of the card place a full-width button with gold background and dark text
/// labeled 'Upgrade Your Plan'.
///
/// At the very bottom of the page place a row of four quick action icon
/// buttons with labels underneath. The four actions are: 'Edit Profile' with
/// a pencil icon, 'Share' with a share icon, 'Customer View' with an eye
/// icon, and 'Get Support' with a headset icon. Each button has a dark
/// charcoal circular background with a gold icon.
///
/// The page should use a single outer ListView as the primary scroll
/// container. No nested primary scroll widgets. All section titles should
/// have consistent top padding of 24 and bottom padding of 12. The overall
/// spacing should feel airy and modern like a premium SaaS dashboard adapted
/// for mobile.
class OwnerProfileWidget extends StatefulWidget {
  const OwnerProfileWidget({super.key});

  static String routeName = 'OwnerProfile';
  static String routePath = '/ownerProfile';

  @override
  State<OwnerProfileWidget> createState() => _OwnerProfileWidgetState();
}

class _OwnerProfileWidgetState extends State<OwnerProfileWidget> {
  late OwnerProfileModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => OwnerProfileModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This dashboard reads the signed-in owner's business; render an empty
    // state instead of crashing when they haven't set one up yet.
    if (currentUserDocument?.ownedBusiness == null) {
      return Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        // No AppBar on this page normally (the hero header below draws its
        // own back button over the business image), but this early-return
        // branch skips that header entirely, which left this exact state -
        // no owned business yet - with no way back at all.
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderRadius: 8.0,
            buttonSize: 40.0,
            fillColor: Colors.transparent,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: FlutterFlowTheme.of(context).primaryText,
              size: 20.0,
            ),
            onPressed: () => context.safePop(),
          ),
          elevation: 0.0,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Set up your business to see your owner dashboard.',
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                ),
                SizedBox(height: 24.0),
                FFButtonWidget(
                  onPressed: () {
                    context.pushNamed(BusinessSetupPageWidget.routeName);
                  },
                  text: 'Set Up Business',
                  options: FFButtonOptions(
                    height: 44.0,
                    padding:
                        EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                    color: FlutterFlowTheme.of(context).secondary,
                    textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                          color: Colors.white,
                        ),
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
                height: 280.0,
                child: Stack(
                  alignment: AlignmentDirectional(-1.0, -1.0),
                  children: [
                    // This page has no AppBar - the hero image fills that
                    // role visually - so it never had a back button either.
                    // Reached from the map hamburger menu's "My Business /
                    // Profile" and pushed (not replaced), so there was
                    // always a screen to return to; there just wasn't a
                    // button for it.
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: FlutterFlowIconButton(
                          borderRadius: 8.0,
                          buttonSize: 37.4,
                          fillColor:
                              FlutterFlowTheme.of(context).primaryBackground,
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: FlutterFlowTheme.of(context).primaryText,
                            size: 20.0,
                          ),
                          onPressed: () => context.safePop(),
                        ),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional(0.0, 0.0),
                      // Was a hardcoded dimg.dreamflow.cloud placeholder -
                      // a stock "luxury business storefront" every owner saw
                      // instead of their own. hero_image was never read here.
                      //
                      // Its own StreamBuilder because this page already opens
                      // one per card rather than sharing a single record;
                      // matching that is a smaller change than restructuring
                      // the page, though the duplication is worth removing.
                      child: StreamBuilder<BusinessesRecord>(
                        stream: BusinessesRecord.getDocument(
                            currentUserDocument!.ownedBusiness!),
                        builder: (context, snapshot) {
                          final hero = snapshot.data?.heroImage;
                          return BusinessImage(
                            imageUrl: hero,
                            width: double.infinity,
                            height: 280.0,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional(-1.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              // Was transparent at the top, so the white
                              // heading sat on whatever the hero happened to
                              // be - and with the KIN logo fallback that is a
                              // pale gold, which the text disappeared into.
                              FlutterFlowTheme.of(context)
                                  .primary
                                  .withAlpha(102),
                              FlutterFlowTheme.of(context)
                                  .primary
                                  .withAlpha(197),
                              FlutterFlowTheme.of(context).primary
                            ],
                            stops: [0.0, 0.7, 1.0],
                            begin: AlignmentDirectional(0.0, -1.0),
                            end: AlignmentDirectional(0, 1.0),
                          ),
                          shape: BoxShape.rectangle,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Container(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    AuthUserStreamWidget(
                                      // Was currentUserDisplayName - the
                                      // owner's own name, sitting above the
                                      // business's category and above the
                                      // business's score, views and reviews.
                                      // Everything else on this page is about
                                      // the business, so the heading is too.
                                      builder: (context) => StreamBuilder<
                                          BusinessesRecord>(
                                        stream: BusinessesRecord.getDocument(
                                            currentUserDocument!
                                                .ownedBusiness!),
                                        builder: (context, nameSnapshot) =>
                                            Text(
                                        nameSnapshot.data?.businessName ??
                                            currentUserDisplayName,
                                        style: FlutterFlowTheme.of(context)
                                            .headlineMedium
                                            .override(
                                              font: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.bold,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .headlineMedium
                                                        .fontStyle,
                                              ),
                                              color: Colors.white,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .headlineMedium
                                                      .fontStyle,
                                              lineHeight: 1.4,
                                            ),
                                      ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.verified_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      size: 20.0,
                                    ),
                                  ].divide(SizedBox(width: 4.0)),
                                ),
                                AuthUserStreamWidget(
                                  builder: (context) =>
                                      StreamBuilder<BusinessesRecord>(
                                    stream: BusinessesRecord.getDocument(
                                        currentUserDocument!.ownedBusiness!),
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

                                      final textBusinessesRecord =
                                          snapshot.data!;

                                      return Text(
                                        valueOrDefault<String>(
                                          textBusinessesRecord.category,
                                          'Business Category',
                                        ),
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
                                                      .primaryText,
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
                                      );
                                    },
                                  ),
                                ),
                              ].divide(SizedBox(height: 4.0)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 24.0, 0.0, 0.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                20.0, 0.0, 20.0, 0.0),
                            child: Container(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Stack(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    children: [
                                      AuthUserStreamWidget(
                                        builder: (context) =>
                                            StreamBuilder<BusinessesRecord>(
                                          stream: BusinessesRecord.getDocument(
                                              currentUserDocument!
                                                  .ownedBusiness!),
                                          builder: (context, snapshot) {
                                            // Customize what your widget looks like when it's loading.
                                            if (!snapshot.hasData) {
                                              return Center(
                                                child: SizedBox(
                                                  width: 50.0,
                                                  height: 50.0,
                                                  child:
                                                      CircularProgressIndicator(
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                            Color>(
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .primary,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }

                                            final metricCardBusinessesRecord =
                                                snapshot.data!;

                                            return wrapWithModel(
                                              model: _model.metricCardModel1,
                                              updateCallback: () =>
                                                  safeSetState(() {}),
                                              child: MetricCard4Widget(
                                                icon: Icon(
                                                  Icons.help,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryText,
                                                  size: 20.0,
                                                ),
                                                value: formatNumber(
                                                  metricCardBusinessesRecord
                                                      .interactionCount,
                                                  formatType:
                                                      FormatType.decimal,
                                                  decimalType:
                                                      DecimalType.periodDecimal,
                                                ),
                                                label: 'Profile Views',
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      if (valueOrDefault(
                                              currentUserDocument
                                                  ?.subscriptionStatus,
                                              '') ==
                                          'Community')
                                        AuthUserStreamWidget(
                                          builder: (context) => Container(
                                            width: 100.0,
                                            height: 100.0,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground
                                                      .withAlpha(154),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.lock,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryText,
                                                  size: 24.0,
                                                ),
                                                Text(
                                                  'Upgrade to View',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        font: GoogleFonts
                                                            .plusJakartaSans(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                        fontSize: 12.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  AuthUserStreamWidget(
                                    builder: (context) =>
                                        StreamBuilder<BusinessesRecord>(
                                      stream: BusinessesRecord.getDocument(
                                          currentUserDocument!.ownedBusiness!),
                                      builder: (context, snapshot) {
                                        // Customize what your widget looks like when it's loading.
                                        if (!snapshot.hasData) {
                                          return Center(
                                            child: SizedBox(
                                              width: 50.0,
                                              height: 50.0,
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        final metricCardBusinessesRecord =
                                            snapshot.data!;

                                        // Was wrapped in an InkWell that
                                        // pushed to CommunityPrestigeWidget -
                                        // a v2/v3 rewards mockup that reads
                                        // nothing from Firestore and renders
                                        // hardcoded businesses/scores. Tapping
                                        // an owner's real Kindex score sent
                                        // them to fake data about someone
                                        // else's business. Removed rather
                                        // than repointed - no real "Kindex
                                        // score details" destination exists
                                        // yet, and the sibling Check-Ins card
                                        // below is plain display too.
                                        return wrapWithModel(
                                          model: _model.metricCardModel2,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: MetricCard4Widget(
                                            icon: Icon(
                                              Icons.trending_up_rounded,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              size: 20.0,
                                            ),
                                            value: formatNumber(
                                              metricCardBusinessesRecord
                                                  .kindexScore,
                                              formatType: FormatType.decimal,
                                              decimalType:
                                                  DecimalType.periodDecimal,
                                            ),
                                            label: 'KINDEX Score',
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  AuthUserStreamWidget(
                                    builder: (context) =>
                                        StreamBuilder<BusinessesRecord>(
                                      stream: BusinessesRecord.getDocument(
                                          currentUserDocument!.ownedBusiness!),
                                      builder: (context, snapshot) {
                                        // Customize what your widget looks like when it's loading.
                                        if (!snapshot.hasData) {
                                          return Center(
                                            child: SizedBox(
                                              width: 50.0,
                                              height: 50.0,
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        final metricCardBusinessesRecord =
                                            snapshot.data!;

                                        return wrapWithModel(
                                          model: _model.metricCardModel3,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: MetricCard4Widget(
                                            icon: Icon(
                                              Icons.location_on_rounded,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              size: 20.0,
                                            ),
                                            value: formatNumber(
                                              metricCardBusinessesRecord
                                                  .connectionCount,
                                              formatType: FormatType.decimal,
                                              decimalType:
                                                  DecimalType.periodDecimal,
                                            ),
                                            label: 'Check-Ins',
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  AuthUserStreamWidget(
                                    builder: (context) =>
                                        StreamBuilder<BusinessesRecord>(
                                      stream: BusinessesRecord.getDocument(
                                          currentUserDocument!.ownedBusiness!),
                                      builder: (context, snapshot) {
                                        // Customize what your widget looks like when it's loading.
                                        if (!snapshot.hasData) {
                                          return Center(
                                            child: SizedBox(
                                              width: 50.0,
                                              height: 50.0,
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        final metricCardBusinessesRecord =
                                            snapshot.data!;

                                        return wrapWithModel(
                                          model: _model.metricCardModel4,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: MetricCard4Widget(
                                            icon: Icon(
                                              Icons.star_rounded,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              size: 20.0,
                                            ),
                                            value: formatNumber(
                                              metricCardBusinessesRecord
                                                  .totalSentimentScore,
                                              formatType: FormatType.decimal,
                                              decimalType:
                                                  DecimalType.periodDecimal,
                                            ),
                                            label: 'Reviews',
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ].divide(SizedBox(width: 16.0)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(20.0, 24.0, 20.0, 12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Community Shoutouts',
                      style: FlutterFlowTheme.of(context).titleSmall.override(
                            font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).primaryText,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .titleSmall
                                .fontStyle,
                          ),
                    ),
                    CommunityShoutoutCarousel(
                      businessRef: currentUserDocument!.ownedBusiness!,
                    ),
                  ].divide(SizedBox(height: 16.0)),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(20.0, 24.0, 20.0, 12.0),
                child: StreamBuilder<BusinessesRecord>(
                  stream: BusinessesRecord.getDocument(
                      currentUserDocument!.ownedBusiness!),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    return MysteryRewardPanelWidget(
                      businessRef: snapshot.data!.reference,
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(20.0, 24.0, 20.0, 12.0),
                child: FFButtonWidget(
                  onPressed: () => showModalBottomSheet(
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    context: context,
                    builder: (context) => Padding(
                      padding: MediaQuery.viewInsetsOf(context),
                      child: const AddBusinessDiscoveryDialog(),
                    ),
                  ),
                  text: 'Add a Business',
                  icon: const Icon(Icons.explore_rounded, size: 18.0),
                  options: FFButtonOptions(
                    width: double.infinity,
                    height: 44.0,
                    color: Colors.transparent,
                    textStyle: FlutterFlowTheme.of(context)
                        .labelMedium
                        .override(color: const Color(0xFFD4AF37)),
                    elevation: 0.0,
                    borderSide: BorderSide(
                      color: const Color(0xFFD4AF37).withAlpha(102),
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(20.0, 24.0, 20.0, 12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          color: FlutterFlowTheme.of(context).primaryText,
                          size: 18.0,
                        ),
                        Text(
                          'Active Promotion',
                          style: FlutterFlowTheme.of(context)
                              .titleSmall
                              .override(
                                font: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                                color: FlutterFlowTheme.of(context).primaryText,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.bold,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .fontStyle,
                              ),
                        ),
                      ].divide(SizedBox(width: 4.0)),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(24.0),
                        shape: BoxShape.rectangle,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: StreamBuilder<BusinessesRecord>(
                          stream: BusinessesRecord.getDocument(
                              currentUserDocument!.ownedBusiness!),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Center(
                                child: SizedBox(
                                  width: 24.0,
                                  height: 24.0,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      FlutterFlowTheme.of(context).secondaryText,
                                    ),
                                  ),
                                ),
                              );
                            }
                            final powerHourBusinessesRecord = snapshot.data!;
                            return PowerHourPanelWidget(
                              businessRef: powerHourBusinessesRecord.reference,
                              hasFlashBeacon:
                                  powerHourBusinessesRecord.hasFlashBeacon,
                              flashBeaconExpiresAt: powerHourBusinessesRecord
                                  .flashBeaconExpiresAt,
                            );
                          },
                        ),
                      ),
                    ),
                  ].divide(SizedBox(height: 16.0)),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(20.0, 24.0, 20.0, 12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Recent Customer Reviews',
                      style: FlutterFlowTheme.of(context).titleSmall.override(
                            font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).primaryText,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .titleSmall
                                .fontStyle,
                          ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AuthUserStreamWidget(
                          builder: (context) =>
                              StreamBuilder<List<ConnectionsRecord>>(
                            stream: queryConnectionsRecord(
                              queryBuilder: (connectionsRecord) =>
                                  connectionsRecord.where(
                                'receiver_business_ref',
                                isEqualTo: currentUserDocument?.ownedBusiness,
                              ),
                            ),
                            builder: (context, snapshot) {
                              // Customize what your widget looks like when it's loading.
                              if (!snapshot.hasData) {
                                return Center(
                                  child: SizedBox(
                                    width: 50.0,
                                    height: 50.0,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        FlutterFlowTheme.of(context).secondaryText,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              List<ConnectionsRecord>
                                  reviewItemConnectionsRecordList =
                                  snapshot.data!;

                              return wrapWithModel(
                                model: _model.reviewItemModel,
                                updateCallback: () => safeSetState(() {}),
                                child: ReviewItemWidget(
                                  name: 'Julian V.',
                                  time: '2h ago',
                                  text:
                                      'Absolutely incredible atmosphere and the service was impeccable.',
                                ),
                              );
                            },
                          ),
                        ),
                      ].divide(SizedBox(height: 8.0)),
                    ),
                  ].divide(SizedBox(height: 16.0)),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(20.0, 24.0, 20.0, 12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Your Membership Tier',
                      style: FlutterFlowTheme.of(context).titleSmall.override(
                            font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).primaryText,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .titleSmall
                                .fontStyle,
                          ),
                    ),
                    InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        context.pushNamed(
                          MerchantPricingSuiteWidget.routeName,
                          queryParameters: {
                            'businessRef': serializeParam(
                              currentUserDocument?.ownedBusiness,
                              ParamType.DocumentReference,
                            ),
                          }.withoutNulls,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            // Was [secondaryBackground, primary]: in light mode that
                              // runs white to dark green, so this card's text
                              // was legible at one end and invisible at the
                              // other. Two stops of the same green instead -
                              // it is the premium tier card and reads as one
                              // dark surface in both themes, which also means
                              // its contents can assume a dark background.
                              colors: [
                              FlutterFlowTheme.of(context).primary,
                              const Color(0xFF06251B)
                            ],
                            stops: [0.0, 1.0],
                            begin: AlignmentDirectional(1.0, 1.0),
                            end: AlignmentDirectional(-1.0, -1.0),
                          ),
                          borderRadius: BorderRadius.circular(24.0),
                          shape: BoxShape.rectangle,
                          border: Border.all(
                            color: FlutterFlowTheme.of(context)
                                .accent1
                                .withAlpha(51),
                            width: 1.0,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Container(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .accent1
                                        .withAlpha(51),
                                    borderRadius: BorderRadius.circular(9999.0),
                                    shape: BoxShape.rectangle,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        16.0, 4.0, 16.0, 4.0),
                                    child: Container(
                                      child: Text(
                                        'CURRENT PLAN',
                                        style: FlutterFlowTheme.of(context)
                                            .labelSmall
                                            .override(
                                              font: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.bold,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelSmall
                                                        .fontStyle,
                                              ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .fontStyle,
                                              lineHeight: 1.4,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                AuthUserStreamWidget(
                                  builder: (context) => Text(
                                    valueOrDefault(
                                        currentUserDocument?.subscriptionStatus,
                                        ''),
                                    style: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .override(
                                          font: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.bold,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .headlineSmall
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .headlineSmall
                                                  .fontStyle,
                                        ),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          size: 18.0,
                                        ),
                                        Text(
                                          'Priority K-Index Ranking',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font:
                                                    GoogleFonts.plusJakartaSans(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                color:
                                                    const Color(0xFFD4AF37),
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
                                      ].divide(SizedBox(width: 8.0)),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          size: 18.0,
                                        ),
                                        Text(
                                          'Unlimited Active Promotions',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font:
                                                    GoogleFonts.plusJakartaSans(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                color:
                                                    const Color(0xFFD4AF37),
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
                                      ].divide(SizedBox(width: 8.0)),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          size: 18.0,
                                        ),
                                        Text(
                                          'Advanced Analytics Dashboard',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font:
                                                    GoogleFonts.plusJakartaSans(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
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
                                      ].divide(SizedBox(width: 8.0)),
                                    ),
                                  ].divide(SizedBox(height: 8.0)),
                                ),
                              ].divide(SizedBox(height: 24.0)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ].divide(SizedBox(height: 16.0)),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primary,
                  shape: BoxShape.rectangle,
                ),
                child: Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(20.0, 32.0, 20.0, 48.0),
                  child: Container(
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            context
                                .pushNamed(BusinessSetupPageWidget.routeName);
                          },
                          child: wrapWithModel(
                            model: _model.actionBtnModel1,
                            updateCallback: () => safeSetState(() {}),
                            // Icon colour is the brand gold, not primaryText. These sit on a
                            // circle hardcoded to 0xFF242424 on a dark green
                            // bar - a surface that does not follow the theme -
                            // so a text token that inverts turned all five
                            // icons near-black on near-black.
                            child: ActionBtnWidget(
                              icon: Icon(
                                Icons.edit_rounded,
                                color: const Color(0xFFD4AF37),
                                size: 24.0,
                              ),
                              label: 'Setup',
                            ),
                          ),
                        ),
                        Builder(
                          builder: (context) => InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              await KinServices.shareApp(
                                text:
                                    'Check out my business on KIN:${currentUserDocument?.ownedBusiness?.id}',
                                sharePositionOrigin:
                                    getWidgetBoundingBox(context),
                                businessRef: currentUserDocument?.ownedBusiness,
                              );
                            },
                            child: wrapWithModel(
                              model: _model.actionBtnModel2,
                              updateCallback: () => safeSetState(() {}),
                              child: ActionBtnWidget(
                                icon: Icon(
                                  Icons.share_rounded,
                                  color: const Color(0xFFD4AF37),
                                  size: 24.0,
                                ),
                                label: 'Promote',
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            context.pushNamed(
                              BusinessProfileV2Widget.routeName,
                              queryParameters: {
                                'businessDocument': serializeParam(
                                  currentUserDocument?.ownedBusiness,
                                  ParamType.DocumentReference,
                                ),
                              }.withoutNulls,
                            );
                          },
                          child: wrapWithModel(
                            model: _model.actionBtnModel3,
                            updateCallback: () => safeSetState(() {}),
                            child: ActionBtnWidget(
                              icon: Icon(
                                Icons.visibility_rounded,
                                color: const Color(0xFFD4AF37),
                                size: 24.0,
                              ),
                              label: 'Preview',
                            ),
                          ),
                        ),
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () =>
                              context.pushNamed(SupportChatWidget.routeName),
                          child: wrapWithModel(
                            model: _model.actionBtnModel4,
                            updateCallback: () => safeSetState(() {}),
                            child: ActionBtnWidget(
                              icon: Icon(
                                Icons.headset_mic_rounded,
                                color: const Color(0xFFD4AF37),
                                size: 24.0,
                              ),
                              label: 'Get Support',
                            ),
                          ),
                        ),
                        if (currentUserDocument?.isAdmin == true)
                          InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              context.pushNamed(
                                  ExecutiveDashboardWidget.routeName);
                            },
                            child: wrapWithModel(
                              model: _model.actionBtnModel5,
                              updateCallback: () => safeSetState(() {}),
                              child: ActionBtnWidget(
                                icon: Icon(
                                  Icons.dashboard_rounded,
                                  color: const Color(0xFFD4AF37),
                                  size: 24.0,
                                ),
                                label: 'Dashboard',
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
        bottomNavigationBar: const KinBottomNav2Widget(),
      ),
    );
  }
}
