import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/backend.dart';
import '/services/community_events_service.dart';

class EventRSVPPage extends StatefulWidget {
  final DocumentReference eventRef;

  const EventRSVPPage({super.key, required this.eventRef});

  @override
  State<EventRSVPPage> createState() => _EventRSVPPageState();
}

class _EventRSVPPageState extends State<EventRSVPPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool isRegistering = false;

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
            'Register for Event',
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
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You\'re about to register for this event.',
                style: theme.bodyMedium,
              ),
              const SizedBox(height: 24.0),
              Text(
                'Event Details',
                style: theme.titleSmall.override(
                  font: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              StreamBuilder<CommunityEventsRecord>(
                stream: CommunityEventsRecord.getDocument(eventRef),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Text('Loading...', style: theme.bodySmall);
                  }
                  final event = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.eventTitle, style: theme.titleSmall),
                      const SizedBox(height: 8.0),
                      Text(event.eventDate.toString().split(' ')[0],
                          style: theme.bodySmall),
                      const SizedBox(height: 8.0),
                      Text(event.eventLocation, style: theme.bodySmall),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32.0),
              Spacer(),
              FFButtonWidget(
                onPressed: isRegistering
                    ? null
                    : () async {
                        setState(() => isRegistering = true);
                        await CommunityEventsService.registerForEvent(
                            eventRef);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Registered successfully!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          Navigator.of(context).pop();
                        }
                      },
                text: isRegistering ? 'Registering...' : 'Confirm Registration',
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
    );
  }
}
