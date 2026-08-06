import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/services/feature_flags.dart';
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

  /// Whether the signed-in account owns a business - the one signal this
  /// bar branches on for Home/Loyalty below. Deliberately not `isAdmin`:
  /// admin is an orthogonal permission layered on top of a real account
  /// (Executive Dashboard embeds this same bar, and its viewer might also
  /// own a business, or might just be a customer with admin rights) - it
  /// says nothing about which "home" screen actually belongs to them.
  bool get _isBusinessOwner => currentUserDocument?.ownedBusiness != null;

  /// The tab for [slot], or the Quest tab if [slot] is the page this bar
  /// is currently embedded on.
  Widget _tabFor(BuildContext context, KinNavPage slot) {
    if (widget.currentPage == slot) return _questTab(context);

    switch (slot) {
      case KinNavPage.home:
        // Every embed of this bar used to send Home to the customer
        // profile unconditionally - including on Owner Profile, Business
        // Insights, and the Executive Dashboard themselves, where a
        // business owner or admin tapping "Home" landed on a customer
        // profile that usually wasn't even theirs (they'd have to already
        // be signed in as the same account with no owned business for it
        // to make sense). This is what "reflect which type of user" in
        // the original ask meant: the destination now actually depends on
        // who's looking at it.
        return _buildTab(
          context,
          icon: Icons.home_rounded,
          label: 'Home',
          onTap: () => context.pushNamed(
            _isBusinessOwner
                ? OwnerProfileWidget.routeName
                : CustomerProfilePageWidget.routeName,
          ),
        );
      case KinNavPage.directory:
        // Universal - both a customer and a business owner want to browse
        // the same business directory, so this one doesn't branch.
        return _buildTab(
          context,
          icon: Icons.map_rounded,
          label: 'Directory',
          onTap: () => context.pushNamed(GoogleMapPageWidget.routeName),
        );
      case KinNavPage.feed:
        // The Feed renders the same exchange_posts content as The Exchange,
        // so it's held back by the same flag. Swapped for the Quest tab
        // rather than removed: the bar is a fixed four slots, and dropping
        // one would leave a visible gap. Reuses the existing swap mechanic.
        //
        // On the Quest page itself (widget.currentPage == quest doesn't
        // match this slot, so the early return above doesn't catch it)
        // that swap used to put a second, identical "Quest" button right
        // next to the real one - falls back to Support Chat instead in
        // that specific case, since there's nowhere else useful left to
        // send this slot that isn't already one of the other three.
        if (!FeatureFlags.exchangeEnabled) {
          if (widget.currentPage == KinNavPage.quest) {
            return _buildTab(
              context,
              icon: Icons.support_agent_rounded,
              label: 'Support',
              onTap: () => context.pushNamed(SupportChatWidget.routeName),
            );
          }
          return _questTab(context);
        }
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
        // A business owner has no "Personal Milestones" of their own to
        // show here - that block (support streak, reviews written,
        // personal Kindex) is a customer concept. Business Insights is
        // the owner-side equivalent: their own business's Kindex and
        // analytics, same reasoning as the Home swap above.
        if (_isBusinessOwner) {
          return _buildTab(
            context,
            icon: Icons.insights_rounded,
            label: 'Insights',
            onTap: () => context.pushNamed(BusinessInsightsWidget.routeName),
          );
        }
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
    // The decoration is on the OUTER container and SafeArea is inside it, so
    // the bar's background colour extends behind the system navigation bar
    // (reading as one continuous bar) while the tappable row is inset above
    // it.
    //
    // Without this the four tabs sat underneath Android's navigation bar:
    // still tappable, but overlapping Back / Home / Recents, so aiming for
    // "Loyalty" could just as easily send you home. Android 15 (the app
    // targets SDK 36) draws every app edge-to-edge and makes insetting the
    // app's job - a fixed-height bottom bar with no inset handling is
    // exactly the case that regression is designed to catch.
    //
    // It never showed on the iOS simulator: the home indicator is a thin
    // overlay Flutter already accounts for, not a reserved strip of system
    // buttons. Physical-Android-only bug.
    // viewPadding rather than SafeArea/MediaQuery.padding. Both describe the
    // same system inset, but `padding` is zeroed out for any subtree an
    // ancestor has already "consumed" it for - and Scaffold does exactly
    // that around its slots. When that happens SafeArea silently insets by
    // nothing and the bar sits back under the navigation buttons, which is
    // the half-covered state this is meant to fix. viewPadding always
    // reports the physical inset, so it can't be neutralised that way.
    final systemInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: systemInset),
        child: SizedBox(
          height: 90.0,
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
        ),
      ),
    );
  }
}
