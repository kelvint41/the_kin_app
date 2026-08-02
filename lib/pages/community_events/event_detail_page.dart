import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/backend.dart';

class EventDetailPage extends StatefulWidget {
  final DocumentReference eventRef;

  const EventDetailPage({super.key, required this.eventRef});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
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
            'Event Details',
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
        body: StreamBuilder<CommunityEventsRecord>(
          stream: CommunityEventsRecord.getDocument(eventRef),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: theme.primary),
              );
            }
            if (!snapshot.hasData) {
              return Center(
                child: Text('Event not found', style: theme.bodyMedium),
              );
            }

            final event = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.1),
                    ),
                    child: event.eventImage.isNotEmpty
                        ? Image.network(event.eventImage,
                            fit: BoxFit.cover)
                        : Icon(Icons.event, size: 80, color: theme.primary),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.eventTitle,
                          style: theme.headlineSmall.override(
                            font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 20, color: theme.primary),
                            const SizedBox(width: 8.0),
                            Text(
                              event.eventDate.toString().split(' ')[0],
                              style: theme.labelSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 20, color: theme.primary),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                event.eventLocation,
                                style: theme.labelSmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24.0),
                        Text(
                          'About This Event',
                          style: theme.titleSmall.override(
                            font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          event.description,
                          style: theme.bodyMedium,
                        ),
                        const SizedBox(height: 24.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '${event.attendeesCount ?? 0}',
                                  style: theme.headlineSmall.override(
                                    color: theme.primary,
                                    font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text('Attending', style: theme.labelSmall),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  '${event.commentsCount ?? 0}',
                                  style: theme.headlineSmall.override(
                                    color: theme.primary,
                                    font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text('Comments', style: theme.labelSmall),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 32.0),
                        FFButtonWidget(
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              '/eventRSVP',
                              arguments: {'eventRef': eventRef},
                            );
                          },
                          text: 'Register for Event',
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
