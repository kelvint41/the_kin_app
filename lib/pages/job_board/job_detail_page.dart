import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
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

          final applicationCount = job['applicationCount'] as int? ?? 0;
          final viewCount = job['viewCount'] as int? ?? 0;
          final tags = (job['tags'] as List?)?.cast<String>() ?? const [];
          final requirements = job['requirements'] as String? ?? '';
          final workLocation = job['workLocation'] as String? ?? 'on_site';
          final jobTypeLabel = _jobTypeLabel(job['jobType'] as String?);
          final locationLabel = workLocation == 'remote'
              ? 'Remote'
              : [
                  job['location'] as String? ?? '',
                  if (workLocation == 'hybrid') '(Hybrid)',
                ].where((s) => s.isNotEmpty).join(' ');

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
                    [locationLabel, jobTypeLabel]
                        .where((s) => s.isNotEmpty)
                        .join(' · '),
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
                      JobBoardService.formatPay(job),
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
                  if (requirements.isNotEmpty) ...[
                    const SizedBox(height: 24.0),
                    Text('Requirements',
                        style: theme.titleSmall
                            .override(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8.0),
                    Text(requirements, style: theme.bodyMedium),
                  ],
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
                    onPressed: () => _apply(job),
                    text: _applyLabel(job['applyMethod'] as String?),
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

  static String _jobTypeLabel(String? raw) {
    switch (raw) {
      case 'full_time':
        return 'Full-time';
      case 'part_time':
        return 'Part-time';
      case 'contract':
        return 'Contract';
      case 'seasonal':
        return 'Seasonal';
      default:
        return '';
    }
  }

  static String _applyLabel(String? method) {
    switch (method) {
      case 'email':
        return 'Email your application';
      case 'website':
        return 'Apply on their website';
      default:
        return 'Apply Now';
    }
  }

  /// Sends the candidate wherever the owner asked to receive applications.
  ///
  /// For email and website the app hands off and stops: KIN takes no
  /// resume and keeps no applicant file, so there is nothing to collect
  /// here first. Only the in-app route stays inside the app, and that one
  /// is a message thread, not a file upload.
  Future<void> _apply(Map<String, dynamic> job) async {
    final method = job['applyMethod'] as String? ?? 'in_app';

    if (method == 'email') {
      final email = (job['applyEmail'] as String? ?? '').trim();
      if (email.isNotEmpty) {
        final subject = Uri.encodeComponent(
            'Application: ${job['title'] as String? ?? 'your opening'}');
        final launched = await launchUrl(
          Uri.parse('mailto:$email?subject=$subject'),
          mode: LaunchMode.externalApplication,
        );
        if (launched || !mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Send your application to $email')),
        );
        return;
      }
    }

    if (method == 'website') {
      final url = (job['applyUrl'] as String? ?? '').trim();
      final uri = Uri.tryParse(url);
      if (uri != null && url.isNotEmpty) {
        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched || !mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't open that link.")),
        );
        return;
      }
    }

    // in_app, or a malformed email/website posting - the message thread is
    // always a working fallback rather than a dead button.
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => JobApplyPage(jobId: widget.jobId)),
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
