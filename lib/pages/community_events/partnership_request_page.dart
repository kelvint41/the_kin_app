import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/community_events_service.dart';

class PartnershipRequestPage extends StatefulWidget {
  const PartnershipRequestPage({super.key});

  @override
  State<PartnershipRequestPage> createState() => _PartnershipRequestPageState();
}

class _PartnershipRequestPageState extends State<PartnershipRequestPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final businessNameController = TextEditingController();
  final businessDescriptionController = TextEditingController();
  final partnershipGoalsController = TextEditingController();
  final contactEmailController = TextEditingController();
  bool isSending = false;

  @override
  void dispose() {
    businessNameController.dispose();
    businessDescriptionController.dispose();
    partnershipGoalsController.dispose();
    contactEmailController.dispose();
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
            'Partnership Request',
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
                  'Connect with other Black-owned businesses',
                  style: theme.bodyMedium,
                ),
                const SizedBox(height: 24.0),
                TextFormField(
                  controller: businessNameController,
                  decoration: InputDecoration(
                    labelText: 'Business Name',
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
                  controller: businessDescriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'What does your business do?',
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
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: partnershipGoalsController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText:
                        'What are your partnership goals? (Collaboration, referrals, joint events, etc.)',
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
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: contactEmailController,
                  decoration: InputDecoration(
                    labelText: 'Contact Email',
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
                const SizedBox(height: 32.0),
                FFButtonWidget(
                  onPressed: isSending
                      ? null
                      : () async {
                          setState(() => isSending = true);
                          await CommunityEventsService.submitPartnershipRequest(
                            businessName: businessNameController.text,
                            businessDescription:
                                businessDescriptionController.text,
                            partnershipGoals: partnershipGoalsController.text,
                            contactEmail: contactEmailController.text,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Partnership request sent! We\'ll review it shortly.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            Navigator.of(context).pop();
                          }
                        },
                  text: isSending ? 'Sending...' : 'Send Request',
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
