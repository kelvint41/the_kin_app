import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/job_board_service.dart';
import 'job_apply_page.dart';

class JobDetailPage extends StatefulWidget {
  final String jobId;

  const JobDetailPage({super.key, required this.jobId});

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  late Future<Map<String, dynamic>?> _jobFuture;

  @override
  void initState() {
    super.initState();
    _jobFuture = JobBoardService.getJobDetails(widget.jobId);
    JobBoardService.trackJobView(widget.jobId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        automaticallyImplyLeading: true,
        title: Text(
          'Job Details',
          style: theme.headlineMedium.override(
            font: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
            ),
            color: theme.info
          ),
        ),
        centerTitle: false,
        elevation: 0.0,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _jobFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: theme.primary),
            );
          }
          final job = snapshot.data;
          if (job == null) {
            return Center(
              child: Text('Job not found', style: theme.bodyMedium),
            );
          }

          final rateMin = (job['rateMin'] as num?)?.toDouble() ?? 0;
          final rateMax = (job['rateMax'] as num?)?.toDouble() ?? 0;
          final applicationCount = job['applicationCount'] as int? ?? 0;
          final viewCount = job['viewCount'] as int? ?? 0;
          final tags = (job['tags'] as List?)?.cast<String>() ?? const [];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job['title'] as String? ?? 'Untitled',
                    style: theme.headlineSmall,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    job['location'] as String? ?? '',
                    style:
                        theme.bodyMedium.override(color: theme.secondaryText),
                  ),
                  const SizedBox(height: 16.0),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 6.0),
                    child: Text(
                      '\$${rateMin.toStringAsFixed(0)}-\$${rateMax.toStringAsFixed(0)}/hr',
                      style: theme.titleSmall.override(
                        color: theme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Row(
                    children: [
                      _buildStat(theme, '$applicationCount', 'Applications'),
                      const SizedBox(width: 24.0),
                      _buildStat(theme, '$viewCount', 'Views'),
                    ],
                  ),
                  const SizedBox(height: 24.0),
                  Text('About This Job',
                      style: theme.titleSmall
                          .override(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8.0),
                  Text(
                    job['description'] as String? ?? '',
                    style: theme.bodyMedium,
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 24.0),
                    Text('Tags',
                        style: theme.titleSmall
                            .override(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8.0),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: tags
                          .map((tag) => Chip(
                                label: Text(tag, style: theme.labelSmall),
                                backgroundColor: theme.alternate,
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 32.0),
                  FFButtonWidget(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => JobApplyPage(jobId: widget.jobId),
                        ),
                      );
                    },
                    text: 'Apply Now',
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 56.0,
                      color: theme.primary,
                      textStyle: theme.titleSmall.override(
                        font: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                        ),
                        color: theme.info
                      ),
                      elevation: 0.0,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStat(FlutterFlowTheme theme, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: theme.titleMedium.override(fontWeight: FontWeight.w700)),
        Text(label,
            style: theme.labelSmall.override(color: theme.secondaryText)),
      ],
    );
  }
}
