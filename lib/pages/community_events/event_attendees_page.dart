import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/backend/schema/users_record.dart';
import '/services/community_events_service.dart';

class EventAttendeesPage extends StatefulWidget {
  final String eventId;

  const EventAttendeesPage({super.key, required this.eventId});

  @override
  State<EventAttendeesPage> createState() => _EventAttendeesPageState();
}

class _EventAttendeesPageState extends State<EventAttendeesPage> {
  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        automaticallyImplyLeading: true,
        title: Text(
          'Attendees',
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
        stream: CommunityEventsService.getEventAttendees(widget.eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: theme.primary),
            );
          }
          final attendees = snapshot.data ?? [];
          if (attendees.isEmpty) {
            return Center(
              child: Text('No attendees yet', style: theme.bodyMedium),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: attendees.length,
            itemBuilder: (context, index) {
              final attendee = attendees[index];
              final userId = attendee['userId'] as String?;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.secondaryBackground,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: theme.alternate),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: userId == null
                      ? Text('Attendee',
                          style: theme.titleSmall
                              .override(fontWeight: FontWeight.w600))
                      : FutureBuilder<UsersRecord>(
                          future: UsersRecord.getDocumentOnce(
                              UsersRecord.collection.doc(userId)),
                          builder: (context, userSnapshot) {
                            final user = userSnapshot.data;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (user?.displayName.isNotEmpty ?? false)
                                      ? user!.displayName
                                      : 'Attendee',
                                  style: theme.titleSmall.override(
                                    font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (user != null && user.email.isNotEmpty) ...[
                                  const SizedBox(height: 4.0),
                                  Text(user.email, style: theme.bodySmall),
                                ],
                              ],
                            );
                          },
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
