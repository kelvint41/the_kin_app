import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/backend.dart';
import '/services/community_events_service.dart';

class EventsListingPage extends StatefulWidget {
  const EventsListingPage({super.key});

  @override
  State<EventsListingPage> createState() => _EventsListingPageState();
}

class _EventsListingPageState extends State<EventsListingPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final scaffoldKey = GlobalKey<ScaffoldState>();

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
            'Community Events',
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
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: theme.primary,
              unselectedLabelColor: theme.secondaryText,
              indicatorColor: theme.primary,
              tabs: const [
                Tab(text: 'All Events'),
                Tab(text: 'Backpack Drives'),
                Tab(text: 'Partnerships'),
                Tab(text: 'Upcoming'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEventsList(context, null),
                  _buildEventsList(context, 'backpack_drive'),
                  _buildEventsList(context, 'partnership'),
                  _buildUpcomingEventsList(context),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: theme.primary,
          onPressed: () {
            Navigator.of(context).pushNamed('/eventCreate');
          },
          child: Icon(Icons.add, color: theme.info),
        ),
      ),
    );
  }

  Widget _buildEventsList(BuildContext context, String? eventType) {
    final theme = FlutterFlowTheme.of(context);
    return FutureBuilder<List<CommunityEventsRecord>>(
      future: eventType == null
          ? CommunityEventsService.getAllPublishedEvents()
          : CommunityEventsService.getEventsByType(eventType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: theme.primary),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text('No events found', style: theme.bodyMedium),
          );
        }

        final events = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _buildEventCard(context, event);
          },
        );
      },
    );
  }

  Widget _buildUpcomingEventsList(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return FutureBuilder<List<CommunityEventsRecord>>(
      future: CommunityEventsService.getUpcomingEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: theme.primary),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text('No upcoming events', style: theme.bodyMedium),
          );
        }

        final events = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _buildEventCard(context, event);
          },
        );
      },
    );
  }

  Widget _buildEventCard(BuildContext context, CommunityEventsRecord event) {
    final theme = FlutterFlowTheme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          '/eventDetail',
          arguments: {'eventRef': event.reference},
        );
      },
      child: Padding(
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
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: theme.secondaryText),
                  const SizedBox(width: 8.0),
                  Text(
                    event.eventDate.toString().split(' ')[0],
                    style: theme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: theme.secondaryText),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      event.eventLocation,
                      style: theme.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${event.attendeesCount ?? 0} attending',
                    style: theme.labelSmall.override(
                      color: theme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: Text(
                      event.eventType,
                      style: theme.labelSmall.override(
                        color: theme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
