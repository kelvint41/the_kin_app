import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Admin dashboard card showing job board activity and engagement metrics.
///
/// Displays:
/// - Active job postings (right now)
/// - Weekly job creation rate
/// - Top hiring businesses
/// - Candidate engagement (bookmarks, messages)
/// - Application volume
class AdminJobBoardMetricsCard extends StatelessWidget {
  const AdminJobBoardMetricsCard({
    super.key,
    this.activePostings = 0,
    this.weeklyPostings = 0,
    this.totalApplications = 0,
    this.avgApplicationsPerJob = 0.0,
    this.topHiringBusinesses = const [],
  });

  final int activePostings;
  final int weeklyPostings;
  final int totalApplications;
  final double avgApplicationsPerJob;
  final List<Map<String, dynamic>> topHiringBusinesses;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.alternate, width: 1.0),
      ),
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.briefcase_outlined,
                    color: theme.primary,
                    size: 24.0,
                  ),
                  SizedBox(width: 12.0),
                  Text(
                    'Job Board Activity',
                    style: theme.titleSmall.override(
                      font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                      ),
                      fontSize: 16.0,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: theme.accent1,
                  borderRadius: BorderRadius.circular(999.0),
                ),
                padding:
                    EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                child: Text(
                  'Live',
                  style: theme.labelSmall.override(
                    color: theme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.0),

          // Metrics Grid (4 columns)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12.0,
            crossAxisSpacing: 12.0,
            childAspectRatio: 1.2,
            children: [
              // Active Postings
              _MetricBox(
                icon: Icons.list_alt_rounded,
                label: 'Active Now',
                value: activePostings.toString(),
                theme: theme,
              ),
              // Weekly Postings
              _MetricBox(
                icon: Icons.trending_up_rounded,
                label: 'This Week',
                value: '+$weeklyPostings',
                theme: theme,
              ),
              // Total Applications
              _MetricBox(
                icon: Icons.mail_outline_rounded,
                label: 'Applications',
                value: totalApplications.toString(),
                theme: theme,
              ),
              // Avg per job
              _MetricBox(
                icon: Icons.show_chart_rounded,
                label: 'Avg per Job',
                value: avgApplicationsPerJob.toStringAsFixed(1),
                theme: theme,
              ),
            ],
          ),
          SizedBox(height: 16.0),

          // Top Hiring Businesses
          if (topHiringBusinesses.isNotEmpty) ...[
            Divider(height: 16.0, color: theme.alternate),
            SizedBox(height: 8.0),
            Text(
              'Top Hiring Businesses',
              style: theme.labelLarge.override(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.0),
            ...List.generate(
              topHiringBusinesses.length,
              (index) {
                final business = topHiringBusinesses[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}. ${business['name'] ?? 'Unknown Business'}',
                              style: theme.bodySmall.override(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.0),
                            Text(
                              '${business['jobCount'] ?? 0} jobs • ${business['hires'] ?? 0} hires',
                              style: theme.labelSmall.override(
                                color: theme.secondaryText,
                                fontSize: 11.0,
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
          ],
        ],
      ),
    );
  }
}

/// Reusable metric box widget
class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final String value;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: theme.alternate, width: 0.5),
      ),
      padding: EdgeInsets.all(12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: theme.primary,
            size: 20.0,
          ),
          SizedBox(height: 8.0),
          Text(
            value,
            style: theme.titleSmall.override(
              font: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
              ),
              fontSize: 18.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.0),
          Text(
            label,
            style: theme.labelSmall.override(
              color: theme.secondaryText,
              fontSize: 11.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
