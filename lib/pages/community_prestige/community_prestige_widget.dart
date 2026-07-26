import '/components/podium_spot_widget.dart';
import '/components/rank_card_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'community_prestige_model.dart';
export 'community_prestige_model.dart';

/// Hi Claude!
///
/// I am designing a mobile application built in FlutterFlow, and I need your
/// help completely redesigning a page layout to look highly professional,
/// gamified, and community-driven.
///
/// I have attached a screenshot of my current stock-market style prototype
/// called the "KIN TERMINAL" (File: e2994afa-d044-49ca-bbe2-46ff7146c650).
///
/// Right now, it looks too much like a cold Nasdaq / stock market ticker. I
/// want to completely strip away that finance aesthetic (remove the 4-letter
/// stock tickers like JOYX, remove the percentage momentum metrics, and get
/// rid of the rigid spreadsheet-like table columns).
///
/// Instead, I want you to redesign this terminal into an elegant "Community
/// Prestige Leaderboard." It needs to remain simple, easy to read, and use a
/// dark premium theme with gold accent colors.
///
/// Please provide a clean UI/UX layout breakdown and structural design
/// instructions using standard FlutterFlow widgets (Containers, Rows,
/// Columns, ListViews) based on the following structural requirements:
///
/// 1. THE TOP AREA: "THE PRESTIGE PODIUM"
/// - Instead of simple data boxes, create a hero "Top 3 Businesses" layout at
/// the top of the screen.
/// - First place should have a larger, prominent circular frame for the
/// business profile image with a gold border or a crown icon indicator.
/// - Second and Third place should sit slightly lower on either side with
/// silver and bronze accents.
/// - Display the business name and their bold K-Index score directly beneath
/// their avatars.
///
/// 2. THE MIDDLE AREA: "RELATIVE RANKING BAR"
/// - Create a dedicated "You Are Here" personal progress block for the
/// logged-in user or their own business.
/// - It should show their current position relative to others (e.g., "Top 5%
/// in San Antonio") and a simple progress bar indicating how many points they
/// need to climb to the next major milestone tier.
///
/// 3. THE LOWER AREA: "COMMUNITY PULSE STREAM"
/// - A simple, clean, vertical ListView showing ranks 4 through 10.
/// - Each item should be a sleek, rounded dark Card.
/// - Inside each card, include: Rank Number, Business Profile Avatar
/// (CircleImage), Business Name, and a single prominent Gold K-Index Score
/// badge on the far right.
/// - No confusing stock-market noise or percentage arrows.
///
/// Please break down your design instructions step-by-step using simple
/// terms, explaining exactly how to nest the containers and layout elements
/// in FlutterFlow to achieve a highly polished, gamified look.
class CommunityPrestigeWidget extends StatefulWidget {
  const CommunityPrestigeWidget({super.key});

  static String routeName = 'CommunityPrestige';
  static String routePath = '/communityPrestige';

  @override
  State<CommunityPrestigeWidget> createState() =>
      _CommunityPrestigeWidgetState();
}

