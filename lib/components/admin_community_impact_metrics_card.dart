import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/services/community_impact_stats_service.dart';

/// Executive Dashboard card for the Community Impact & Spend Tracker's
/// community-wide totals.
///
/// Reads `community_impact_stats/aggregate`, maintained server-side by
/// spend_log_aggregate.js's onCreate/onDelete triggers on `spend_logs` -
/// never the `spend_logs` collection itself, which firestore.rules keeps
/// strictly owner-only. Every number here is a total with zero per-user
/// attribution, by design: what an individual customer spent is never
/// readable by anyone but themselves, not even here. See that rules file's
/// comment on `spend_logs` for the product decision this card is built
/// around.
///
/// Loads once (a manual refresh icon re-fetches), same as
/// AdminKinQuestMetricsCard - an admin-review number checked
/// periodically, not one that needs to tick live.
class AdminCommunityImpactMetricsCard extends StatefulWidget {
  const AdminCommunityImpactMetricsCard({super.key});

  @override
  State<AdminCommunityImpactMetricsCard> createState() =>
      _AdminCommunityImpactMetricsCardState();
}

class _AdminCommunityImpactMetricsCardState
    extends State<AdminCommunityImpactMetricsCard> {
  static const _topN = 5;
  final _currency = NumberFormat.simpleCurrency(locale: 'en_US');

  bool _loading = true;
  String? _error;
  CommunityImpactAggregate _aggregate = CommunityImpactAggregate.empty;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final aggregate = await fetchCommunityImpactAggregate(topN: _topN);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _aggregate = aggregate;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Couldn't load community impact totals right now.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.alternate, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '💚 Community Impact',
                    style: theme.titleSmall.override(
                      font: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold),
                      color: theme.primaryText,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  icon: Icon(Icons.refresh_rounded,
                      size: 20.0, color: theme.secondaryText),
                  onPressed: _loading ? null : _load,
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            if (_loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                  child: SizedBox(
                    width: 22.0,
                    height: 22.0,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.0, color: theme.secondaryText),
                  ),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child:
                    Text(_error!, style: theme.bodySmall.override(color: theme.error)),
              )
            else if (_aggregate.totalEntries == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'No visits or spend logged yet. This fills in as '
                  'customers use "Log a Visit / Spend".',
                  style: theme.bodySmall.override(
                    color: theme.secondaryText,
                    lineHeight: 1.4,
                  ),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _tile(theme,
                        label: 'Total Spend Logged',
                        value: _currency.format(_aggregate.totalSpend),
                        icon: '💵',
                        color: theme.primary),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: _tile(theme,
                        label: 'Visits Logged',
                        value: '${_aggregate.totalEntries}',
                        icon: '📝',
                        color: theme.secondary),
                  ),
                ],
              ),
              if (_aggregate.topCities.isNotEmpty) ...[
                const SizedBox(height: 12.0),
                Divider(color: theme.alternate, height: 12.0),
                const SizedBox(height: 8.0),
                Text(
                  'Top Cities by Spend',
                  style: theme.labelMedium.override(
                    font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                    color: theme.secondaryText,
                    letterSpacing: 0.0,
                  ),
                ),
                const SizedBox(height: 6.0),
                ..._aggregate.topCities.map((e) => _rankRow(theme, e)),
              ],
              if (_aggregate.topCategories.isNotEmpty) ...[
                const SizedBox(height: 12.0),
                Divider(color: theme.alternate, height: 12.0),
                const SizedBox(height: 8.0),
                Text(
                  'Top Categories by Spend',
                  style: theme.labelMedium.override(
                    font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                    color: theme.secondaryText,
                    letterSpacing: 0.0,
                  ),
                ),
                const SizedBox(height: 6.0),
                ..._aggregate.topCategories.map((e) => _rankRow(theme, e)),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _rankRow(FlutterFlowTheme theme, RankedTotal entry) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                entry.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.bodySmall.override(
                  font: GoogleFonts.plusJakartaSans(),
                  color: theme.primaryText,
                  letterSpacing: 0.0,
                ),
              ),
            ),
            Text(
              _currency.format(entry.total),
              style: theme.bodySmall.override(
                font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                color: theme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  Widget _tile(
    FlutterFlowTheme theme, {
    required String label,
    required String value,
    required String icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18.0)),
            const SizedBox(height: 4.0),
            Text(
              value,
              style: theme.titleSmall.override(
                font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                color: color,
                letterSpacing: 0.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2.0),
            Text(
              label,
              style: theme.labelSmall.override(
                font: GoogleFonts.plusJakartaSans(),
                color: theme.secondaryText,
                fontSize: 10.0,
                letterSpacing: 0.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
