import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/backend.dart';

class EventManagementPage extends StatefulWidget {
  const EventManagementPage({super.key});

  @override
  State<EventManagementPage> createState() => _EventManagementPageState();
}

class _EventManagementPageState extends State<EventManagementPage> {
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
            'My Events',
            style: theme.headlineMedium.override(
              font: GoogleFonts.plusJakartaSans(
                color: theme.info,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          centerTitle: false,
          elevation: 0.0,
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 16.0, 0.0),
              child: IconButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/eventCreate');
                },
                icon: const Icon(Icons.add),
                color: theme.info,
              ),
            ),
          ],
        ),
        body: StreamBuilder<List<CommunityEventsRecord>>(
          stream: CommunityEventsRecord.collection
              .where('organizer_ref', isEqualTo: null)
              .snapshots()
              .map((snapshot) => snapshot.docs
                  .map((doc) => CommunityEventsRecord.fromSnapshot(doc))
                  .toList()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: theme.primary),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_note,
                        size: 48, color: theme.secondaryText),
                    const SizedBox(height: 16),
                    Text('No events yet', style: theme.bodyMedium),
                    const SizedBox(height: 16),
                    FFButtonWidget(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/eventCreate');
                      },
                      text: 'Create Event',
                      options: FFButtonOptions(
                        width: 150,
                        height: 44,
                        color: theme.primary,
                        textStyle: theme.labelSmall.override(
                          color: theme.info,
                          fontWeight: FontWeight.w600,
                        ),
                        elevation: 0.0,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ],
                ),
              );
            }

            final events = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
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
                          event.eventTitle,
                          style: theme.titleSmall.override(
                            font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          event.eventDate.toString().split(' ')[0],
                          style: theme.bodySmall,
                        ),
                        const SizedBox(height: 12.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            FFButtonWidget(
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  '/eventAttendees',
                                  arguments: {'eventRef': event.reference},
                                );
                              },
                              text: 'View Attendees',
                              options: FFButtonOptions(
                                width: 120,
                                height: 36,
                                color: theme.primary.withOpacity(0.1),
                                textStyle: theme.labelSmall.override(
                                  color: theme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                elevation: 0.0,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            PopupMenuButton(
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: Text('Edit'),
                                  onTap: () {},
                                ),
                                PopupMenuItem(
                                  child: Text('Cancel'),
                                  onTap: () {},
                                ),
                              ],
                            ),
                          ],
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
