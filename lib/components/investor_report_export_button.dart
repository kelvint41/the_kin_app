import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/services/investor_report_pdf.dart';

/// Executive Dashboard AppBar action - gathers the same numbers already
/// shown on the dashboard's own cards (System Overview's counts,
/// AdminCommunityImpactMetricsCard's totals) into a polished PDF and hands
/// it to the OS share sheet, for sending to investors or presenting live.
///
/// Self-contained: owns its own loading state rather than routing through
/// ExecutiveDashboardModel, the same way MainMenuButton and the refresh
/// button next to it in the AppBar are self-contained.
class InvestorReportExportButton extends StatefulWidget {
  const InvestorReportExportButton({super.key});

  @override
  State<InvestorReportExportButton> createState() =>
      _InvestorReportExportButtonState();
}

class _InvestorReportExportButtonState
    extends State<InvestorReportExportButton> {
  bool _exporting = false;

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final data = await gatherInvestorReportData();
      await exportInvestorReportPdf(data);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Couldn't generate the report right now.")),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    if (_exporting) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: 24.0,
          height: 24.0,
          child: CircularProgressIndicator(
              strokeWidth: 2.0, color: theme.primaryText),
        ),
      );
    }
    return FlutterFlowIconButton(
      borderRadius: 8.0,
      buttonSize: 40.0,
      fillColor: Colors.transparent,
      icon: Icon(
        Icons.picture_as_pdf_rounded,
        color: theme.primaryText,
        size: 24.0,
      ),
      onPressed: _export,
    );
  }
}
