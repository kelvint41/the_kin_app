import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

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
  State<OwnerROIDashboardWidget> createState() => _OwnerROIDashboardWidgetState();
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

      // Metric 1: KIN Quest Discoveries (profile views)
      final discoveriesSnapshot = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.businessId)
          .collection('discovery_views')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('timestamp', isLessThan: Timestamp.fromDate(startOfNextMonth))
          .count()
          .get();

      final discoveries = discoveriesSnapshot.data().count;

      // Metric 2: Job Applications
      final jobsSnapshot = await FirebaseFirestore.instance
          .collection('job_postings')
          .where('businessRef', isEqualTo: businessDoc.reference)
          .get();

      int jobApplications = 0;
      for (final jobDoc in jobsSnapshot.docs) {
        final appSnapshot = await jobDoc.reference
            .collection('applications')
            .where('appliedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
            .count()
            .get();
        jobApplications += appSnapshot.data().count;
      }

      // Metric 3: Event Attendees
      final eventsSnapshot = await FirebaseFirestore.instance
          .collection('community_events')
          .where('businessRef', isEqualTo: businessDoc.reference)
          .where('eventDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      int eventAttendees = 0;
      for (final eventDoc in eventsSnapshot.docs) {
        final attendeesSnapshot = await eventDoc.reference
            .collection('attendees')
            .count()
            .get();
        eventAttendees += attendeesSnapshot.data().count;
      }

      // Calculate estimated ROI (rough estimate)
      const avgTransactionValue = 15.0; // Average transaction value
      final estimatedRevenue = discoveries * avgTransactionValue;

      return {
        'discoveries': discoveries,
        'jobApplications': jobApplications,
        'eventAttendees': eventAttendees,
        'estimatedRevenue': estimatedRevenue,
        'businessName': business['businessName'] ?? 'Your Business',
        'tier': widget.currentTier ?? 'free',
      };
    } catch (e) {
      debugPrint('Error loading metrics: $e');
      return {
        'discoveries': 0,
        'jobApplications': 0,
        'eventAttendees': 0,
        'estimatedRevenue': 0.0,
        'businessName': 'Your Business',
        'tier': widget.currentTier ?? 'free',
      };
    }
  }

  void _showUpgradeDialog(Map<String, dynamic> metrics) {
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
              label: 'Discoveries',
              value: '${metrics['discoveries']}',
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
                    'Estimated Revenue This Month',
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
              // Navigate to upgrade flow
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
                    title: 'Discovered',
                    value: '${metrics['discoveries']}',
                    subtitle: 'users found you',
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
                    value: '\$${metrics['estimatedRevenue'].toStringAsFixed(0)}',
                    subtitle: 'potential sales',
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
                      metrics['discoveries'] > 25
                          ? 'Amazing! You\'re in the top 10% of discovered businesses. Premium features could boost this 3x.'
                          : metrics['discoveries'] > 10
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
