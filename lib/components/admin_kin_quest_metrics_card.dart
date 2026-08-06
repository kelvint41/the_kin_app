import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/services/kin_services.dart';

/// Executive Dashboard card for everything added this session under the
/// KIN Quest map/scoring rebuild: real check-ins, the mystery-tier random
/// points, the unlisted-business discovery bonus, the Black-owned
/// ownership survey, and Small Business Saturday's boost - plus an export
/// button covering not just this card but the full getOperationsStats
/// payload (activity/engagement/Kindex/claims/reviews too), since none of
/// that had anywhere to be exported from before this.
///
/// Loads once (a manual refresh icon re-fetches) rather than a live
/// stream - these are admin-review numbers checked periodically, not a
/// counter that needs to tick in real time, and getOperationsStats itself
/// is a callable, not a listenable source.
class AdminKinQuestMetricsCard extends StatefulWidget {
  const AdminKinQuestMetricsCard({super.key});

  @override
  State<AdminKinQuestMetricsCard> createState() =>
      _AdminKinQuestMetricsCardState();
}

class _AdminKinQuestMetricsCardState extends State<AdminKinQuestMetricsCard> {
  OperationsStats? _stats;
  bool _loading = true;
  bool _exporting = false;
  String? _error;

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
    final result = await KinServices.getOperationsStats();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _stats = result.data;
      } else {
        _error = result.error;
      }
    });
  }

  Future<void> _exportCsv() async {
    final stats = _stats;
    if (stats == null || _exporting) return;
    setState(() => _exporting = true);
    try {
      final rows = stats.toCsvRows();
      final csv = rows
          .map((row) => row.map(_csvEscape).join(','))
          .join('\r\n');
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File('${dir.path}/kin_operations_stats_$timestamp.csv');
      await file.writeAsString(csv);
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'KIN operations stats export',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't export right now.")),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final stats = _stats;

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
                    '🧭 KIN Quest Activity',
                    style: theme.titleSmall.override(
                      font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                      color: theme.primaryText,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  icon: Icon(Icons.refresh_rounded, size: 20.0, color: theme.secondaryText),
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
                child: Text(_error!,
                    style: theme.bodySmall.override(color: theme.error)),
              )
            else if (stats != null) ...[
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 1.5,
                children: [
                  _tile(theme,
                      label: 'Check-ins',
                      value: '${stats.checkinsWithPoints ?? '—'}',
                      icon: '📍',
                      color: theme.primary),
                  _tile(theme,
                      label: 'Mystery Finds',
                      value: '${stats.mysteryFinds ?? '—'}',
                      icon: '❓',
                      color: Colors.amber),
                  _tile(theme,
                      label: 'Unlisted Discoveries',
                      value: '${stats.discoveriesApproved}',
                      icon: '🆕',
                      color: Colors.blue),
                  _tile(theme,
                      label: 'Ownership Reports',
                      value: '${stats.ownershipReportsTotal ?? '—'}',
                      icon: '🏷️',
                      color: Colors.purple),
                ],
              ),
              const SizedBox(height: 12.0),
              Divider(color: theme.alternate, height: 12.0),
              const SizedBox(height: 12.0),
              _summaryRow(theme, 'Total scavenger points (check-ins)',
                  '${stats.checkinPointsTotal}'),
              _summaryRow(theme, 'Discovery bonus points paid',
                  '${stats.discoveryPointsTotal}'),
              if (stats.smallBusinessSaturdayPoints > 0)
                _summaryRow(theme, '🟣 Small Business Saturday points',
                    '${stats.smallBusinessSaturdayPoints}'),
              _summaryRow(
                theme,
                'Says Black-owned / says not',
                '${stats.ownershipReportsBlackOwned} / ${stats.ownershipReportsNotBlackOwned}',
              ),
              _summaryRow(theme, 'Business submissions pending review',
                  '${stats.submissionsPending ?? '—'}'),
              const SizedBox(height: 12.0),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _exporting ? null : _exportCsv,
                  icon: _exporting
                      ? SizedBox(
                          width: 14.0,
                          height: 14.0,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.0, color: theme.primary),
                        )
                      : Icon(Icons.ios_share_rounded, size: 16.0, color: theme.primary),
                  label: Text(
                    _exporting ? 'Exporting...' : 'Export all stats to CSV',
                    style: theme.bodySmall.override(
                        font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                        color: theme.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.primary.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(FlutterFlowTheme theme, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(label,
                  style: theme.bodySmall.override(
                      font: GoogleFonts.plusJakartaSans(),
                      color: theme.secondaryText,
                      letterSpacing: 0.0)),
            ),
            Text(value,
                style: theme.bodySmall.override(
                    font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                    color: theme.primaryText,
                    fontWeight: FontWeight.bold)),
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
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20.0)),
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
