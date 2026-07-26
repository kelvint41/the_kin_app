import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/milestone_card_widget.dart';
import '/components/rank_item_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'single_mobile_named_page_model.dart';
export 'single_mobile_named_page_model.dart';

/// Create a single mobile page named CommunityPrestigePage for a premium
/// directory app called "Kinvest Guidance" that showcases black-owned
/// businesses.
///
/// This is a gamified engagement/leaderboard page. It must look premium,
/// clean, dynamic, and professional.
///
/// STYLING RULES (apply these first, to every widget on the page):
///
/// Two colors only: background #0B3D2E (Deep Green), accents #C5A059 (Mustard
/// Gold). Text is white #FFFFFF or off-white #F5F1E8. No other colors.
/// Gold #C5A059 is used for: active toggle, progress bar fill, rank badges
/// #1–#3, all icons, key numbers, and section titles.
/// Green #0B3D2E is the fill for the scaffold and all cards/list items.
/// Contrast rule: white/off-white text on green surfaces; dark green #0B3D2E
/// text on gold surfaces. Never gold-on-gold or green-on-green.
/// All corners rounded 16px. Consistent 12–16px spacing. Clean,
/// high-contrast, premium finish.
/// Default font: clean sans-serif (Inter or Poppins). Section titles gold
/// #C5A059, bold, 18px. Body text white or off-white.
/// PAGE SETUP:
///
/// Scaffold background color: Deep Green #0B3D2E.
/// Wrap all content in a scrollable SingleChildScrollView with a Column, 20px
/// horizontal padding.
/// SECTION 1 — Profile Header (ProfileHeaderContainer):
///
/// A Container with 20px padding, 16px rounded corners, a 1px gold border
/// #C5A059, and a slightly lighter green fill.
/// Inside, a Row: on the left a circular CircleAvatar (60px) profile image
/// placeholder. On the right a Column with the business name ("Placeholder
/// Business Name", white, bold, 16px) and directly below it a rank badge — a
/// pill-shaped Container filled gold #C5A059 with dark green text reading
/// "Community Pillar" (rounded, 8px padding).
/// Below the row, a level label Row: "Level 4" on the left, "Level 5" on the
/// right, both off-white 12px.
/// Under that, a LinearProgressIndicator showing progress to the next level:
/// value 0.65, fill color gold #C5A059, background a muted dark green, height
/// 10px, fully rounded corners.
/// SECTION 2 — Segmented Control (RankingToggle):
///
/// A ToggleButtons / segmented control with two options: "Local Ranking" and
/// "National Ranking".
/// Active segment filled gold #C5A059 with Deep Green text; inactive segment
/// transparent with a gold border and off-white text. Full-width, rounded
/// 12px.
/// SECTION 3 — Leaderboard (PrestigeLeaderboard):
///
/// Section title "Prestige Rankings" in gold.
/// A ListView (shrinkWrap: true, physics: NeverScrollableScrollPhysics) with
/// 8 placeholder items.
/// Each item is a Container (row) filled Deep Green #0B3D2E, 14px rounded
/// corners, 12px vertical margin, 16px padding, thin gold border.
/// Item Row has three parts: (1) Rank Number — a bold number in a small
/// circular badge; ranks #1, #2, #3 use a gold #C5A059 badge with dark green
/// number, ranks #4+ use a muted green badge with off-white number. (2)
/// Business Name — placeholder name (white, bold, 15px), expanded to fill
/// space. (3) Prestige Score — a number like "1,280" on the far right in
/// gold, bold, with a small star icon.
/// SECTION 4 — Milestones (MilestonesSection):
///
/// Section title "Your Milestones" in gold.
/// A GridView (2 columns, shrinkWrap: true, NeverScrollableScrollPhysics) of
/// elevated Card widgets (elevation 4, 16px rounded corners, lighter Deep
/// Green fill). Create 3 cards:
/// Icon (star/reviews), big gold number "24", off-white label "Reviews
/// Written".
/// Icon (location pin), big gold number "58", off-white label "Check-ins".
/// Icon (handshake/heart), big gold number "17", off-white label "Businesses
/// Supported".
/// Each card: centered Column — gold icon on top, large bold number in the
/// middle, small off-white label at bottom.
class SingleMobileNamedPageWidget extends StatefulWidget {
  const SingleMobileNamedPageWidget({super.key});

  static String routeName = 'SingleMobileNamedPage';
  static String routePath = '/singleMobileNamedPage';

  @override
  State<SingleMobileNamedPageWidget> createState() =>
      _SingleMobileNamedPageWidgetState();
}

