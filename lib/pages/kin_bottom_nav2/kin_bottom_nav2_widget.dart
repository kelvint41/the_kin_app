import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'kin_bottom_nav2_model.dart';
export 'kin_bottom_nav2_model.dart';

/// Which page currently embeds the bar, so it can avoid showing a button
/// for the screen already on screen. `other` covers every page that isn't
/// one of the four base tabs (Owner Profile, Executive Dashboard, The
/// Exchange, Community Prestige) - on those, all four base tabs show
/// normally, same as before this existed.
enum KinNavPage { home, directory, feed, loyalty, quest, other }

class KinBottomNav2Widget extends StatefulWidget {
  const KinBottomNav2Widget({super.key, this.currentPage = KinNavPage.other});

  /// The page this bar is embedded on. Whichever of the four base tabs
  /// (Home/Directory/Feed/Loyalty) matches this is replaced by The KIN
  /// Quest tab instead of linking back to the page already showing - the
  /// bar always shows exactly four buttons, never a redundant one.
  /// `KinNavPage.quest` and `KinNavPage.other` don't match any of the
  /// four, so all four show unchanged in both cases: there's no "Quest"
  /// slot to begin with when you're already on the Quest page.
  final KinNavPage currentPage;

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

  /// One tab's definition: icon, label, and what tapping it does. Kept as
  /// plain data so [_tabFor] can pick between a slot's normal definition
  /// and the Quest swap-in without duplicating the Column/Icon/Text tree.
  Widget _buildTab(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      flex: 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: _navGold(context), size: 24.0),
            Text(
              label,
              style: FlutterFlowTheme.of(context).labelSmall.override(
                    font: GoogleFonts.playfairDisplay(
                      fontWeight: FontWeight.bold,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelSmall.fontStyle,
                    ),
                    color: _navGold(context),
                    fontSize: 10.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.bold,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelSmall.fontStyle,
                    lineHeight: 1.2,
                  ),
            ),
          ].divide(SizedBox(
              height: FlutterFlowTheme.of(context).designToken.spacing.xs)),
        ),
      ),
    );
  }

  Widget _questTab(BuildContext context) => _buildTab(
        context,
        icon: Icons.explore_rounded,
        label: 'Quest',
        onTap: () => context.pushNamed(KinQuestWidget.routeName),
      );

  /// The tab for [slot], or the Quest tab if [slot] is the page this bar
  /// is currently embedded on.
  Widget _tabFor(BuildContext context, KinNavPage slot) {
    if (widget.currentPage == slot) return _questTab(context);

    switch (slot) {
      case KinNavPage.home:
        return _buildTab(
          context,
          icon: Icons.home_rounded,
          label: 'Home',
          onTap: () =>
              context.pushNamed(CustomerProfilePageWidget.routeName),
        );
      case KinNavPage.directory:
        return _buildTab(
          context,
          icon: Icons.map_rounded,
          label: 'Directory',
          onTap: () => context.pushNamed(GoogleMapPageWidget.routeName),
        );
      case KinNavPage.feed:
        return _buildTab(
          context,
          icon: Icons.forum_rounded,
          label: 'Feed',
          // Previously this opened TheExchange with whatever business
          // `queryBusinessesRecordOnce(limit: 1)` happened to return - one
          // arbitrary business's wall out of 600+, which is why the Feed
          // always looked empty. NearbyFeed aggregates the walls of the
          // businesses closest to the user instead.
          onTap: () => context.pushNamed(NearbyFeedWidget.routeName),
        );
      case KinNavPage.loyalty:
        return _buildTab(
          context,
          icon: Icons.workspace_premium_rounded,
          label: 'Loyalty',
          // Was CommunityPrestige, which reads nothing from Firestore - its
          // tier, rank and point totals are literals, so every account saw
          // the same invented standing. The real figures - support streak,
          // reviews written, Kindex score - are the Personal Milestones
          // block on CustomerProfilePage, so this opens there, scrolled
          // past the launchpad to them.
          onTap: () => context.pushNamed(
            CustomerProfilePageWidget.routeName,
            queryParameters: {
              'scrollToMilestones': serializeParam(true, ParamType.bool),
            }.withoutNulls,
          ),
        );
      case KinNavPage.quest:
      case KinNavPage.other:
        // Unreachable: _tabFor is only ever called with the four base
        // slots below.
        throw StateError('$slot is not a base nav slot');
    }
  }

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
            _tabFor(context, KinNavPage.home),
            _tabFor(context, KinNavPage.directory),
            _tabFor(context, KinNavPage.feed),
            _tabFor(context, KinNavPage.loyalty),
          ],
        ),
      ),
    );
  }
}
