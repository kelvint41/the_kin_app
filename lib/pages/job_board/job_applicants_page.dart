import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/job_board_service.dart';
import 'job_messages_page.dart';

class JobApplicantsPage extends StatefulWidget {
  final String jobId;

  const JobApplicantsPage({super.key, required this.jobId});

  @override
  State<JobApplicantsPage> createState() => _JobApplicantsPageState();
}

class _JobApplicantsPageState extends State<JobApplicantsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        automaticallyImplyLeading: true,
        title: Text(
          'Applicants',
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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: JobBoardService.getJobApplications(widget.jobId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: theme.primary),
            );
          }
          final applications = snapshot.data ?? [];
          if (applications.isEmpty) {
            return Center(
              child: Text('No applicants yet', style: theme.bodyMedium),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final app = applications[index];
              final status = app['status'] as String? ?? 'pending';
              final appliedAt = app['appliedAt'];
              String appliedLabel = '';
              if (appliedAt != null && appliedAt is Timestamp) {
                final days =
                    DateTime.now().difference(appliedAt.toDate()).inDays;
                appliedLabel =
                    days <= 0 ? 'Applied today' : 'Applied $days days ago';
              }
              final applicantRef = app['applicantRef'];
              final applicantName =
                  app['applicantName'] as String? ?? 'Applicant';

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
                        applicantName,
                        style: theme.titleSmall.override(
                          font: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(app['applicantEmail'] as String? ?? '',
                          style: theme.bodySmall),
                      Text(app['applicantPhone'] as String? ?? '',
                          style: theme.bodySmall),
                      const SizedBox(height: 12.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            status[0].toUpperCase() + status.substring(1),
                            style: theme.labelSmall.override(
                              color: status == 'accepted'
                                  ? theme.success
                                  : status == 'rejected'
                                      ? Colors.red
                                      : theme.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            appliedLabel,
                            style: theme.labelSmall
                                .override(color: theme.secondaryText),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),
                      FFButtonWidget(
                        onPressed: applicantRef == null
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => JobMessagesPage(
                                      applicationId: app['id'] as String,
                                      otherUserId: applicantRef.id as String,
                                      otherUserName: applicantName,
                                    ),
                                  ),
                                );
                              },
                        text: 'Message',
                        options: FFButtonOptions(
                          width: double.infinity,
                          height: 40.0,
                          color: theme.primary.withOpacity(0.1),
                          textStyle: theme.labelSmall.override(
                            color: theme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          elevation: 0.0,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
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
