import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// Admin review queue for `business_submissions`.
///
/// This collection previously had no exit: a customer could add a business
/// from KIN Quest search and the row landed here, but nothing in the app or
/// the Cloud Functions could ever promote one onto the map. Submissions
/// accumulated and no submitted business could reach a user.
///
/// Approve/dismiss both run through the `resolveBusinessSubmissionReview`
/// callable, which re-checks `is_admin` server-side and creates the listing
/// itself (including the geohash the map needs). Nothing here writes to
/// `businesses` directly.
///
/// `business_submissions` is read-gated to admins only in firestore.rules,
/// so a non-admin who lands here (deep link, typed URL, stale bookmark)
/// never actually saw submission data - the stream's own `hasError` branch
/// already caught the resulting permission-denied error with an "admin
/// only" message. The redirect below just makes that consistent with
/// AdminClaimReviewPage/ExecutiveDashboardWidget's own admin gates: bounce
/// away immediately instead of briefly sitting on this admin-titled screen
/// waiting for the query to fail.
class AdminSubmissionsPage extends StatefulWidget {
  const AdminSubmissionsPage({super.key});

  static String routeName = 'AdminSubmissions';
  static String routePath = '/adminSubmissions';

  @override
  State<AdminSubmissionsPage> createState() => _AdminSubmissionsPageState();
}

class _AdminSubmissionsPageState extends State<AdminSubmissionsPage> {
  bool _confirmedAdmin = false;
  final _busy = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userRef = currentUserReference;
      if (userRef == null) {
        context.goNamed(OnboardingSelectionCardWidget.routeName);
        return;
      }
      final userDoc = await UsersRecord.getDocumentOnce(userRef);
      if (!mounted) return;
      if (userDoc.isAdmin != true) {
        context.goNamed(OnboardingSelectionCardWidget.routeName);
        return;
      }
      safeSetState(() => _confirmedAdmin = true);
    });
  }

  Future<void> _resolve(String submissionId, String action, String name) async {
    setState(() => _busy.add(submissionId));
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('resolveBusinessSubmissionReview')
          .call<Map<String, dynamic>>({
        'submissionId': submissionId,
        'action': action,
      });
      if (!mounted) return;
      final approved = result.data['action'] == 'approved';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approved
              ? '$name is live on the map.'
              : 'Dismissed $name.'),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Couldn't update that submission.")),
      );
    } finally {
      if (mounted) setState(() => _busy.remove(submissionId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    // Don't fire the admin-only business_submissions query until admin
    // status is confirmed - the redirect above runs in a post-frame
    // callback, so without this guard the very first frame would still
    // attempt it (same reasoning as ExecutiveDashboardWidget).
    if (!_confirmedAdmin) {
      return Scaffold(
        backgroundColor: theme.primaryBackground,
        body: Center(
          child: CircularProgressIndicator(color: theme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        automaticallyImplyLeading: true,
        title: Text(
          'Business Submissions',
          style: theme.headlineMedium.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            color: theme.info,
          ),
        ),
        centerTitle: false,
        elevation: 0.0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Ordered newest-first. Deliberately not filtered on review_status in
        // the query: the field is absent on every row written before this
        // screen existed, and a Firestore equality clause matches only
        // documents where the field is present - the exact null-matching trap
        // that shipped once already in getAllActiveJobs. Filtered client-side
        // below instead.
        stream: FirebaseFirestore.instance
            .collection('business_submissions')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: theme.primary));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  "Couldn't load submissions. This screen is admin-only.",
                  textAlign: TextAlign.center,
                  style: theme.bodyMedium,
                ),
              ),
            );
          }

          final pending = (snapshot.data?.docs ?? []).where((d) {
            final data = d.data() as Map<String, dynamic>;
            final status = data['review_status'] as String?;
            return status == null || status == 'pending';
          }).toList();

          if (pending.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_rounded,
                        size: 48, color: theme.secondaryText),
                    const SizedBox(height: 12),
                    Text('Nothing waiting for review',
                        style: theme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Businesses submitted from KIN Quest show up here.',
                      textAlign: TextAlign.center,
                      style: theme.bodySmall
                          .override(color: theme.secondaryText),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: pending.length,
            itemBuilder: (context, i) {
              final doc = pending[i];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['business_name'] as String? ?? 'Unnamed';
              final loc = data['business_location'];
              final hasCoords = loc is GeoPoint;
              final onSite = data['verified_on_site'] == true;
              final busy = _busy.contains(doc.id);

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
                      Text(name,
                          style: theme.titleSmall
                              .override(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4.0),
                      Text(data['address'] as String? ?? '',
                          style: theme.bodySmall),
                      Text(data['category'] as String? ?? '',
                          style: theme.labelSmall
                              .override(color: theme.secondaryText)),
                      const SizedBox(height: 10.0),
                      Row(
                        children: [
                          // Whether the submitter's own GPS put them at the
                          // business, or they vouched for it remotely. Both
                          // are worth having; only one is ground truth.
                          _chip(
                            theme,
                            onSite ? 'Verified on site' : 'Remote vouch',
                            onSite ? theme.success : theme.warning,
                          ),
                          const SizedBox(width: 8.0),
                          if (!hasCoords)
                            _chip(theme, 'No coordinates', theme.error),
                        ],
                      ),
                      if (!hasCoords)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            "Can't be approved without coordinates - it would "
                            'never appear on the map.',
                            style: theme.labelSmall
                                .override(color: theme.error),
                          ),
                        ),
                      const SizedBox(height: 12.0),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: busy
                                  ? null
                                  : () => _resolve(doc.id, 'dismiss', name),
                              child: Text('Dismiss',
                                  style: theme.bodyMedium
                                      .override(color: theme.secondaryText)),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: (busy || !hasCoords)
                                  ? null
                                  : () => _resolve(doc.id, 'approve', name),
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.primary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12.0),
                              ),
                              child: Text(
                                busy ? 'Working...' : 'Approve & publish',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.bodyMedium
                                    .override(color: theme.info),
                              ),
                            ),
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

  Widget _chip(FlutterFlowTheme theme, String label, Color color) => Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        child: Text(label,
            style: theme.labelSmall
                .override(color: color, fontWeight: FontWeight.w600)),
      );
}
