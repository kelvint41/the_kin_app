import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '/components/kin_back_button.dart';
import '/components/kpi_card_widget.dart';
import '/components/log_visit_spend_sheet.dart';
import '/components/main_menu_button.dart';
import '/components/member_since_badge.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/services/local/community_impact_local_store.dart';

/// V1 "Community Impact & Spend Tracker" dashboard.
///
/// DRAFT SCOPE: every number here is derived from
/// [CommunityImpactLocalStore] (device-local SharedPreferences - see that
/// file's doc comment). There is no `spend_logs` Firestore collection yet;
/// this screen exists to validate the metrics and layout before that
/// backend work is approved.
class CommunityImpactDashboardWidget extends StatefulWidget {
  const CommunityImpactDashboardWidget({super.key});

  static String routeName = 'CommunityImpactDashboard';
  static String routePath = '/communityImpactDashboard';

  @override
  State<CommunityImpactDashboardWidget> createState() =>
      _CommunityImpactDashboardWidgetState();
}

class _CommunityImpactDashboardWidgetState
    extends State<CommunityImpactDashboardWidget> {
  final _store = CommunityImpactLocalStore.instance;
  final _currency = NumberFormat.simpleCurrency(locale: 'en_US');

  @override
  void initState() {
    super.initState();
    _store.ensureLoaded();
    _store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 0.0, 0.0),
          child: KinBackButton(floating: true),
        ),
        title: Text(
          'Community Impact',
          style: theme.headlineSmall.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            color: theme.primaryText,
            letterSpacing: 0.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        elevation: 0.0,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: MainMenuButton(),
          ),
        ],
      ),
      body: SafeArea(
        top: true,
        child: !_store.isLoaded
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                ),
              )
            : _body(theme),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => LogVisitSpendSheet.show(context),
        backgroundColor: theme.primary,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add_rounded),
        label: Text(
          'Log a Visit / Spend',
          style: theme.titleSmall.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _body(FlutterFlowTheme theme) {
    final entries = _store.entries;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 96.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heroTotalCard(theme),
          SizedBox(height: 16.0),
          SizedBox(
            height: 100.0,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                KpiCardWidget(
                  value: '${_store.uniqueBusinessCount}',
                  label: 'Unique Businesses Visited',
                ),
                SizedBox(width: 12.0),
                KpiCardWidget(
                  value: '${_store.currentStreakMonths} mo',
                  label: 'Monthly Support Streak',
                ),
                SizedBox(width: 12.0),
                KpiCardWidget(
                  value: '${entries.length}',
                  label: 'Visits Logged',
                ),
              ],
            ),
          ),
          SizedBox(height: 28.0),
          Text(
            'Impact Badges',
            style: theme.titleSmall.override(
              font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              color: theme.primaryText,
              letterSpacing: 0.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.0),
          Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            children: _store.badges
                .map((badge) => _badgeTile(theme, badge))
                .toList(),
          ),
          SizedBox(height: 28.0),
          Text(
            'Recent Activity',
            style: theme.titleSmall.override(
              font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              color: theme.primaryText,
              letterSpacing: 0.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.0),
          if (entries.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: theme.alternate, width: 1.0),
              ),
              child: Text(
                'No visits logged yet. Tap "Log a Visit / Spend" below every '
                'time you support a Black-owned business to start building '
                'your impact totals and streak.',
                style: theme.bodySmall.override(
                  color: theme.secondaryText,
                  lineHeight: 1.4,
                ),
              ),
            )
          else
            Column(
              children: entries
                  .map((entry) => _activityRow(theme, entry))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _heroTotalCard(FlutterFlowTheme theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primary, Color(0xFF0B3D2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
        border: Border.all(color: theme.secondary, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.volunteer_activism_rounded,
                  color: theme.secondary, size: 20.0),
              SizedBox(width: 8.0),
              Text(
                'Total Dollar Amount Supported',
                style: theme.labelMedium.override(
                  font: GoogleFonts.plusJakartaSans(),
                  color: Colors.white.withOpacity(0.85),
                  letterSpacing: 0.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.0),
          Text(
            _currency.format(_store.totalSpend),
            style: theme.displaySmall.override(
              font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.0,
            ),
          ),
          SizedBox(height: 4.0),
          Text(
            'Real dollars kept in the community, one visit at a time.',
            style: theme.bodySmall.override(
              color: theme.secondary,
              lineHeight: 1.4,
            ),
          ),
          SizedBox(height: 10.0),
          // Fixed light colors, not theme tokens - this card is a fixed
          // dark green gradient in both light and dark mode.
          const MemberSinceBadge(
            color: Colors.white70,
            iconColor: Color(0xFFC5A059),
          ),
        ],
      ),
    );
  }

  Widget _badgeTile(FlutterFlowTheme theme, ImpactBadge badge) {
    final unlocked = badge.unlocked;
    return Container(
      width: 104.0,
      padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: unlocked
            ? theme.secondary.withOpacity(0.12)
            : theme.secondaryBackground,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: unlocked ? theme.secondary : theme.alternate,
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            unlocked ? badge.icon : Icons.lock_outline_rounded,
            color: unlocked ? theme.secondary : theme.secondaryText,
            size: 26.0,
          ),
          SizedBox(height: 8.0),
          Text(
            badge.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.labelSmall.override(
              font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              color: unlocked ? theme.primaryText : theme.secondaryText,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityRow(FlutterFlowTheme theme, SpendLogEntry entry) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.0),
      padding: EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: theme.alternate, width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            width: 36.0,
            height: 36.0,
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.storefront_rounded,
                color: theme.primary, size: 18.0),
          ),
          SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyMedium.override(
                    color: theme.primaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat.yMMMd().format(entry.date) +
                      (entry.note.trim().isEmpty ? '' : ' · ${entry.note}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.labelSmall.override(color: theme.secondaryText),
                ),
              ],
            ),
          ),
          Text(
            _currency.format(entry.amount),
            style: theme.bodyMedium.override(
              color: theme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () => _store.removeEntry(entry.id),
            icon: Icon(Icons.close_rounded,
                color: theme.secondaryText, size: 18.0),
            splashRadius: 18.0,
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}