class _SingleMobileNamedPageWidgetState
    extends State<SingleMobileNamedPageWidget> with TickerProviderStateMixin {
  late SingleMobileNamedPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SingleMobileNamedPageModel());

    animationsMap.addAll({
      'textOnPageLoadAnimation': AnimationInfo(
        loop: true,
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 1000.0.ms,
            begin: Offset(1.0, 1.0),
            end: Offset(1.0, 1.0),
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

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primary,
        body: SingleChildScrollView(
          primary: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 20.0),
                child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            0.0, 10.0, 0.0, 10.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Kinvest Guidance',
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                    ),
                                    color:
                                        FlutterFlowTheme.of(context).secondary,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                    lineHeight: 1.4,
                                  ),
                            ),
                            FlutterFlowIconButton(
                              borderRadius: 8.0,
                              buttonSize: 40.0,
                              fillColor: Colors.transparent,
                              icon: Icon(
                                Icons.settings_rounded,
                                color: FlutterFlowTheme.of(context).secondary,
                                size: 24.0,
                              ),
                              onPressed: () {
                                print('IconButton pressed ...');
                              },
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF144D3D),
                          borderRadius: BorderRadius.circular(16.0),
                          shape: BoxShape.rectangle,
                          border: Border.all(
                            color: FlutterFlowTheme.of(context).secondary,
                            width: 1.0,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Container(
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
                                    Container(
                                      width: 60.0,
                                      height: 60.0,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(30.0),
                                      ),
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      child: AuthUserStreamWidget(
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

                                            final imageBusinessesRecord =
                                                snapshot.data!;

                                            return ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(30.0),
                                              child: CachedNetworkImage(
                                                fadeInDuration:
                                                    Duration(milliseconds: 0),
                                                fadeOutDuration:
                                                    Duration(milliseconds: 0),
                                                imageUrl: valueOrDefault<bool>(
                                                        currentUserDocument
                                                            ?.isBusinessOwner,
                                                        false)
                                                    ? imageBusinessesRecord
                                                        .heroImage
                                                    : currentUserPhoto,
                                                width: 60.0,
                                                height: 60.0,
                                                fit: BoxFit.cover,
                                                alignment: Alignment(0.0, 0.0),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AuthUserStreamWidget(
                                          builder: (context) =>
                                              StreamBuilder<BusinessesRecord>(
                                            stream:
                                                BusinessesRecord.getDocument(
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

                                              final textBusinessesRecord =
                                                  snapshot.data!;

                                              return Text(
                                                textBusinessesRecord
                                                                .businessName !=
                                                            ''
                                                    ? textBusinessesRecord
                                                        .businessName
                                                    : currentUserDisplayName,
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .titleMedium
                                                        .override(
                                                          font: GoogleFonts
                                                              .plusJakartaSans(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleMedium
                                                                    .fontStyle,
                                                          ),
                                                          color: Colors.white,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleMedium
                                                                  .fontStyle,
                                                          lineHeight: 1.4,
                                                        ),
                                              );
                                            },
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .secondary,
                                            borderRadius:
                                                BorderRadius.circular(100.0),
                                            shape: BoxShape.rectangle,
                                          ),
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    12.0, 4.0, 12.0, 4.0),
                                            child: Container(
                                              child: Text(
                                                'Community Pillar',
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          font: GoogleFonts
                                                              .plusJakartaSans(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primary,
                                                          fontSize: 10.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                          lineHeight: 1.4,
                                                        ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ].divide(SizedBox(height: 4.0)),
                                    ),
                                  ].divide(SizedBox(width: 16.0)),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Level 4',
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
                                                color: Color(0xFFF5F1E8),
                                                fontSize: 12.0,
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
                                        Text(
                                          'Level 5',
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
                                                color: Color(0xFFF5F1E8),
                                                fontSize: 12.0,
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
                                      ],
                                    ),
                                    LinearPercentIndicator(
                                      percent: 0.65,
                                      lineHeight: 10.0,
                                      animation: true,
                                      animateFromLastPercent: true,
                                      progressColor:
                                          FlutterFlowTheme.of(context)
                                              .secondary,
                                      backgroundColor:
                                          FlutterFlowTheme.of(context).primary,
                                      barRadius: Radius.circular(5.0),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ].divide(SizedBox(height: 4.0)),
                                ),
                              ].divide(SizedBox(height: 16.0)),
                            ),
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.0),
                            shape: BoxShape.rectangle,
                            border: Border.all(
                              color: FlutterFlowTheme.of(context).secondary,
                              width: 1.0,
                            ),
                          ),
                          child: Container(
                            height: 44.0,
                            child: Row(
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
                                      FFAppState().activeranking = 'local';
                                      safeSetState(() {});
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .secondary,
                                        shape: BoxShape.rectangle,
                                      ),
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      child: Text(
                                        'Local Ranking',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.bold,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                              lineHeight: 1.4,
                                            ),
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
                                      FFAppState().activeranking = 'national';
                                      safeSetState(() {});
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        shape: BoxShape.rectangle,
                                      ),
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      child: Text(
                                        'National Ranking',
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
                                              color: Color(0xFFF5F1E8),
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
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Prestige Rankings',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color: FlutterFlowTheme.of(context).secondary,
                                  fontSize: 18.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                  lineHeight: 1.4,
                                ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              StreamBuilder<List<PrestigePointsRecord>>(
                                stream: queryPrestigePointsRecord(
                                  queryBuilder: (prestigePointsRecord) =>
                                      prestigePointsRecord
                                          .where(
                                            'location_city',
                                            isEqualTo:
                                                FFAppState().activeranking ==
                                                        'local'
                                                    ? 'converse'
                                                    : '',
                                          )
                                          .orderBy('kindex_score',
                                              descending: true),
                                  limit: 20,
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
                                  List<PrestigePointsRecord>
                                      listViewPrestigePointsRecordList =
                                      snapshot.data!;

                                  return ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    scrollDirection: Axis.vertical,
                                    itemCount:
                                        listViewPrestigePointsRecordList.length,
                                    itemBuilder: (context, listViewIndex) {
                                      final listViewPrestigePointsRecord =
                                          listViewPrestigePointsRecordList[
                                              listViewIndex];
                                      return RankItemWidget(
                                        key: Key(
                                            'Keyf3d_${listViewIndex}_of_${listViewPrestigePointsRecordList.length}'),
                                        isTop: true,
                                        rank: listViewIndex.toString(),
                                        name: listViewPrestigePointsRecord
                                            .displayName,
                                        score: listViewPrestigePointsRecord
                                            .kindexScore
                                            .toString(),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ].divide(SizedBox(height: 16.0)),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Your Milestones',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color: FlutterFlowTheme.of(context).secondary,
                                  fontSize: 18.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                  lineHeight: 1.4,
                                ),
                          ),
                          GridView(
                            padding: EdgeInsets.zero,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12.0,
                              mainAxisSpacing: 12.0,
                              childAspectRatio: 1.0,
                            ),
                            primary: false,
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            children: [
                              AuthUserStreamWidget(
                                builder: (context) => wrapWithModel(
                                  model: _model.milestoneCardModel1,
                                  updateCallback: () => safeSetState(() {}),
                                  child: MilestoneCardWidget(
                                    icon: Icon(
                                      Icons.rate_review_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .secondary,
                                      size: 28.0,
                                    ),
                                    value: valueOrDefault<bool>(
                                            currentUserDocument
                                                ?.isBusinessOwner,
                                            false)
                                        ? 'Reviews Received'
                                        : 'Reviews Written',
                                    label: 'Reviews Written',
                                  ),
                                ),
                              ),
                              if (!valueOrDefault<bool>(
                                  currentUserDocument?.isBusinessOwner, false))
                                AuthUserStreamWidget(
                                  builder: (context) => wrapWithModel(
                                    model: _model.milestoneCardModel2,
                                    updateCallback: () => safeSetState(() {}),
                                    child: MilestoneCardWidget(
                                      icon: Icon(
                                        Icons.location_on_rounded,
                                        color: FlutterFlowTheme.of(context)
                                            .secondary,
                                        size: 28.0,
                                      ),
                                      value: '58',
                                      label: 'Check-ins',
                                    ),
                                  ),
                                ),
                              if (!valueOrDefault<bool>(
                                  currentUserDocument?.isBusinessOwner, false))
                                AuthUserStreamWidget(
                                  builder: (context) => wrapWithModel(
                                    model: _model.milestoneCardModel3,
                                    updateCallback: () => safeSetState(() {}),
                                    child: MilestoneCardWidget(
                                      icon: Icon(
                                        Icons.handshake_rounded,
                                        color: FlutterFlowTheme.of(context)
                                            .secondary,
                                        size: 28.0,
                                      ),
                                      value: '17',
                                      label: 'Businesses Supported',
                                    ),
                                  ),
                                ),
                              Stack(
                                children: [
                                  Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: wrapWithModel(
                                      model: _model.milestoneCardModel4,
                                      updateCallback: () => safeSetState(() {}),
                                      child: MilestoneCardWidget(
                                        icon: Icon(
                                          Icons.workspace_premium_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .secondary,
                                          size: 28.0,
                                        ),
                                        value: 'Gold',
                                        label: 'Current Tier',
                                      ),
                                    ),
                                  ),
                                  Opacity(
                                    opacity: 0.9,
                                    child: Align(
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      child: Container(
                                        width:
                                            MediaQuery.sizeOf(context).width *
                                                1.0,
                                        height:
                                            MediaQuery.sizeOf(context).height *
                                                1.0,
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(12.0),
                                            topRight: Radius.circular(12.0),
                                            bottomLeft: Radius.circular(12.0),
                                            bottomRight: Radius.circular(12.0),
                                          ),
                                          shape: BoxShape.rectangle,
                                        ),
                                        alignment:
                                            AlignmentDirectional(0.0, 0.0),
                                        child: Align(
                                          alignment:
                                              AlignmentDirectional(0.0, 0.0),
                                          child: Text(
                                            'Coming Soon!',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontWeight: FontWeight.bold,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .warning,
                                                  fontSize: 20.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.bold,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                          ).animateOnPageLoad(animationsMap[
                                              'textOnPageLoadAnimation']!),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ].divide(SizedBox(height: 16.0)),
                      ),
                    ].divide(SizedBox(height: 24.0)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
