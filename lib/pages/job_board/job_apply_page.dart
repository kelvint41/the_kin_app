import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/backend.dart';
import 'job_apply_page_model.dart';

export 'job_apply_page_model.dart';

class JobApplyPage extends StatefulWidget {
  final DocumentReference jobRef;

  const JobApplyPage({super.key, required this.jobRef});

  @override
  State<JobApplyPage> createState() => _JobApplyPageState();
}

class _JobApplyPageState extends State<JobApplyPage> {
  late JobApplyPageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => JobApplyPageModel());
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
            'Apply to Job',
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
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Information',
                  style: theme.titleSmall.override(
                    font: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // Full name field
                TextFormField(
                  controller: _model.nameController,
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

                // Email field
                TextFormField(
                  controller: _model.emailController,
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

                // Phone field
                TextFormField(
                  controller: _model.phoneController,
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
                  style: theme.titleSmall.override(
                    font: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // Cover letter field
                TextFormField(
                  controller: _model.coverLetterController,
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

                // Submit button
                FFButtonWidget(
                  onPressed: () async {
                    final success = await _model.submitApplication(
                      jobRef: widget.jobRef,
                      name: _model.nameController.text,
                      email: _model.emailController.text,
                      phone: _model.phoneController.text,
                      coverLetter: _model.coverLetterController.text,
                    );
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Application submitted successfully!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to submit application'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  text: 'Submit Application',
                  options: FFButtonOptions(
                    width: double.infinity,
                    height: 56.0,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
