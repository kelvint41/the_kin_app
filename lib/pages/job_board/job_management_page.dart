import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/services/job_board_service.dart';
import 'job_applicants_page.dart';
import 'job_create_page.dart';

class JobManagementPage extends StatefulWidget {
  const JobManagementPage({super.key});

  static String routeName = 'JobManagement';
  static String routePath = '/jobManagement';

  @override
  State<JobManagementPage> createState() => _JobManagementPageState();
}

class _JobManagementPageState extends State<JobManagementPage> {
  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final businessId = currentUserDocument?.ownedBusiness?.id;

    return Scaffold(
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
              onPressed: businessId == null
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              JobCreatePage(businessId: businessId),
                        ),
                      );
                    },
              icon: const Icon(Icons.add),
              color: theme.info,
            ),
          ),
        ],
      ),
      body: businessId == null
          ? Center(
              child: Text('Set up your business to post jobs',
                  style: theme.bodyMedium),
            )
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: JobBoardService.getBusinessJobs(businessId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: theme.primary),
                  );
                }
                final jobs = snapshot.data ?? [];
                if (jobs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.work_outline,
                            size: 48, color: theme.secondaryText),
                        const SizedBox(height: 16),
                        Text('No job postings yet', style: theme.bodyMedium),
                        const SizedBox(height: 16),
                        FFButtonWidget(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    JobCreatePage(businessId: businessId),
                              ),
                            );
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

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    final status = job['status'] as String? ?? 'active';
                    final applicationCount =
                        job['applicationCount'] as int? ?? 0;
                    final jobId = job['id'] as String;

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
                              job['title'] as String? ?? 'Untitled',
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
                                      horizontal: 8.0, vertical: 4.0),
                                  child: Text(
                                    '$applicationCount applicants',
                                    style: theme.labelSmall.override(
                                      color: theme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Text(
                                  status == 'active' ? 'Active' : 'Closed',
                                  style: theme.labelSmall.override(
                                    color: status == 'active'
                                        ? theme.success
                                        : Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12.0),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                FFButtonWidget(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            JobApplicantsPage(jobId: jobId),
                                      ),
                                    );
                                  },
                                  text: 'View Applicants',
                                  options: FFButtonOptions(
                                    width: 140,
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
                                PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'close') {
                                      await JobBoardService.updateJobStatus(
                                          jobId, 'closed');
                                    } else if (value == 'delete') {
                                      await JobBoardService.deleteJob(jobId);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'close',
                                      child: Text('Close'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
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
    );
  }
}