class _CommunityPrestigeWidgetState extends State<CommunityPrestigeWidget> {
  late CommunityPrestigeModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CommunityPrestigeModel());
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
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SingleChildScrollView(
          primary: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A1A1A), Color(0xFF121212)],
                    stops: [0.0, 1.0],
                    begin: AlignmentDirectional(0.0, -1.0),
                    end: AlignmentDirectional(0, 1.0),
                  ),
                  shape: BoxShape.rectangle,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Container(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'COMMUNITY PRESTIGE',
                              textAlign: TextAlign.center,
                              style: FlutterFlowTheme.of(context)
                                  .labelLarge
                                  .override(
                                    font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelLarge
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelLarge
                                          .fontStyle,
                                    ),
                                    color: Color(0xFFFFD700),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelLarge
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelLarge
                                        .fontStyle,
                                    lineHeight: 1.4,
                                  ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                wrapWithModel(
                                  model: _model.podiumSpotModel1,
                                  updateCallback: () => safeSetState(() {}),
                                  child: PodiumSpotWidget(
                                    size: 70.0,
                                    accent: Color(0xFFC0C0C0),
                                    name: 'Heritage Coffee',
                                    icon: Icon(
                                      Icons.workspace_premium_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryBackground,
                                      size: 14.0,
                                    ),
                                    score: FFAppState().kindexscore,
                                  ),
                                ),
                                wrapWithModel(
                                  model: _model.podiumSpotModel2,
                                  updateCallback: () => safeSetState(() {}),
                                  child: PodiumSpotWidget(
                                    size: 100.0,
                                    accent: Color(0xFFFFD700),
                                    name: 'Velvet & Vine',
                                    icon: Icon(
                                      Icons.star_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryBackground,
                                      size: 14.0,
                                    ),
                                    score: 995.0,
                                  ),
                                ),
                                wrapWithModel(
                                  model: _model.podiumSpotModel3,
                                  updateCallback: () => safeSetState(() {}),
                                  child: PodiumSpotWidget(
                                    size: 70.0,
                                    accent: Color(0xFFCD7F32),
                                    name: 'The Local Hub',
                                    icon: Icon(
                                      Icons.military_tech_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryBackground,
                                      size: 14.0,
                                    ),
                                    score: 945.0,
                                  ),
                                ),
                              ],
                            ),
                          ].divide(SizedBox(height: 24.0)),
                        ),
                      ),
                    ),
                    Container(
                      height: 1.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).alternate,
                        shape: BoxShape.rectangle,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Container(
                    child: Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(24.0),
                        shape: BoxShape.rectangle,
                        border: Border.all(
                          color: Color(0x33FFD700),
                          width: 1.0,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Container(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'YOUR BUSINESS',
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
                                                      .secondaryText,
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
                                      Text(
                                        'Avenue Bistro',
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
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                              lineHeight: 1.4,
                                            ),
                                      ),
                                    ].divide(SizedBox(height: 4.0)),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Rank #12',
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
                                              color: Color(0xFFFFD700),
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                              lineHeight: 1.4,
                                            ),
                                      ),
                                      Text(
                                        'Top 5% in San Antonio',
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
                                                      .success,
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
                                    ].divide(SizedBox(height: 4.0)),
                                  ),
                                ],
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
                                        'Next Tier: Elite',
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
                                                      .secondaryText,
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
                                      Text(
                                        '85 pts to climb',
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
                                                      .secondaryText,
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
                                    ],
                                  ),
                                ].divide(SizedBox(height: 4.0)),
                              ),
                            ].divide(SizedBox(height: 16.0)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(24.0),
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
                          'COMMUNITY PULSE',
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
                        Text(
                          'Ranks 4-10',
                          style:
                              FlutterFlowTheme.of(context).labelSmall.override(
                                    font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context).accent3,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontStyle,
                                    lineHeight: 1.4,
                                  ),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        wrapWithModel(
                          model: _model.rankCardModel1,
                          updateCallback: () => safeSetState(() {}),
                          child: RankCardWidget(
                            rank: '4',
                            name: 'Urban Greens',
                            desc: 'Sustainable Dining',
                            score: '912',
                          ),
                        ),
                        wrapWithModel(
                          model: _model.rankCardModel2,
                          updateCallback: () => safeSetState(() {}),
                          child: RankCardWidget(
                            rank: '5',
                            name: 'Iron & Oak',
                            desc: 'Craft Furniture',
                            score: '884',
                          ),
                        ),
                        wrapWithModel(
                          model: _model.rankCardModel3,
                          updateCallback: () => safeSetState(() {}),
                          child: RankCardWidget(
                            rank: '6',
                            name: 'Neon Nights',
                            desc: 'Entertainment Venue',
                            score: '871',
                          ),
                        ),
                        wrapWithModel(
                          model: _model.rankCardModel4,
                          updateCallback: () => safeSetState(() {}),
                          child: RankCardWidget(
                            rank: '7',
                            name: 'Blue Wave',
                            desc: 'Marine Supplies',
                            score: '855',
                          ),
                        ),
                        wrapWithModel(
                          model: _model.rankCardModel5,
                          updateCallback: () => safeSetState(() {}),
                          child: RankCardWidget(
                            rank: '8',
                            name: 'The Daily Grind',
                            desc: 'Artisan Bakery',
                            score: '842',
                          ),
                        ),
                        wrapWithModel(
                          model: _model.rankCardModel6,
                          updateCallback: () => safeSetState(() {}),
                          child: RankCardWidget(
                            rank: '9',
                            name: 'Summit Peak',
                            desc: 'Outdoor Gear',
                            score: '820',
                          ),
                        ),
                        wrapWithModel(
                          model: _model.rankCardModel7,
                          updateCallback: () => safeSetState(() {}),
                          child: RankCardWidget(
                            rank: '10',
                            name: 'Petal Pushers',
                            desc: 'Floral Design',
                            score: '798',
                          ),
                        ),
                      ].divide(SizedBox(height: 8.0)),
                    ),
                  ].divide(SizedBox(height: 16.0)),
                ),
              ),
              Align(
                alignment: AlignmentDirectional(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    shape: BoxShape.rectangle,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 1.0,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).alternate,
                          shape: BoxShape.rectangle,
                        ),
                      ),
                      Container(
                        width: 0.0,
                        height: 0.0,
                      ),
                    ],
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
