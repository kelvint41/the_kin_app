import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'kin_bottom_nav2_model.dart';
export 'kin_bottom_nav2_model.dart';

class KinBottomNav2Widget extends StatefulWidget {
  const KinBottomNav2Widget({super.key});

  @override
  State<KinBottomNav2Widget> createState() => _KinBottomNav2WidgetState();
}

class _KinBottomNav2WidgetState extends State<KinBottomNav2Widget> {
  late KinBottomNav2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => KinBottomNav2Model());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  /// Coin gold - the dark-mode colour for all four tabs, icons and labels
  /// alike.
  ///
  /// The theme's dark `primaryText` (0xFFD4AF37, the brand gold) measured
  /// 7.4:1 on the 0xFF242424 nav background, which passes AA comfortably,
  /// but contrast is not the whole story: at 83% HSV value it is a muted
  /// metallic gold that sits too close to the bar it is painted on and
  /// reads as dim. This lifts the value to 95% and the saturation to 76%
  /// while holding roughly the same hue (44° vs 45°), so it stays gold
  /// rather than turning yellow, and lands at 9.2:1 - a brighter, warmer
  /// brass that separates cleanly from the background.
  ///
  /// Deliberately local to this widget rather than a change to the theme's
  /// dark `primaryText`, which is the default colour for nearly every text
  /// style in the app - retuning it here would repaint every screen.
  static const Color _navGoldDark = Color(0xFFF3C13A);

  /// Light-mode gold, unchanged: the theme's light `primaryText`, a
  /// deepened 0xFF7D5F16 at 6.0:1 on white. The raw brand gold manages
  /// only 1.9:1 there and would fail AA outright for the 10px labels.
  Color _navGold(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _navGoldDark
          : FlutterFlowTheme.of(context).primaryText;

  /// Previously Directory/Feed/Loyalty were `secondaryText` (gold-ish in
  /// dark mode, near-black 0xFF14181B in light mode) while Map alone was
  /// `primary`, the dark green - so the row read as three-plus-one in dark
  /// mode and lost its labels entirely in light mode. Note that Map's
  /// green was the only active-tab signal, and it was hardcoded here
  /// rather than derived from the current route, so it stayed on Map no
  /// matter which page embedded this bar. Unifying the colour removes a
  /// signal that was wrong more often than right; there is now no visual
  /// active state.
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90.0,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
            FlutterFlowTheme.of(context).designToken.spacing.lg,
            0.0,
            FlutterFlowTheme.of(context).designToken.spacing.lg,
            0.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 1,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  print('KinBottomNav2Widget: Home tab tapped');
                  context.pushNamed(CustomerProfilePageWidget.routeName);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home_rounded,
                      color: _navGold(context),
                      size: 24.0,
                    ),
                    Text(
                      'Home',
                      style: FlutterFlowTheme.of(context).labelSmall.override(
                            font: GoogleFonts.playfairDisplay(
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .fontStyle,
                            ),
                            color: _navGold(context),
                            fontSize: 10.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontStyle,
                            lineHeight: 1.2,
                          ),
                    ),
                  ].divide(SizedBox(
                      height:
                          FlutterFlowTheme.of(context).designToken.spacing.xs)),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  print('KinBottomNav2Widget: Directory tab tapped');
                  context.pushNamed(GoogleMapPageWidget.routeName);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_rounded,
                      color: _navGold(context),
                      size: 24.0,
                    ),
                    Text(
                      'Directory',
                      style: FlutterFlowTheme.of(context).labelSmall.override(
                            font: GoogleFonts.playfairDisplay(
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .fontStyle,
                            ),
                            color: _navGold(context),
                            fontSize: 10.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontStyle,
                            lineHeight: 1.2,
                          ),
                    ),
                  ].divide(SizedBox(
                      height:
                          FlutterFlowTheme.of(context).designToken.spacing.xs)),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  // Previously this opened TheExchange with whatever business
                  // `queryBusinessesRecordOnce(limit: 1)` happened to return -
                  // one arbitrary business's wall out of 600+, which is why
                  // the Feed always looked empty. NearbyFeed aggregates the
                  // walls of the businesses closest to the user instead.
                  print('KinBottomNav2Widget: Feed tab tapped');
                  context.pushNamed(NearbyFeedWidget.routeName);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.forum_rounded,
                      color: _navGold(context),
                      size: 24.0,
                    ),
                    Text(
                      'Feed',
                      style: FlutterFlowTheme.of(context).labelSmall.override(
                            font: GoogleFonts.playfairDisplay(
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .fontStyle,
                            ),
                            color: _navGold(context),
                            fontSize: 10.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontStyle,
                            lineHeight: 1.2,
                          ),
                    ),
                  ].divide(SizedBox(
                      height:
                          FlutterFlowTheme.of(context).designToken.spacing.xs)),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  print('KinBottomNav2Widget: Loyalty tab tapped');
                  // Was CommunityPrestige, which reads nothing from
                  // Firestore - its tier, rank and point totals are
                  // literals, so every account saw the same invented
                  // standing. The map page's menu had already dropped it
                  // from v1 for that reason, which left this tab as its
                  // last entry point. The real figures - support streak,
                  // reviews written, Kindex score - are the Personal
                  // Milestones block on CustomerProfilePage, so the tab
                  // opens there, scrolled past the launchpad to them.
                  context.pushNamed(
                    CustomerProfilePageWidget.routeName,
                    queryParameters: {
                      'scrollToMilestones': serializeParam(
                        true,
                        ParamType.bool,
                      ),
                    }.withoutNulls,
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      color: _navGold(context),
                      size: 24.0,
                    ),
                    Text(
                      'Loyalty',
                      style: FlutterFlowTheme.of(context).labelSmall.override(
                            font: GoogleFonts.playfairDisplay(
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .fontStyle,
                            ),
                            color: _navGold(context),
                            fontSize: 10.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontStyle,
                            lineHeight: 1.2,
                          ),
                    ),
                  ].divide(SizedBox(
                      height:
                          FlutterFlowTheme.of(context).designToken.spacing.xs)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
