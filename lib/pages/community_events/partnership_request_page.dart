import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/services/community_events_service.dart';

class PartnershipRequestPage extends StatefulWidget {
  final String eventId;
  final String toBusinessId;

  const PartnershipRequestPage({
    super.key,
    required this.eventId,
    required this.toBusinessId,
  });

  @override
  State<PartnershipRequestPage> createState() =>
      _PartnershipRequestPageState();
}

class _PartnershipRequestPageState extends State<PartnershipRequestPage> {
  final messageController = TextEditingController();
  bool isSending = false;

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final fromBusinessId = currentUserDocument?.ownedBusiness?.id;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.primaryBackground,
        appBar: AppBar(
          backgroundColor: theme.primary,
          automaticallyImplyLeading: true,
          title: Text(
            'Partnership Request',
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
                  'Connect with this business for a joint event',
                  style: theme.bodyMedium,
                ),
                const SizedBox(height: 24.0),
                TextFormField(
                  controller: messageController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText:
                        'What would you like to propose? (Collaboration, joint hosting, cross-promotion, etc.)',
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
                  onPressed: (isSending || fromBusinessId == null)
                      ? null
                      : () async {
                          setState(() => isSending = true);
                          try {
                            await CommunityEventsService.requestPartnership(
                              fromBusinessId: fromBusinessId,
                              toBusinessId: widget.toBusinessId,
                              eventId: widget.eventId,
                              message: messageController.text,
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Partnership request sent! We\'ll review it shortly.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            Navigator.of(context).pop();
                          } finally {
                            if (mounted) setState(() => isSending = false);
                          }
                        },
                  text: fromBusinessId == null
                      ? 'You need a business to partner'
                      : (isSending ? 'Sending...' : 'Send Request'),
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
