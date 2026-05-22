import '/core/kin_brand_assets.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'dart:ui';
import 'kin_bottom_nav_widget.dart' show KinBottomNavTab;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'kin_bottom_nav2_model.dart';
export 'kin_bottom_nav2_model.dart';

class KinBottomNav2Widget extends StatefulWidget {
  const KinBottomNav2Widget({
    super.key,
    this.activeTab = KinBottomNavTab.map,
  });

  final KinBottomNavTab activeTab;

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

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  void _navigateToTab(KinBottomNavTab tab) {
    final String routeName;
    switch (tab) {
      case KinBottomNavTab.directory:
        routeName = BusinessDirectory2Widget.routeName;
        break;
      case KinBottomNavTab.map:
        routeName = Page3SanAntonioDiscoveryMapWidget.routeName;
        break;
      case KinBottomNavTab.feed:
        routeName = CommunityFeedWidget.routeName;
        break;
      case KinBottomNavTab.loyalty:
        routeName = LoyaltyDashboardWidget.routeName;
        break;
    }

    if (GoRouterState.of(context).name == routeName) {
      return;
    }

    context.goNamed(routeName);
  }

  Color _tabColor(KinBottomNavTab tab) {
    return widget.activeTab == tab
        ? FlutterFlowTheme.of(context).primary
        : FlutterFlowTheme.of(context).secondaryText;
  }

  Widget _buildTabIcon({
    required KinBottomNavTab tab,
    required IconData icon,
  }) {
    if (tab == KinBottomNavTab.map && widget.activeTab == KinBottomNavTab.map) {
      return Container(
        width: 28.0,
        height: 28.0,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: FlutterFlowTheme.of(context).primary,
            width: 2.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6.0),
          child: Image.asset(
            KinBrandAssets.primaryLogo,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Image.asset(
              KinBrandAssets.appIcon,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    return Icon(
      icon,
      color: _tabColor(tab),
      size: 24.0,
    );
  }

  Widget _buildNavTab({
    required KinBottomNavTab tab,
    required IconData icon,
    required String label,
  }) {
    final color = _tabColor(tab);

    return Expanded(
      flex: 1,
      child: InkWell(
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () => _navigateToTab(tab),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildTabIcon(tab: tab, icon: icon),
            Text(
              label,
              style: FlutterFlowTheme.of(context).labelSmall.override(
                    font: GoogleFonts.playfairDisplay(
                      fontWeight: FontWeight.bold,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelSmall.fontStyle,
                    ),
                    color: color,
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
            _buildNavTab(
              tab: KinBottomNavTab.directory,
              icon: Icons.home_rounded,
              label: 'Directory',
            ),
            _buildNavTab(
              tab: KinBottomNavTab.map,
              icon: Icons.map_rounded,
              label: 'Map',
            ),
            _buildNavTab(
              tab: KinBottomNavTab.feed,
              icon: Icons.forum_rounded,
              label: 'Feed',
            ),
            _buildNavTab(
              tab: KinBottomNavTab.loyalty,
              icon: Icons.workspace_premium_rounded,
              label: 'Loyalty',
            ),
          ],
        ),
      ),
    );
  }
}
