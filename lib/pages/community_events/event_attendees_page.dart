import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/backend/backend.dart';

class EventAttendeesPage extends StatefulWidget {
  final DocumentReference eventRef;

  const EventAttendeesPage({super.key, required this.eventRef});

  @override
  State<EventAttendeesPage> createState() => _EventAttendeesPageState();
}

class _EventAttendeesPageState extends State<EventAttendeesPage> {
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
        body: StreamBuilder<List<CommunityEventAttendeesRecord>>(
          stream: CommunityEventAttendeesRecord.collection
              .where('event_ref', isEqualTo: widget.eventRef)
              .snapshots()
              .map((snapshot) => snapshot.docs
                  .map((doc) =>
                      CommunityEventAttendeesRecord.fromSnapshot(doc))
                  .toList()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: theme.primary),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text('No attendees yet', style: theme.bodyMedium),
              );
            }

            final attendees = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: attendees.length,
              itemBuilder: (context, index) {
                final attendee = attendees[index];
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
                          attendee.attendeeName,
                          style: theme.titleSmall.override(
                            font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          attendee.attendeeEmail,
                          style: theme.bodySmall,
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
