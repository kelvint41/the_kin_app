import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/services/job_board_service.dart';

class JobApplyPage extends StatefulWidget {
  final String jobId;

  const JobApplyPage({super.key, required this.jobId});

  @override
  State<JobApplyPage> createState() => _JobApplyPageState();
}

class _JobApplyPageState extends State<JobApplyPage> {
  final nameController = TextEditingController(text: currentUserDisplayName);
  final emailController = TextEditingController(text: currentUserEmail);
  final phoneController = TextEditingController();
  final coverLetterController = TextEditingController();
  bool isSubmitting = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    coverLetterController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => isSubmitting = true);
    try {
      final job = await JobBoardService.getJobDetails(widget.jobId);
      final businessRef = job?['businessRef'];
      if (businessRef == null) {
        throw Exception('Job has no business reference');
      }
      await JobBoardService.applyToJob(
        jobId: widget.jobId,
        applicantId: currentUserUid,
        businessId: businessRef.id as String,
        applicantName: nameController.text,
        applicantEmail: emailController.text,
        applicantPhone: phoneController.text,
        coverLetter: coverLetterController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit application'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.primaryBackground,
        appBar: AppBar(
          backgroundColor: theme.primary,
          automaticallyImplyLeading: true,
          title: Text(
            'Apply to Job',
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
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Information',
                  style: theme.titleSmall
                      .override(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: theme.labelSmall,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.alternate),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.primary, width: 2.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  style: theme.bodyMedium,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: theme.labelSmall,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.alternate),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.primary, width: 2.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  style: theme.bodyMedium,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: theme.labelSmall,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.alternate),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.primary, width: 2.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  style: theme.bodyMedium,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24.0),
                Text(
                  'Cover Letter',
                  style: theme.titleSmall
                      .override(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: coverLetterController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: 'Tell the employer why you\'re a great fit',
                    labelStyle: theme.labelSmall,
                    alignLabelWithHint: true,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.alternate),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.primary, width: 2.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  style: theme.bodyMedium,
                ),
                const SizedBox(height: 32.0),
                FFButtonWidget(
                  onPressed: isSubmitting ? null : _submit,
                  text: isSubmitting ? 'Submitting...' : 'Submit Application',
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
        ),
      ),
    );
  }
}
