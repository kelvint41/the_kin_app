import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '/backend/backend.dart';
import '/services/community_impact_stats_service.dart';

// Brand colors, matching flutter_flow_theme.dart's DarkModeTheme.primary/
// secondary - a printed/shared PDF is read outside the app on a fixed
// light background regardless of the viewer's own theme setting, so this
// intentionally doesn't try to follow light/dark mode the way the in-app
// screens do.
final _forestGreen = PdfColor.fromHex('#0B3D2E');
final _gold = PdfColor.fromHex('#C5A059');
final _ink = PdfColor.fromHex('#241F17');
final _inkSoft = PdfColor.fromHex('#6B6152');
final _rule = PdfColor.fromHex('#D9D1C2');

/// Everything the investor report needs, gathered once up front so the
/// document-building function itself stays synchronous and side-effect
/// free.
class InvestorReportData {
  const InvestorReportData({
    required this.totalBusinesses,
    required this.blackOwnedCount,
    required this.premiumCount,
    required this.impact,
  });

  final int totalBusinesses;
  final int blackOwnedCount;
  final int premiumCount;
  final CommunityImpactAggregate impact;
}

/// Gathers the report's numbers from the same sources the Executive
/// Dashboard's own cards read - queryBusinessesRecordCount for the
/// directory counts (see the System Overview KPI row), and
/// fetchCommunityImpactAggregate for spend (see
/// AdminCommunityImpactMetricsCard) - so the PDF can never show a
/// different number than what's already on screen.
Future<InvestorReportData> gatherInvestorReportData() async {
  final results = await Future.wait([
    queryBusinessesRecordCount(),
    queryBusinessesRecordCount(
      queryBuilder: (q) => q.where('is_black_owned', isEqualTo: true),
    ),
    queryBusinessesRecordCount(
      queryBuilder: (q) => q.where('is_premium', isEqualTo: true),
    ),
  ]);
  final impact = await fetchCommunityImpactAggregate(topN: 8);

  return InvestorReportData(
    totalBusinesses: results[0],
    blackOwnedCount: results[1],
    premiumCount: results[2],
    impact: impact,
  );
}

/// Builds the investor-facing PDF from already-gathered [data]. Kept
/// separate from [gatherInvestorReportData] so this half - the actual
/// layout - can be iterated on and tested without hitting Firestore.
pw.Document buildInvestorReportPdf(InvestorReportData data) {
  final currency = NumberFormat.simpleCurrency(locale: 'en_US');
  final generatedAt = DateFormat.yMMMMd().add_jm().format(DateTime.now());
  final doc = pw.Document(
    title: 'The KIN App - Community Impact Report',
    author: 'KINVEST GUIDANCE LLC',
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.fromLTRB(40, 48, 40, 40),
      header: (context) => context.pageNumber == 1
          ? pw.SizedBox()
          : pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Text(
                'The KIN App - Community Impact Report',
                style: pw.TextStyle(color: _inkSoft, fontSize: 8),
              ),
            ),
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 12),
        child: pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: pw.TextStyle(color: _inkSoft, fontSize: 8),
        ),
      ),
      build: (context) => [
        _titleBlock(generatedAt),
        pw.SizedBox(height: 28),
        _sectionHeading('Directory Overview'),
        pw.SizedBox(height: 10),
        pw.Row(children: [
          _statTile('Total Businesses', '${data.totalBusinesses}'),
          pw.SizedBox(width: 12),
          _statTile('Black-Owned', '${data.blackOwnedCount}'),
          pw.SizedBox(width: 12),
          _statTile('Premium Tier', '${data.premiumCount}'),
        ]),
        pw.SizedBox(height: 28),
        _sectionHeading('Community Impact'),
        pw.SizedBox(height: 6),
        pw.Text(
          'Aggregate totals only. No individual customer\'s spending is '
          'included or attributable - see note at the end of this report.',
          style: pw.TextStyle(
              color: _inkSoft, fontSize: 8, fontStyle: pw.FontStyle.italic),
        ),
        pw.SizedBox(height: 10),
        pw.Row(children: [
          _statTile(
              'Total Spend Logged', currency.format(data.impact.totalSpend)),
          pw.SizedBox(width: 12),
          _statTile('Visits Logged', '${data.impact.totalEntries}'),
        ]),
        if (data.impact.topCities.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          _rankedTable('Top Cities by Spend', data.impact.topCities, currency),
        ],
        if (data.impact.topCategories.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          _rankedTable(
              'Top Categories by Spend', data.impact.topCategories, currency),
        ],
        pw.SizedBox(height: 32),
        pw.Divider(color: _rule),
        pw.SizedBox(height: 8),
        pw.Text(
          'Community Impact figures reflect self-reported visits and '
          'spend logged by customers in the KIN app. Figures are '
          'aggregate totals with zero per-customer attribution by design '
          '- individual spending is private to each customer and is '
          'never collected into this or any other report.',
          style: pw.TextStyle(color: _inkSoft, fontSize: 8, lineSpacing: 2),
        ),
      ],
    ),
  );

  return doc;
}

pw.Widget _titleBlock(String generatedAt) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'The KIN App',
          style: pw.TextStyle(
              color: _forestGreen, fontSize: 26, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Community Impact Report',
          style: pw.TextStyle(color: _gold, fontSize: 16),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Prepared by KINVEST GUIDANCE LLC  ·  Generated $generatedAt',
          style: pw.TextStyle(color: _inkSoft, fontSize: 9),
        ),
        pw.SizedBox(height: 14),
        pw.Divider(color: _forestGreen, thickness: 1.5),
      ],
    );

pw.Widget _sectionHeading(String text) => pw.Text(
      text,
      style: pw.TextStyle(
          color: _forestGreen, fontSize: 13, fontWeight: pw.FontWeight.bold),
    );

pw.Widget _statTile(String label, String value) => pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _rule),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(value,
                style: pw.TextStyle(
                    color: _forestGreen,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text(label, style: pw.TextStyle(color: _inkSoft, fontSize: 9)),
          ],
        ),
      ),
    );

pw.Widget _rankedTable(
  String title,
  List<RankedTotal> entries,
  NumberFormat currency,
) =>
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(
                color: _ink, fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder(
            horizontalInside: pw.BorderSide(color: _rule, width: 0.5),
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(1),
          },
          children: entries
              .map((e) => pw.TableRow(children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 5),
                      child: pw.Text(e.label,
                          style: pw.TextStyle(color: _ink, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 5),
                      child: pw.Text(
                        currency.format(e.total),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            color: _gold,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ]))
              .toList(),
        ),
      ],
    );

/// Builds and hands the report to the OS share/print/save sheet in one
/// call - what the Executive Dashboard's export button uses.
Future<void> exportInvestorReportPdf(InvestorReportData data) async {
  final doc = buildInvestorReportPdf(data);
  final bytes = await doc.save();
  final stamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
  await Printing.sharePdf(
    bytes: bytes,
    filename: 'kin_community_impact_report_$stamp.pdf',
  );
}
