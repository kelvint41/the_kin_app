import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/services/community_events_service.dart';
import 'event_attendees_page.dart';
import 'event_create_page.dart';

class EventManagementPage extends StatefulWidget {
  const EventManagementPage({super.key});

  static String routeName = 'EventManagement';
  static String routePath = '/eventManagement';

  @override
  State<EventManagementPage> createState() => _EventManagementPageState();
}

class _EventManagementPageState extends State<EventManagementPage> {
  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final businessId = currentUserDocument?.ownedBusiness?.id;

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        automaticallyImplyLeading: true,
        title: Text(
          'My Events',
          style: theme.headlineMedium.override(
            font: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
            ),
            color: theme.info
          ),
        ),
        centerTitle: false,
        elevation: 0.0,
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 16.0, 0.0),
            child: IconButton(
              onPressed: businessId == null
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              EventCreatePage(businessId: businessId),
                        ),
                      );
                    },
              icon: const Icon(Icons.add),
              color: theme.info,
            ),
          ),
        ],
      ),
      body: businessId == null
          ? Center(
              child: Text('Set up your business to post events',
                  style: theme.bodyMedium),
            )
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: CommunityEventsService.getBusinessEvents(businessId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: theme.primary),
                  );
                }
                final events = snapshot.data ?? [];
                if (events.isEmpty) {
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
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    EventCreatePage(businessId: businessId),
                              ),
                            );
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

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final eventId = event['id'] as String;
                    final eventDate = event['eventDate'];
                    String dateLabel = '';
                    if (eventDate != null) {
                      final dt = (eventDate as dynamic).toDate();
                      dateLabel = '${dt.month}/${dt.day}/${dt.year}';
                    }
                    final status = event['status'] as String? ?? 'draft';

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
                              event['title'] as String? ?? 'Untitled',
                              style: theme.titleSmall.override(
                                font: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Row(
                              children: [
                                Text(dateLabel, style: theme.bodySmall),
                                const SizedBox(width: 12.0),
                                Text(
                                  status,
                                  style: theme.labelSmall.override(
                                    color: status == 'published'
                                        ? theme.success
                                        : theme.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12.0),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                FFButtonWidget(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => EventAttendeesPage(
                                            eventId: eventId),
                                      ),
                                    );
                                  },
                                  text: 'View Attendees',
                                  options: FFButtonOptions(
                                    width: 140,
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
                                PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'cancel') {
                                      await CommunityEventsService
                                          .cancelEvent(eventId);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'cancel',
                                      child: Text('Cancel'),
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
    );
  }
}
