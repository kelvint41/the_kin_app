import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/backend.dart';
import 'job_detail_page_model.dart';

export 'job_detail_page_model.dart';

class JobDetailPage extends StatefulWidget {
  final DocumentReference jobRef;

  const JobDetailPage({super.key, required this.jobRef});

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  late JobDetailPageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => JobDetailPageModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        appBar: AppBar(
          backgroundColor: theme.primary,
          automaticallyImplyLeading: true,
          title: Text(
            'Job Details',
            style: theme.headlineMedium.override(
              font: GoogleFonts.plusJakartaSans(
                color: theme.info,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          centerTitle: false,
          elevation: 0.0,
        ),
        body: StreamBuilder<JobPostingsRecord>(
          stream: JobPostingsRecord.getDocument(widget.jobRef),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: theme.primary),
              );
            }
            if (!snapshot.hasData) {
              return Center(
                child: Text('Job not found', style: theme.bodyMedium),
              );
            }

            final job = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.secondaryBackground,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16.0),
                        bottomRight: Radius.circular(16.0),
                      ),
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: theme.headlineSmall.override(
                            font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          job.businessName,
                          style: theme.titleSmall.override(
                            color: theme.primary,
                            font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: theme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 6.0,
                              ),
                              child: Text(
                                '\$${job.hourlyRate.toStringAsFixed(2)}/hr',
                                style: theme.labelSmall.override(
                                  color: theme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Container(
                              decoration: BoxDecoration(
                                color: theme.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 6.0,
                              ),
                              child: Text(
                                job.employmentType,
                                style: theme.labelSmall.override(
                                  color: theme.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // About section
                        Text(
                          'About This Job',
                          style: theme.titleSmall.override(
                            font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          job.description,
                          style: theme.bodyMedium,
                        ),

                        const SizedBox(height: 24.0),

                        // Requirements
                        Text(
                          'Requirements',
                          style: theme.titleSmall.override(
                            font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          job.requirements,
                          style: theme.bodyMedium,
                        ),

                        const SizedBox(height: 24.0),

                        // Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '${job.applicationsCount}',
                                  style: theme.headlineSmall.override(
                                    color: theme.primary,
                                    font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Applications',
                                  style: theme.labelSmall,
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  '${job.viewsCount ?? 0}',
                                  style: theme.headlineSmall.override(
                                    color: theme.primary,
                                    font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Views',
                                  style: theme.labelSmall,
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  job.createdAt.difference(DateTime.now()).inDays > 0
                                      ? '${job.createdAt.difference(DateTime.now()).inDays} days'
                                      : 'Today',
                                  style: theme.headlineSmall.override(
                                    color: theme.primary,
                                    font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Posted',
                                  style: theme.labelSmall,
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 32.0),

                        // Apply button
                        FFButtonWidget(
                          onPressed: () async {
                            Navigator.of(context).pushNamed(
                              '/jobApply',
                              arguments: {'jobRef': widget.jobRef},
                            );
                          },
                          text: 'Apply Now',
                          options: FFButtonOptions(
                            width: double.infinity,
                            height: 56.0,
                            padding:
                                const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                            color: theme.primary,
                            textStyle: theme.titleSmall.override(
                              font: GoogleFonts.plusJakartaSans(
                                color: theme.info,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            elevation: 0.0,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),

                        const SizedBox(height: 12.0),

                        // Save job button
                        FFButtonWidget(
                          onPressed: () async {
                            await _model.saveJob(widget.jobRef);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Job saved to your list'),
                              ),
                            );
                          },
                          text: 'Save Job',
                          options: FFButtonOptions(
                            width: double.infinity,
                            height: 56.0,
                            padding:
                                const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                            color: theme.secondaryBackground,
                            textStyle: theme.titleSmall.override(
                              font: GoogleFonts.plusJakartaSans(
                                color: theme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            elevation: 0.0,
                            borderRadius: BorderRadius.circular(12.0),
                            side: BorderSide(color: theme.primary, width: 2.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
