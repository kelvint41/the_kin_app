import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/backend.dart';

class JobApplicantsPage extends StatefulWidget {
  final DocumentReference jobRef;

  const JobApplicantsPage({super.key, required this.jobRef});

  @override
  State<JobApplicantsPage> createState() => _JobApplicantsPageState();
}

class _JobApplicantsPageState extends State<JobApplicantsPage> {
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
        body: StreamBuilder<List<JobApplicationsRecord>>(
          stream: JobApplicationsRecord.collection
              .where('job_ref', isEqualTo: widget.jobRef)
              .snapshots()
              .map((snapshot) => snapshot.docs
                  .map((doc) => JobApplicationsRecord.fromSnapshot(doc))
                  .toList()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: theme.primary),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text('No applicants yet', style: theme.bodyMedium),
              );
            }

            final applications = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: applications.length,
              itemBuilder: (context, index) {
                final app = applications[index];
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
                          app.applicantName,
                          style: theme.titleSmall.override(
                            font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          app.applicantEmail,
                          style: theme.bodySmall,
                        ),
                        Text(
                          app.applicantPhone,
                          style: theme.bodySmall,
                        ),
                        const SizedBox(height: 12.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              app.status,
                              style: theme.labelSmall.override(
                                color: app.status == 'Accepted'
                                    ? theme.success
                                    : app.status == 'Rejected'
                                        ? Colors.red
                                        : theme.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Applied ${app.appliedAt.difference(DateTime.now()).inDays} days ago',
                              style: theme.labelSmall.override(
                                color: theme.secondaryText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        FFButtonWidget(
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              '/jobMessages',
                              arguments: {
                                'applicationRef': app.reference,
                                'otherUserName': app.applicantName,
                              },
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
      ),
    );
  }
}
