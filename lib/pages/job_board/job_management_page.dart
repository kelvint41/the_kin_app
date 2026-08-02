import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/backend.dart';

class JobManagementPage extends StatefulWidget {
  const JobManagementPage({super.key});

  @override
  State<JobManagementPage> createState() => _JobManagementPageState();
}

class _JobManagementPageState extends State<JobManagementPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

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
            'My Job Postings',
            style: theme.headlineMedium.override(
              font: GoogleFonts.plusJakartaSans(
                color: theme.info,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          centerTitle: false,
          elevation: 0.0,
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 16.0, 0.0),
              child: IconButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/jobCreate');
                },
                icon: const Icon(Icons.add),
                color: theme.info,
              ),
            ),
          ],
        ),
        body: StreamBuilder<List<JobPostingsRecord>>(
          stream: JobPostingsRecord.collection
              .where('business_ref', isEqualTo: null) // Should be current business
              .snapshots()
              .map((snapshot) => snapshot.docs
                  .map((doc) => JobPostingsRecord.fromSnapshot(doc))
                  .toList()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: theme.primary),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.work_outline, size: 48, color: theme.secondaryText),
                    const SizedBox(height: 16),
                    Text(
                      'No job postings yet',
                      style: theme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FFButtonWidget(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/jobCreate');
                      },
                      text: 'Create Your First Job',
                      options: FFButtonOptions(
                        width: 200,
                        height: 44,
                        color: theme.primary,
                        textStyle: theme.labelSmall.override(
                          color: theme.info,
                          fontWeight: FontWeight.w600,
                        ),
                        elevation: 0.0,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ],
                ),
              );
            }

            final jobs = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.secondaryBackground,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: theme.alternate),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: theme.titleSmall.override(
                            font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: theme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              child: Text(
                                '${job.applicationsCount} applicants',
                                style: theme.labelSmall.override(
                                  color: theme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              job.isActive ? 'Active' : 'Closed',
                              style: theme.labelSmall.override(
                                color: job.isActive ? theme.success : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            FFButtonWidget(
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  '/jobApplicants',
                                  arguments: {'jobRef': job.reference},
                                );
                              },
                              text: 'View Applicants',
                              options: FFButtonOptions(
                                width: 120,
                                height: 36,
                                color: theme.primary.withOpacity(0.1),
                                textStyle: theme.labelSmall.override(
                                  color: theme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                elevation: 0.0,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            PopupMenuButton(
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: Text('Edit'),
                                  onTap: () {
                                    Navigator.of(context).pushNamed(
                                      '/jobEdit',
                                      arguments: {'jobRef': job.reference},
                                    );
                                  },
                                ),
                                PopupMenuItem(
                                  child: Text('Close'),
                                  onTap: () {},
                                ),
                                PopupMenuItem(
                                  child: Text('Delete'),
                                  onTap: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
