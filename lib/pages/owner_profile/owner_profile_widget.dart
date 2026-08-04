import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/kin_back_button.dart';
import '/components/metric_card4_widget.dart';
import '/components/mystery_reward_panel_widget.dart';
import '/components/add_business_discovery_dialog.dart';
import '/components/review_item_widget.dart';
import '/components/business_image_widget.dart';
import '/components/community_shoutout_carousel.dart';
import '/components/main_menu_button.dart';
import '/components/support_bubble_widget.dart';
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
        // No AppBar on this page normally (the hero header below has its
        // own back button, floating over the business image), but this
        // early-return branch skips that header entirely, which left this
        // exact state - no owned business yet - with no way back at all.
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          automaticallyImplyLeading: false,
          leading: KinBackButton(),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: MainMenuButton(),
            ),
          ],
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
        // Get Support existed only as a hamburger-menu row - easy to miss
        // for an owner who hasn't dug through the menu. This is the same
        // destination, just always reachable without that.
        floatingActionButton: const SupportBubbleWidget(),
        // Only the hero's own back/menu buttons were SafeArea-protected -
        // once the page scrolls far enough that later content (e.g. "Active
        // Promotion") becomes the top-most thing on screen, nothing stopped
        // it from sliding in behind the status bar's time/battery icons,
        // since those render with no background scrim of their own. This
        // pinned strip sits above the scroll view at all times, so scrolled
        // content always stops below it instead of colliding with it - the
        // hero itself is unaffected and still bleeds under the status bar
        // at rest.
        body: Stack(
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
                    // This page has no AppBar - the hero image fills that
                    // role visually - so it never had a back button either.
                    // Reached from the map hamburger menu's "My Business /
                    // Profile" and pushed (not replaced), so there was
                    // always a screen to return to; there just wasn't a
                    // button for it.
                    //
                    // These must paint after (i.e. be listed below) the hero
                    // image and gradient above - they were previously listed
                    // first, so the opaque hero image painted over them and
                    // silently absorbed every tap meant for them. Both
                    // buttons were invisible and completely unreachable as a
                    // result, which also made every "Setup" / "Get Support" /
                    // "My Items" menu item unreachable, since they all live
                    // behind this same hamburger button.
                    Align(
                      alignment: AlignmentDirectional(1.0, -1.0),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: MainMenuButton(
                              extraItems: _ownerMenuItems(context)),
                        ),
                      ),
                    ),
                    // The other of the two buttons the comment above
                    // describes as "invisible and completely unreachable" -
                    // the hamburger got fixed, this one never got added.
                    Align(
                      alignment: AlignmentDirectional(-1.0, -1.0),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: KinBackButton(floating: true),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Was the ROI Dashboard, shown unconditionally every visit.
              // Promote, Power Hour, listing management, and the
              // ROI/upgrade dashboard itself all moved to Growth Tools -
              // this main screen now stays focused on the three things an
              // owner actually needs at a glance (profile info, KINDEX
              // score, job applicant messages), same as
              // GrowthToolsPageWidget's own doc comment describes.
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(20.0, 24.0, 20.0, 0.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16.0),
                  onTap: () =>
                      context.pushNamed(GrowthToolsPageWidget.routeName),
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                          color: FlutterFlowTheme.of(context).alternate,
                          width: 1.0),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.trending_up_rounded,
                            color: FlutterFlowTheme.of(context).accentOnSurface,
                            size: 22.0),
                        Expanded(
                          child: Padding(
                            padding:
                                EdgeInsetsDirectional.fromSTEB(12, 0, 8, 0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Growth Tools',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.bold),
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  'Promote, Power Hour, your plan, and '
                                  'listing management.',
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(
                                        font: GoogleFonts.plusJakartaSans(),
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: FlutterFlowTheme.of(context).secondaryText,
                            size: 20.0),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
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
              // Job Board Messages - the only owner-facing messaging that
              // exists today is applicant conversations tied to a specific
              // job posting (JobMessagesPage requires an applicationId), so
              // this opens Job Management rather than inventing a general
              // inbox that doesn't exist yet - see JobManagementPage for
              // where individual conversations are actually reached.
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(20.0, 12.0, 20.0, 0.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16.0),
                  onTap: () =>
                      context.pushNamed(JobManagementPage.routeName),
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                          color: FlutterFlowTheme.of(context).alternate,
                          width: 1.0),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.mail_outline_rounded,
                            color: FlutterFlowTheme.of(context).accentOnSurface,
                            size: 22.0),
                        Expanded(
                          child: Padding(
                            padding:
                                EdgeInsetsDirectional.fromSTEB(12, 0, 8, 0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Job Board Messages',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.bold),
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  'Conversations with job applicants.',
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(
                                        font: GoogleFonts.plusJakartaSans(),
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: FlutterFlowTheme.of(context).secondaryText,
                            size: 20.0),
                      ],
                    ),
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
              // Admin-only. This was visible to every business owner, which
              // made curation of a "verified Black-owned" directory a task
              // any owner could contribute to unreviewed. Adding a listing
              // is now an operator action - customers still have their own
              // path via KIN Quest search, which queues for review.
              if (currentUserDocument?.isAdmin == true)
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
              // Active Promotion (Power Hour + Location Beacon) moved to
              // Growth Tools - see the note on the card above.
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
              // "Your Membership Tier", SubscriptionManagementRow, and the
              // App Studio prompt all moved to Growth Tools alongside the
              // ROI Dashboard - see the Growth Tools card above.
              Container(
                height: 24.0,
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
        bottomNavigationBar: const KinBottomNav2Widget(),
      ),
    );
  }

  /// Owner-specific actions appended to the hamburger sheet via
  /// [MainMenuButton]'s `extraItems`. Promote and Manage My Listings used
  /// to live here too - both moved to GrowthToolsPageWidget along with
  /// everything else under its "growth/management, not a daily glance"
  /// umbrella, so they're reached from the Growth Tools card on the main
  /// screen now instead of a second path through this menu.
  List<Widget> _ownerMenuItems(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return [
      Divider(
        height: theme.designToken.spacing.md,
        thickness: 1.0,
        indent: 16.0,
        endIndent: 16.0,
        color: theme.alternate,
      ),
      ListTile(
        leading: Icon(Icons.edit_rounded, color: theme.primaryText),
        title: Text('Edit Business Profile', style: theme.bodyLarge),
        onTap: () {
          Navigator.pop(context);
          context.pushNamed(BusinessSetupPageWidget.routeName);
        },
      ),
      // Preview now lives as the eye icon on the Setup page's own header,
      // right next to where the profile is actually being edited - it no
      // longer needs its own top-level row here.
      ListTile(
        leading: Icon(Icons.headset_mic_rounded, color: theme.primaryText),
        title: Text('Get Support', style: theme.bodyLarge),
        onTap: () {
          Navigator.pop(context);
          context.pushNamed(SupportChatWidget.routeName);
        },
      ),
      ListTile(
        leading: Icon(Icons.trending_up_rounded, color: theme.primaryText),
        title: Text('Growth Tools', style: theme.bodyLarge),
        onTap: () {
          Navigator.pop(context);
          context.pushNamed(GrowthToolsPageWidget.routeName);
        },
      ),
      if (currentUserDocument?.isAdmin == true)
        ListTile(
          leading: Icon(Icons.dashboard_rounded, color: theme.primaryText),
          title: Text('Dashboard', style: theme.bodyLarge),
          onTap: () {
            Navigator.pop(context);
            context.pushNamed(ExecutiveDashboardWidget.routeName);
          },
        ),
    ];
  }

}
