import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/backend.dart';
import 'job_board_listing_page_model.dart';

export 'job_board_listing_page_model.dart';

class JobBoardListingPage extends StatefulWidget {
  const JobBoardListingPage({super.key});

  @override
  State<JobBoardListingPage> createState() => _JobBoardListingPageState();
}

class _JobBoardListingPageState extends State<JobBoardListingPage>
    with TickerProviderStateMixin {
  late JobBoardListingPageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => JobBoardListingPageModel());
    _model.tabController =
        TabController(vsync: this, length: 3, initialIndex: 0);
  }

  @override
  void dispose() {
    _model.dispose();
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
            'Job Board',
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
            // Search bar
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 12.0),
              child: TextFormField(
                controller: _model.searchController,
                onChanged: (_) => setState(() {}),
                obscureText: false,
                decoration: InputDecoration(
                  labelText: 'Search jobs...',
                  labelStyle: theme.labelSmall,
                  hintStyle: theme.labelSmall,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: theme.alternate,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: theme.primary,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: Icon(Icons.search, color: theme.secondaryText),
                ),
                style: theme.bodyMedium,
              ),
            ),

            // Filter tabs
            TabBar(
              controller: _model.tabController,
              labelColor: theme.primary,
              unselectedLabelColor: theme.secondaryText,
              indicatorColor: theme.primary,
              tabs: const [
                Tab(text: 'All Jobs'),
                Tab(text: 'Recently Posted'),
                Tab(text: 'Most Applied'),
              ],
            ),

            // Job list
            Expanded(
              child: TabBarView(
                controller: _model.tabController,
                children: [
                  // All jobs
                  _buildJobsList(context, _model.getAllJobs()),
                  // Recently posted
                  _buildJobsList(context, _model.getRecentJobs()),
                  // Most applied
                  _buildJobsList(context, _model.getMostAppliedJobs()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobsList(BuildContext context, Future<List<JobPostingsRecord>> jobsFuture) {
    return FutureBuilder<List<JobPostingsRecord>>(
      future: jobsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: FlutterFlowTheme.of(context).primary),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No jobs found',
              style: FlutterFlowTheme.of(context).bodyMedium,
            ),
          );
        }

        final jobs = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 16.0, 16.0),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            return _buildJobCard(context, job);
          },
        );
      },
    );
  }

  Widget _buildJobCard(BuildContext context, JobPostingsRecord job) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pushNamed(
            '/jobDetail',
            arguments: {'jobRef': job.reference},
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: theme.alternate),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        job.title,
                        style: theme.titleSmall.override(
                          font: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                        '\$${job.hourlyRate.toStringAsFixed(2)}/hr',
                        style: theme.labelSmall.override(
                          color: theme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  job.businessName,
                  style: theme.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8.0),
                Text(
                  job.description,
                  style: theme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${job.applicationsCount} applied',
                      style: theme.labelSmall.override(
                        color: theme.secondaryText,
                      ),
                    ),
                    Text(
                      'Posted ${job.createdAt.difference(DateTime.now()).inDays} days ago',
                      style: theme.labelSmall.override(
                        color: theme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
