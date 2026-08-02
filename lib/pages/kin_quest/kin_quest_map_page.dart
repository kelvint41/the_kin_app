import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/components/kin_splash_widget.dart';
import '/auth/firebase_auth/auth_util.dart';

/// Simplified Gamified KIN Quest map page
/// Shows all Black-owned businesses for discovery
class KinQuestMapPage extends StatefulWidget {
  const KinQuestMapPage({super.key});

  static String routeName = 'KinQuestMap';
  static String routePath = '/kinQuestMap';

  @override
  State<KinQuestMapPage> createState() => _KinQuestMapPageState();
}

class _KinQuestMapPageState extends State<KinQuestMapPage> {
  late Future<List<Map<String, dynamic>>> _businessesFuture;
  Set<String> discoveredBusinessIds = {};
  int discoveredCount = 0;
  int totalBusinesses = 0;

  @override
  void initState() {
    super.initState();
    _businessesFuture = _loadBusinesses();
    _loadDiscoveredBusinesses();
  }

  Future<List<Map<String, dynamic>>> _loadBusinesses() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('businesses')
          .where('isBlackOwned', isEqualTo: true)
          .get();

      final businesses = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      setState(() => totalBusinesses = businesses.length);
      return businesses;
    } catch (e) {
      debugPrint('Error loading businesses: $e');
      return [];
    }
  }

  Future<void> _loadDiscoveredBusinesses() async {
    try {
      final user = currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('discovered_businesses')
          .get();

      setState(() {
        discoveredBusinessIds = snapshot.docs.map((doc) => doc.id).toSet();
        discoveredCount = discoveredBusinessIds.length;
      });
    } catch (e) {
      debugPrint('Error loading discovered businesses: $e');
    }
  }

  Future<void> _markAsDiscovered(Map<String, dynamic> business) async {
    try {
      final user = currentUser;
      if (user == null) return;

      final businessId = business['id'];

      // Save to user's discovered businesses
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('discovered_businesses')
          .doc(businessId)
          .set({
        'businessName': business['businessName'],
        'category': business['category'],
        'discoveredAt': FieldValue.serverTimestamp(),
        'verified': false,
        'points': 50,
      });

      // Award KIN points
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'kinBalance': FieldValue.increment(50),
      });

      // Reload and update UI
      await _loadDiscoveredBusinesses();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${business['businessName']} discovered! +50 KIN'),
            backgroundColor: FlutterFlowTheme.of(context).success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking discovered: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showBusinessDetails(Map<String, dynamic> business) {
    final businessId = business['id'];
    final isDiscovered = discoveredBusinessIds.contains(businessId);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24.0),
            topRight: Radius.circular(24.0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business name with status
            Row(
              children: [
                Expanded(
                  child: Text(
                    business['businessName'] ?? 'Business',
                    style: FlutterFlowTheme.of(context).titleLarge,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: isDiscovered
                        ? FlutterFlowTheme.of(context).success
                        : Colors.amber,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    isDiscovered ? '✓ Discovered' : '? Undiscovered',
                    style: FlutterFlowTheme.of(context)
                        .labelSmall
                        .override(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),

            // Category
            Text(
              business['category'] ?? 'Business',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
            ),
            const SizedBox(height: 16.0),

            // Address
            if (business['address'] != null)
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: FlutterFlowTheme.of(context).primary,
                    size: 16.0,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      business['address'],
                      style: FlutterFlowTheme.of(context).bodySmall,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24.0),

            // Action button
            if (!isDiscovered)
              FFButtonWidget(
                onPressed: () {
                  Navigator.pop(context);
                  _showVerificationFlow(business);
                },
                text: '📸 Verify This Business',
                options: FFButtonOptions(
                  width: double.infinity,
                  height: 48.0,
                  color: FlutterFlowTheme.of(context).primary,
                  textStyle: FlutterFlowTheme.of(context)
                      .titleSmall
                      .override(color: Colors.white),
                  elevation: 3.0,
                  borderRadius: BorderRadius.circular(8.0),
                ),
              )
            else
              FFButtonWidget(
                onPressed: () => Navigator.pop(context),
                text: '✓ Already Discovered',
                options: FFButtonOptions(
                  width: double.infinity,
                  height: 48.0,
                  color: FlutterFlowTheme.of(context).accent1,
                  textStyle: FlutterFlowTheme.of(context)
                      .titleSmall
                      .override(color: FlutterFlowTheme.of(context).primary),
                  elevation: 0.0,
                  borderSide: BorderSide(
                    color: FlutterFlowTheme.of(context).primary,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showVerificationFlow(Map<String, dynamic> business) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24.0),
            topRight: Radius.circular(24.0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🔍 Verify Business Ownership',
              style: FlutterFlowTheme.of(context).titleMedium,
            ),
            const SizedBox(height: 16.0),
            Text(
              'Help us verify that this is a Black-owned business by taking a photo.',
              style: FlutterFlowTheme.of(context).bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),
            FFButtonWidget(
              onPressed: () {
                Navigator.pop(context);
                _markAsDiscovered(business);
              },
              text: '✅ Confirm Discovery',
              options: FFButtonOptions(
                width: double.infinity,
                height: 48.0,
                color: FlutterFlowTheme.of(context).success,
                textStyle: FlutterFlowTheme.of(context)
                    .titleSmall
                    .override(color: Colors.white),
                elevation: 3.0,
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primary,
        elevation: 0.0,
        title: Text(
          'KIN Quest Discovery Map',
          style: FlutterFlowTheme.of(context).headlineSmall.override(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _businessesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: KinSplashWidget());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off,
                    size: 64.0,
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'No businesses yet',
                    style: FlutterFlowTheme.of(context).titleMedium,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Load test data to see the discovery map',
                    style: FlutterFlowTheme.of(context).bodySmall,
                  ),
                ],
              ),
            );
          }

          final businesses = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Progress card
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).accent1,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: FlutterFlowTheme.of(context).primary,
                    width: 2.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '🎮 Quest Progress',
                          style: FlutterFlowTheme.of(context).labelLarge,
                        ),
                        Text(
                          '$discoveredCount / $totalBusinesses',
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                color: FlutterFlowTheme.of(context).primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: LinearProgressIndicator(
                        value: totalBusinesses > 0
                            ? discoveredCount / totalBusinesses
                            : 0.0,
                        minHeight: 8.0,
                        backgroundColor:
                            FlutterFlowTheme.of(context).alternate,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          FlutterFlowTheme.of(context).success,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      '📍 Tap a business to verify it',
                      style: FlutterFlowTheme.of(context).labelSmall.override(
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),

              // Business list
              ...businesses.map(
                (business) {
                  final businessId = business['id'];
                  final isDiscovered =
                      discoveredBusinessIds.contains(businessId);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GestureDetector(
                      onTap: () => _showBusinessDetails(business),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: isDiscovered
                                ? FlutterFlowTheme.of(context).success
                                : Colors.amber,
                            width: 2.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Status marker
                            Container(
                              width: 48.0,
                              height: 48.0,
                              decoration: BoxDecoration(
                                color: isDiscovered
                                    ? FlutterFlowTheme.of(context).success
                                    : Colors.amber,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  isDiscovered ? '✓' : '?',
                                  style: const TextStyle(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16.0),

                            // Business info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    business['businessName'] ?? 'Business',
                                    style: FlutterFlowTheme.of(context)
                                        .titleSmall,
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    business['category'] ?? 'Category',
                                    style: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .override(
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                        ),
                                  ),
                                ],
                              ),
                            ),

                            // Arrow
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16.0,
                              color: FlutterFlowTheme.of(context).primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
