import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/community_events_service.dart';
import 'event_rsvp_page.dart';
import 'event_comments_page.dart';
import 'partnership_request_page.dart';

class EventDetailPage extends StatefulWidget {
  final String eventId;

  const EventDetailPage({super.key, required this.eventId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
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
          'Event Details',
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
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _eventFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: theme.primary),
            );
          }
          final event = snapshot.data;
          if (event == null) {
            return Center(
              child: Text('Event not found', style: theme.bodyMedium),
            );
          }

          final eventDate = event['eventDate'];
          String dateLabel = '';
          if (eventDate != null) {
            final dt = (eventDate as dynamic).toDate();
            dateLabel = '${dt.month}/${dt.day}/${dt.year}';
          }
          final attendeeCount = event['attendeeCount'] as int? ?? 0;
          final businessRef = event['businessRef'];
          final eventType = event['eventType'] as String? ?? 'other';
          final imageUrl = event['imageUrl'] as String?;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null && imageUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 220.0,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    memCacheHeight:
                        (220.0 * MediaQuery.devicePixelRatioOf(context))
                            .round(),
                  ),
                Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CommunityEventsService.eventTypeLabel(eventType),
                    style: theme.labelMedium.override(color: theme.primary),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    event['title'] as String? ?? 'Untitled Event',
                    style: theme.headlineSmall,
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: theme.secondaryText),
                      const SizedBox(width: 6.0),
                      Text(dateLabel, style: theme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: theme.secondaryText),
                      const SizedBox(width: 6.0),
                      Expanded(
                        child: Text(event['location'] as String? ?? '',
                            style: theme.bodySmall),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Icon(Icons.people_outline,
                          size: 16, color: theme.secondaryText),
                      const SizedBox(width: 6.0),
                      Text('$attendeeCount attending', style: theme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 24.0),
                  Text('About This Event',
                      style: theme.titleSmall
                          .override(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8.0),
                  Text(
                    event['description'] as String? ?? '',
                    style: theme.bodyMedium,
                  ),
                  const SizedBox(height: 32.0),
                  FFButtonWidget(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              EventRSVPPage(eventId: widget.eventId),
                        ),
                      );
                    },
                    text: 'Register / RSVP',
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
                  const SizedBox(height: 12.0),
                  FFButtonWidget(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              EventCommentsPage(eventId: widget.eventId),
                        ),
                      );
                    },
                    text: 'View Discussion',
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 56.0,
                      color: theme.secondaryBackground,
                      textStyle: theme.titleSmall.override(
                        color: theme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      elevation: 0.0,
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: theme.primary, width: 2.0),
                    ),
                  ),
                  if (eventType == 'partnership' && businessRef != null) ...[
                    const SizedBox(height: 12.0),
                    FFButtonWidget(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PartnershipRequestPage(
                              eventId: widget.eventId,
                              toBusinessId: businessRef.id as String,
                            ),
                          ),
                        );
                      },
                      text: 'Request Partnership',
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 56.0,
                        color: theme.secondaryBackground,
                        textStyle: theme.titleSmall.override(
                          color: theme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        elevation: 0.0,
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: theme.primary, width: 2.0),
                      ),
                    ),
                  ],
                ],
              ),
            ),
              ],
            ),
          );
        },
      ),
    );
  }
}
