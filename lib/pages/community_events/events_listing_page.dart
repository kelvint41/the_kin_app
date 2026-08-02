import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/services/community_events_service.dart';
import '/components/main_menu_button.dart';
import 'event_detail_page.dart';
import 'event_create_page.dart';

class EventsListingPage extends StatefulWidget {
  const EventsListingPage({super.key});

  static String routeName = 'EventsListing';
  static String routePath = '/events';

  @override
  State<EventsListingPage> createState() => _EventsListingPageState();
}

class _EventsListingPageState extends State<EventsListingPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = ['All', 'backpack_drive', 'partnership', 'upcoming'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 4, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<List<Map<String, dynamic>>> _streamForTab(int index) {
    switch (_tabs[index]) {
      case 'backpack_drive':
        return CommunityEventsService.getEventsByType('backpack_drive');
      case 'partnership':
        return CommunityEventsService.getEventsByType('partnership');
      case 'upcoming':
        return CommunityEventsService.getUpcomingEvents();
      default:
        return CommunityEventsService.getAllPublishedEvents();
    }
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
          'Community Events',
          style: theme.headlineMedium.override(
            font: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
            ),
            color: theme.info
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
            child: MainMenuButton(),
          ),
        ],
        centerTitle: false,
        elevation: 0.0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: theme.info,
          unselectedLabelColor: theme.info.withOpacity(0.7),
          indicatorColor: theme.info,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Backpack Drives'),
            Tab(text: 'Partnerships'),
            Tab(text: 'Upcoming'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.primary,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EventCreatePage()),
          );
        },
        child: Icon(Icons.add, color: theme.info),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(4, (tabIndex) {
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _streamForTab(tabIndex),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: theme.primary),
                );
              }
              final events = snapshot.data ?? [];
              if (events.isEmpty) {
                return Center(
                  child: Text('No events found', style: theme.bodyMedium),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: events.length,
                itemBuilder: (context, index) =>
                    _buildEventCard(context, events[index]),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> event) {
    final theme = FlutterFlowTheme.of(context);
    final eventDate = event['eventDate'];
    String dateLabel = '';
    if (eventDate != null) {
      final dt = (eventDate as dynamic).toDate();
      dateLabel = '${dt.month}/${dt.day}/${dt.year}';
    }
    final attendeeCount = event['attendeeCount'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  EventDetailPage(eventId: event['id'] as String),
            ),
          );
        },
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
                CommunityEventsService.eventTypeLabel(
                    event['eventType'] as String? ?? 'other'),
                style:
                    theme.labelSmall.override(color: theme.secondaryText),
              ),
              const SizedBox(height: 4.0),
              Text(
                event['title'] as String? ?? 'Untitled Event',
                style:
                    theme.titleSmall.override(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: theme.secondaryText),
                  const SizedBox(width: 4.0),
                  Text(dateLabel, style: theme.labelSmall),
                  const SizedBox(width: 16.0),
                  Icon(Icons.location_on,
                      size: 14, color: theme.secondaryText),
                  const SizedBox(width: 4.0),
                  Expanded(
                    child: Text(
                      event['location'] as String? ?? '',
                      style: theme.labelSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text('$attendeeCount attending',
                  style:
                      theme.labelSmall.override(color: theme.secondaryText)),
            ],
          ),
        ),
      ),
    );
  }
}
