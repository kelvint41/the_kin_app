import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/services/community_events_service.dart';

class EventRSVPPage extends StatefulWidget {
  final String eventId;

  const EventRSVPPage({super.key, required this.eventId});

  @override
  State<EventRSVPPage> createState() => _EventRSVPPageState();
}

class _EventRSVPPageState extends State<EventRSVPPage> {
  bool isRegistering = false;
  late Future<Map<String, dynamic>?> _eventFuture;

  @override
  void initState() {
    super.initState();
    _eventFuture = CommunityEventsService.getEventDetails(widget.eventId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        automaticallyImplyLeading: true,
        title: Text(
          'Register for Event',
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
              style:
                  theme.titleSmall.override(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16.0),
            FutureBuilder<Map<String, dynamic>?>(
              future: _eventFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return Text('Loading...', style: theme.bodySmall);
                }
                final event = snapshot.data!;
                final eventDate = event['eventDate'];
                String dateLabel = '';
                if (eventDate != null) {
                  final dt = (eventDate as dynamic).toDate();
                  dateLabel = '${dt.month}/${dt.day}/${dt.year}';
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event['title'] as String? ?? '',
                        style: theme.titleSmall),
                    const SizedBox(height: 8.0),
                    Text(dateLabel, style: theme.bodySmall),
                    const SizedBox(height: 8.0),
                    Text(event['location'] as String? ?? '',
                        style: theme.bodySmall),
                  ],
                );
              },
            ),
            const Spacer(),
            FFButtonWidget(
              onPressed: isRegistering
                  ? null
                  : () async {
                      setState(() => isRegistering = true);
                      await CommunityEventsService.registerForEvent(
                        eventId: widget.eventId,
                        userId: currentUserUid,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Registered successfully!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      Navigator.of(context).pop();
                    },
              text: isRegistering ? 'Registering...' : 'Confirm Registration',
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
    );
  }
}
