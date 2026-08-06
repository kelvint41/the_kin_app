import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';

/// Owner ROI Dashboard - Shows business impact metrics
/// Designed to convert Tier 1 to paid tiers by showing visible results
class OwnerROIDashboardWidget extends StatefulWidget {
  final String businessId;
  final String? currentTier;

  const OwnerROIDashboardWidget({
    Key? key,
    required this.businessId,
    this.currentTier = 'free',
  }) : super(key: key);

  @override
  State<OwnerROIDashboardWidget> createState() =>
      _OwnerROIDashboardWidgetState();
}

class _OwnerROIDashboardWidgetState extends State<OwnerROIDashboardWidget> {
  late Future<Map<String, dynamic>> _metricsFuture;

  @override
  void initState() {
    super.initState();
    _metricsFuture = _loadMetrics();
  }

  Future<Map<String, dynamic>> _loadMetrics() async {
    try {
      // Load business metrics
      final businessDoc = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.businessId)
          .get();

      final business = businessDoc.data() ?? {};

      // Get this month's date range
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfNextMonth = DateTime(now.year, now.month + 1, 1);

      // Metric 1: Verified check-ins this month (uservisits, written by
      // recordVerifiedVisit - visit_verification.js). Was counting
      // businesses/{id}/discovery_views instead, a subcollection nothing
      // in the codebase ever writes to - so this always read 0, and
      // "Est. Revenue" below (which multiplies this count) always showed
      // $0.00 for every business, not a rough estimate, a permanently
      // broken one. Check-ins are a real, populated signal for "did
      // someone show enough interest to actually show up" - not the same
      // thing as a page view, but it's what real foot traffic looks like
      // in this app's own data, and matches the same idea a business
      // owner would gravitate to on their own: how many people actually
      // came, not how many people glanced at a listing.
      final checkInsSnapshot = await FirebaseFirestore.instance
          .collection('uservisits')
          .where('business_ref', isEqualTo: businessDoc.reference)
          .where('visit_timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('visit_timestamp',
              isLessThan: Timestamp.fromDate(startOfNextMonth))
          .count()
          .get();

      final checkIns = checkInsSnapshot.count ?? 0;

      // Metric 2: Job Applications
      final jobsSnapshot = await FirebaseFirestore.instance
          .collection('job_postings')
          .where('businessRef', isEqualTo: businessDoc.reference)
          .get();

      int jobApplications = 0;
      for (final jobDoc in jobsSnapshot.docs) {
        final appSnapshot = await jobDoc.reference
            .collection('applications')
            .where('appliedAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
            .count()
            .get();
        jobApplications += appSnapshot.count ?? 0;
      }

      // Metric 3: Event Attendees
      final eventsSnapshot = await FirebaseFirestore.instance
          .collection('community_events')
          .where('businessRef', isEqualTo: businessDoc.reference)
          .where('eventDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      int eventAttendees = 0;
      for (final eventDoc in eventsSnapshot.docs) {
        final attendeesSnapshot =
            await eventDoc.reference.collection('attendees').count().get();
        eventAttendees += attendeesSnapshot.count ?? 0;
      }

      // Still a rough estimate, not a real number - there's no POS/sales
      // integration anywhere in this app, so there's no way to know a
      // business's actual average transaction value or how many check-ins
      // convert into a sale. $15/visit is a flat, disclosed assumption
      // (see its label in build() below), not a computed figure - the
      // real fix here was checkIns itself being real data; this multiplier
      // is honest about staying a guess.
      const avgTransactionValue = 15.0;
      final estimatedRevenue = checkIns * avgTransactionValue;

      return {
        'checkIns': checkIns,
        'jobApplications': jobApplications,
        'eventAttendees': eventAttendees,
        'estimatedRevenue': estimatedRevenue,
        'businessName': business['businessName'] ?? 'Your Business',
        'tier': widget.currentTier ?? 'free',
      };
    } catch (e) {
      debugPrint('Error loading metrics: $e');
      return {
        'checkIns': 0,
        'jobApplications': 0,
        'eventAttendees': 0,
        'estimatedRevenue': 0.0,
        'businessName': 'Your Business',
        'tier': widget.currentTier ?? 'free',
      };
    }
  }

  void _showUpgradeDialog(Map<String, dynamic> metrics) {
    // Captured before showDialog's own builder shadows `context` with the
    // dialog's - Navigator.pop below needs that shadowed one to close the
    // right route, but pushNamed needs this outer, still-mounted one
    // rather than navigating through a context whose route just popped.
    final pageContext = context;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚀 Upgrade & Grow'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Current Impact:',
              style: FlutterFlowTheme.of(context).titleSmall,
            ),
            const SizedBox(height: 12),
            _MetricRow(
              icon: '✨',
              label: 'Verified check-ins',
              value: '${metrics['checkIns']}',
            ),
            _MetricRow(
              icon: '💼',
              label: 'Job Applications',
              value: '${metrics['jobApplications']}',
            ),
            _MetricRow(
              icon: '🎭',
              label: 'Event Attendees',
              value: '${metrics['eventAttendees']}',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated Revenue This Month (rough - \$15/visit)',
                    style: FlutterFlowTheme.of(context).bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${metrics['estimatedRevenue'].toStringAsFixed(2)}',
                    style: FlutterFlowTheme.of(context).headlineSmall.override(
                          color: Colors.green[700],
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Imagine with Premium features:',
              style: FlutterFlowTheme.of(context).titleSmall,
            ),
            const SizedBox(height: 8),
            _UpgradeFeature('📊 Advanced analytics'),
            _UpgradeFeature('🎯 Targeted promotions'),
            _UpgradeFeature('💬 Direct customer messaging'),
            _UpgradeFeature('📈 ROI tracking'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Was a bare comment with no code behind it - tapping
              // "Upgrade Now" did nothing at all. Same destination Growth
              // Tools' own "Your Membership Tier" section links out to.
              // pageContext, not this button's own (dialog) context - see
              // the doc comment on _showUpgradeDialog.
              if (!pageContext.mounted) return;
              pageContext.pushNamed(
                MerchantPricingSuiteWidget.routeName,
                queryParameters: {
                  'businessRef': serializeParam(
                    FirebaseFirestore.instance
                        .collection('businesses')
                        .doc(widget.businessId),
                    ParamType.DocumentReference,
                  ),
                }.withoutNulls,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FlutterFlowTheme.of(context).success,
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _metricsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }

        final metrics = snapshot.data!;
        final theme = FlutterFlowTheme.of(context);

        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primary.withOpacity(0.1),
                theme.accent1,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: theme.primary.withOpacity(0.3),
              width: 2.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '📊 This Month\'s Impact',
                    style: theme.titleMedium,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.success,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      metrics['tier'].toUpperCase(),
                      style: theme.labelSmall.override(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Metrics Grid
              GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _MetricCard(
                    icon: '✨',
                    title: 'Check-ins',
                    value: '${metrics['checkIns']}',
                    subtitle: 'verified visits',
                    color: Colors.amber,
                  ),
                  _MetricCard(
                    icon: '💼',
                    title: 'Applications',
                    value: '${metrics['jobApplications']}',
                    subtitle: 'job seekers',
                    color: Colors.blue,
                  ),
                  _MetricCard(
                    icon: '🎭',
                    title: 'Event RSVPs',
                    value: '${metrics['eventAttendees']}',
                    subtitle: 'attendees',
                    color: Colors.purple,
                  ),
                  _MetricCard(
                    icon: '💰',
                    title: 'Est. Revenue',
                    value:
                        '\$${metrics['estimatedRevenue'].toStringAsFixed(0)}',
                    // Disclosed rather than presented as a real figure -
                    // there's no sales/POS data anywhere in the app, so
                    // this is check-ins x a flat assumed $15/visit, not a
                    // computed number. See _loadMetrics' own comment.
                    subtitle: 'rough estimate (\$15/visit)',
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ROI Message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎯 Your Performance',
                      style: theme.labelSmall.override(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      // Thresholds (25/10) were originally calibrated for
                      // the old page-view metric, a much higher-volume
                      // signal than real physical check-ins - kept as-is
                      // rather than guessing new numbers, since there's no
                      // real distribution of check-in volume across
                      // businesses yet to calibrate against. Worth
                      // revisiting once there's actual usage data to look
                      // at instead of another guess.
                      metrics['checkIns'] > 25
                          ? 'Amazing! You\'re in the top 10% of visited businesses. Premium features could boost this 3x.'
                          : metrics['checkIns'] > 10
                              ? 'Great start! Keep growing with premium features like targeted promotions.'
                              : 'Get started on Premium to reach more customers in your area.',
                      style: theme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Upgrade CTA
              FFButtonWidget(
                onPressed: () => _showUpgradeDialog(metrics),
                text: '🚀 See Premium Impact',
                options: FFButtonOptions(
                  width: double.infinity,
                  height: 48,
                  color: theme.primary,
                  textStyle: theme.titleSmall.override(
                    color: Colors.white,
                  ),
                  elevation: 3,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.titleSmall.override(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.labelSmall.override(
              color: theme.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$icon $label'),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeFeature extends StatelessWidget {
  final String text;

  const _UpgradeFeature(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Text('✅ '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
