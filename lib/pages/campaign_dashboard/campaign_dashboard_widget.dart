import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/referral_share_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'campaign_dashboard_model.dart';
export 'campaign_dashboard_model.dart';

/// Owner-facing dashboard for the marketing engine.
///
/// Streams the signed-in owner's `marketing_campaigns` (newest first) and
/// renders the live, server-maintained counters (referral_count,
/// qualified_referral_count, reward_granted_count, impression_count,
/// click_count) that processReferral / logCampaignEvent keep up to date -
/// so the numbers here are always the same source of truth the Cloud
/// Functions write, never a client re-computation.
///
/// Each active referral campaign embeds a [ReferralShareWidget] so the
/// owner can grab and share their own invite code from the same screen.
class CampaignDashboardWidget extends StatefulWidget {
  const CampaignDashboardWidget({super.key});

  static String routeName = 'CampaignDashboard';
  static String routePath = '/campaignDashboard';

  @override
  State<CampaignDashboardWidget> createState() =>
      _CampaignDashboardWidgetState();
}

class _CampaignDashboardWidgetState extends State<CampaignDashboardWidget> {
  late CampaignDashboardModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CampaignDashboardModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final userRef = currentUserReference;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        automaticallyImplyLeading: false,
        elevation: 0.0,
        leading: FlutterFlowIconButton(
          borderRadius: 20.0,
          buttonSize: 44.0,
          icon: Icon(Icons.arrow_back_rounded,
              color: theme.primaryText, size: 24.0),
          onPressed: () => context.safePop(),
        ),
        title: Text('Campaign Dashboard', style: theme.headlineSmall),
        centerTitle: false,
      ),
      body: SafeArea(
        child: userRef == null
            ? _centered(theme, 'Please sign in to view your campaigns.')
            : StreamBuilder<List<MarketingCampaignsRecord>>(
                stream: queryMarketingCampaignsRecord(
                  queryBuilder: (q) => q
                      .where('owner_ref', isEqualTo: userRef)
                      .orderBy('created_at', descending: true),
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: SizedBox(
                        height: 32.0,
                        width: 32.0,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    );
                  }
                  final campaigns = snapshot.data!;
                  if (campaigns.isEmpty) {
                    return _centered(
                      theme,
                      'No campaigns yet.\nCreate one to start tracking referrals and promos.',
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 32.0),
                    children: [
                      _aggregateHeader(theme, campaigns),
                      const SizedBox(height: 16.0),
                      ...campaigns
                          .map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: _campaignCard(theme, c),
                              ))
                          .toList(),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _centered(FlutterFlowTheme theme, String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.bodyMedium.override(
              fontFamily: theme.bodyMedium.fontFamily,
              color: theme.secondaryText,
            ),
          ),
        ),
      );

  Widget _aggregateHeader(
      FlutterFlowTheme theme, List<MarketingCampaignsRecord> campaigns) {
    var referrals = 0;
    var rewarded = 0;
    var impressions = 0;
    var active = 0;
    for (final c in campaigns) {
      referrals += c.referralCount;
      rewarded += c.rewardGrantedCount;
      impressions += c.impressionCount;
      if (c.status == 'active') active++;
    }
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primary, theme.secondary],
          begin: const Alignment(-1.0, -1.0),
          end: const Alignment(1.0, 1.0),
        ),
        borderRadius: BorderRadius.circular(16.0),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$active active campaign${active == 1 ? '' : 's'}',
            style: theme.labelMedium.override(
              fontFamily: theme.labelMedium.fontFamily,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 12.0),
          Row(
            children: [
              _headerStat(theme, referrals.toString(), 'Referrals'),
              _headerStat(theme, rewarded.toString(), 'Rewarded'),
              _headerStat(theme, _compact(impressions), 'Impressions'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(FlutterFlowTheme theme, String value, String label) =>
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.headlineMedium.override(
                fontFamily: theme.headlineMedium.fontFamily,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: theme.bodySmall.override(
                fontFamily: theme.bodySmall.fontFamily,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
      );

  Widget _campaignCard(
      FlutterFlowTheme theme, MarketingCampaignsRecord c) {
    final conversion = c.referralCount > 0
        ? (c.rewardGrantedCount / c.referralCount * 100).toStringAsFixed(0)
        : '—';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: theme.alternate, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.title.isNotEmpty ? c.title : 'Untitled campaign',
                    style: theme.titleMedium,
                  ),
                ),
                _statusChip(theme, c.status),
              ],
            ),
            if (c.targetRegions.isNotEmpty) ...[
              const SizedBox(height: 4.0),
              Text(
                c.targetRegions.join(' • '),
                style: theme.bodySmall.override(
                  fontFamily: theme.bodySmall.fontFamily,
                  color: theme.secondaryText,
                ),
              ),
            ],
            const SizedBox(height: 16.0),
            // Metric grid
            Wrap(
              spacing: 24.0,
              runSpacing: 14.0,
              children: [
                _metric(theme, c.referralCount.toString(), 'Redemptions'),
                _metric(theme, c.qualifiedReferralCount.toString(), 'Qualified'),
                _metric(theme, c.rewardGrantedCount.toString(), 'Rewarded'),
                _metric(theme, '$conversion%', 'Conversion'),
                _metric(theme, _compact(c.impressionCount), 'Impressions'),
                _metric(theme, _compact(c.clickCount), 'Clicks'),
              ],
            ),
            if (c.type == 'referral' && c.status == 'active') ...[
              const SizedBox(height: 18.0),
              ReferralShareWidget(
                key: ValueKey('share_${c.reference.path}'),
                campaignRef: c.reference,
                campaignTitle: 'Share “${c.title}”',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metric(FlutterFlowTheme theme, String value, String label) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.titleLarge.override(
              fontFamily: theme.titleLarge.fontFamily,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: theme.bodySmall.override(
              fontFamily: theme.bodySmall.fontFamily,
              color: theme.secondaryText,
            ),
          ),
        ],
      );

  Widget _statusChip(FlutterFlowTheme theme, String status) {
    Color bg;
    switch (status) {
      case 'active':
        bg = theme.success;
        break;
      case 'paused':
        bg = theme.warning;
        break;
      case 'ended':
        bg = theme.secondaryText;
        break;
      default:
        bg = theme.alternate;
    }
    return Container(
      decoration: BoxDecoration(
        color: bg.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: bg, width: 1.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
      child: Text(
        status.isNotEmpty ? status[0].toUpperCase() + status.substring(1) : '—',
        style: theme.labelSmall.override(
          fontFamily: theme.labelSmall.fontFamily,
          color: bg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Compact large counts (1200 -> 1.2k) for the metric tiles.
  String _compact(int n) {
    if (n < 1000) return n.toString();
    if (n < 1000000) return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    return '${(n / 1000000).toStringAsFixed(1)}M';
  }
}
