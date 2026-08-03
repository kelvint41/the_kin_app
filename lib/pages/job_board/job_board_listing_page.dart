import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/services/job_board_service.dart';
import '/components/main_menu_button.dart';
import 'job_create_page.dart';
import 'job_detail_page.dart';

class JobBoardListingPage extends StatefulWidget {
  const JobBoardListingPage({super.key});

  static String routeName = 'JobBoardListing';
  static String routePath = '/jobBoard';

  @override
  State<JobBoardListingPage> createState() => _JobBoardListingPageState();
}

class _JobBoardListingPageState extends State<JobBoardListingPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 3, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterAndSort(
      List<Map<String, dynamic>> jobs, int tabIndex) {
    var filtered = jobs;
    final query = searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((job) =>
              (job['title'] as String? ?? '').toLowerCase().contains(query) ||
              (job['description'] as String? ?? '')
                  .toLowerCase()
                  .contains(query))
          .toList();
    }
    final sorted = List<Map<String, dynamic>>.from(filtered);
    if (tabIndex == 2) {
      sorted.sort((a, b) =>
          (b['applicationCount'] as int? ?? 0)
              .compareTo(a['applicationCount'] as int? ?? 0));
    }
    // Tab 0 (All) and tab 1 (Recently Posted) both use the stream's default
    // postedAt-descending order.
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.primaryBackground,
        appBar: AppBar(
          backgroundColor: theme.primary,
          automaticallyImplyLeading: true,
          title: Text(
            'Job Board',
            style: theme.headlineMedium.override(
              font: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
              ),
              color: theme.info
            ),
          ),
          actions: [
            // Posting was only reachable via Owner Profile's "Manage Jobs"
            // menu item - a separate page from this one, so an owner
            // browsing the Job Board itself (the natural place to expect
            // it) had no way to add a listing without first knowing that
            // other page existed. Mirrors JobManagementPage's own add
            // button exactly (same icon/route), just reachable from here
            // too. Hidden rather than disabled for anyone without a
            // business - same as MainMenuButton's other role-gated items.
            if (currentUserDocument?.ownedBusiness != null)
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => JobCreatePage(
                        businessId: currentUserDocument!.ownedBusiness!.id,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                color: theme.info,
              ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
              child: MainMenuButton(),
            ),
          ],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 12.0),
              child: TextFormField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Search jobs...',
                  labelStyle: theme.labelSmall,
                  hintStyle: theme.labelSmall,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.alternate, width: 2.0),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.primary, width: 2.0),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: Icon(Icons.search, color: theme.secondaryText),
                ),
                style: theme.bodyMedium,
              ),
            ),
            TabBar(
              controller: _tabController,
              // 'Recently Posted' was clipping/overlapping the tab next to
              // it - a non-scrollable TabBar divides its width evenly across
              // all three tabs regardless of how long their labels are, and
              // that label alone doesn't fit its third at the default text
              // scale. Scrollable gives each tab its own natural width
              // instead - the standard fix, and one that keeps the actual
              // words intact rather than truncating them.
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: theme.primary,
              unselectedLabelColor: theme.secondaryText,
              indicatorColor: theme.primary,
              onTap: (_) => setState(() {}),
              tabs: const [
                Tab(text: 'All Jobs'),
                Tab(text: 'Recently Posted'),
                Tab(text: 'Most Applied'),
              ],
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: JobBoardService.getAllActiveJobs(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: theme.primary),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Could not load jobs',
                          style: theme.bodyMedium),
                    );
                  }
                  final allJobs = snapshot.data ?? [];
                  return TabBarView(
                    controller: _tabController,
                    children: List.generate(3, (tabIndex) {
                      final jobs = _filterAndSort(allJobs, tabIndex);
                      if (jobs.isEmpty) {
                        return Center(
                          child: Text('No jobs found', style: theme.bodyMedium),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            16.0, 12.0, 16.0, 16.0),
                        itemCount: jobs.length,
                        itemBuilder: (context, index) =>
                            _buildJobCard(context, jobs[index]),
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, Map<String, dynamic> job) {
    final theme = FlutterFlowTheme.of(context);
    final applicationCount = job['applicationCount'] as int? ?? 0;
    final workLocation = job['workLocation'] as String? ?? 'on_site';
    // A remote role has no meaningful address, so show the mode instead of
    // an empty line.
    final locationLabel = workLocation == 'remote'
        ? 'Remote'
        : [
            job['location'] as String? ?? '',
            if (workLocation == 'hybrid') '(Hybrid)',
          ].where((s) => s.isNotEmpty).join(' ');
    final postedAt = job['postedAt'];
    String postedLabel = '';
    if (postedAt != null && postedAt is Timestamp) {
      final days = DateTime.now().difference(postedAt.toDate()).inDays;
      postedLabel = days <= 0 ? 'Posted today' : 'Posted $days days ago';
    }

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => JobDetailPage(jobId: job['id'] as String),
            ),
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
                        job['title'] as String? ?? 'Untitled',
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
                          horizontal: 8.0, vertical: 4.0),
                      child: Text(
                        JobBoardService.formatPay(job),
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
                  locationLabel,
                  style: theme.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8.0),
                Text(
                  job['description'] as String? ?? '',
                  style: theme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$applicationCount applied',
                      style: theme.labelSmall.override(
                        color: theme.secondaryText,
                      ),
                    ),
                    Text(
                      postedLabel,
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
