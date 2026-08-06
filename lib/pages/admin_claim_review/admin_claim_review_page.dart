import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Admin review queue for `claim_requests` - the screen that didn't exist
/// before this: approval only ever happened from a terminal, running
/// firebase/scripts/approve_claim.js with a service account key. This is
/// the same queue, reachable from the phone.
///
/// Approve/reject both run through the `resolveClaimRequest` callable
/// (firebase/custom_cloud_functions/claim_review.js), which re-checks
/// is_admin server-side and does every cross-collection write itself
/// (businesses.owner_ref, users.owned_business, the ticker reservation) -
/// nothing here writes to those collections directly, same reasoning as
/// AdminSubmissionsPage/resolveBusinessSubmissionReview.
///
/// claim_requests is read-gated to admins only in firestore.rules (it
/// carries applicant email/phone) - the admin check below runs first and
/// gates the query itself, so a non-admin who somehow lands here sees a
/// redirect, not a permission-denied error.
class AdminClaimReviewPage extends StatefulWidget {
  const AdminClaimReviewPage({super.key});

  static String routeName = 'AdminClaimReview';
  static String routePath = '/adminClaimReview';

  @override
  State<AdminClaimReviewPage> createState() => _AdminClaimReviewPageState();
}

class _AdminClaimReviewPageState extends State<AdminClaimReviewPage> {
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

  Future<void> _resolve(
    String claimId,
    String action, {
    String? businessName,
    bool? blackOwned,
    bool? veteran,
    bool? verify,
    String? reviewNote,
  }) async {
    safeSetState(() => _busy.add(claimId));
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('resolveClaimRequest')
          .call<Map<String, dynamic>>({
        'claimId': claimId,
        'action': action,
        if (blackOwned != null) 'blackOwned': blackOwned,
        if (veteran != null) 'veteran': veteran,
        if (verify != null) 'verify': verify,
        if (reviewNote != null && reviewNote.trim().isNotEmpty)
          'reviewNote': reviewNote.trim(),
      });
      if (!mounted) return;
      final approved = result.data['action'] == 'approved';
      final name = (result.data['businessName'] as String?)?.isNotEmpty == true
          ? result.data['businessName'] as String
          : (businessName ?? 'That business');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approved ? '$name approved.' : '$name\'s claim rejected.'),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Couldn't update that claim.")),
      );
    } finally {
      if (mounted) safeSetState(() => _busy.remove(claimId));
    }
  }

  Future<void> _confirmApprove(ClaimRequestsRecord claim) async {
    var blackOwned = claim.declaredBlackOwned;
    var veteran = claim.declaredVeteran;
    var verify = false;
    final theme = FlutterFlowTheme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: theme.secondaryBackground,
          title: Text('Approve claim', style: theme.headlineSmall),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${claim.businessName} → ${claim.claimantName}',
                  style: theme.bodyMedium
                      .override(color: theme.secondaryText),
                ),
                const SizedBox(height: 12.0),
                // Pre-filled from what the claimant checked, but editable -
                // this is the actual decision, not a rubber stamp on their
                // own declaration.
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Black-owned', style: theme.bodyMedium),
                  subtitle: Text(
                    claim.declaredBlackOwned
                        ? 'Claimant declared: yes'
                        : 'Claimant declared: no',
                    style: theme.labelSmall
                        .override(color: theme.secondaryText),
                  ),
                  value: blackOwned,
                  onChanged: (v) => setDialogState(() => blackOwned = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Veteran-owned', style: theme.bodyMedium),
                  subtitle: Text(
                    claim.declaredVeteran
                        ? 'Claimant declared: yes'
                        : 'Claimant declared: no',
                    style: theme.labelSmall
                        .override(color: theme.secondaryText),
                  ),
                  value: veteran,
                  onChanged: (v) => setDialogState(() => veteran = v),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text('Also mark Verified', style: theme.bodyMedium),
                  subtitle: Text(
                    'Separate trust badge, off by default - required '
                    'before this owner can post in The Exchange.',
                    style: theme.labelSmall
                        .override(color: theme.secondaryText),
                  ),
                  value: verify,
                  onChanged: (v) => setDialogState(() => verify = v ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('Cancel',
                  style: theme.bodyMedium.override(color: theme.secondaryText)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: theme.primary),
              child: Text('Approve',
                  style: theme.bodyMedium.override(color: theme.info)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _resolve(
        claim.reference.id,
        'approve',
        businessName: claim.businessName,
        blackOwned: blackOwned,
        veteran: veteran,
        verify: verify,
      );
    }
  }

  Future<void> _confirmReject(ClaimRequestsRecord claim) async {
    final noteController = TextEditingController();
    final theme = FlutterFlowTheme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.secondaryBackground,
        title: Text('Reject claim', style: theme.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${claim.businessName} → ${claim.claimantName}',
              style: theme.bodyMedium.override(color: theme.secondaryText),
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: noteController,
              maxLines: 3,
              style: theme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Reason (optional) - sent to the claimant',
                hintStyle: theme.bodySmall.override(color: theme.hint),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel',
                style: theme.bodyMedium.override(color: theme.secondaryText)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: theme.error),
            child: Text('Reject', style: theme.bodyMedium.override(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _resolve(
        claim.reference.id,
        'reject',
        businessName: claim.businessName,
        reviewNote: noteController.text,
      );
    }
  }

  Future<void> _openLink(String url, {bool isEmail = false, bool isPhone = false}) async {
    final uri = isEmail
        ? Uri(scheme: 'mailto', path: url)
        : isPhone
            ? Uri(scheme: 'tel', path: url)
            : Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _chip(FlutterFlowTheme theme, String label, Color color) => Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        child: Text(label,
            style: theme.labelSmall
                .override(color: color, fontWeight: FontWeight.w600)),
      );

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (!_confirmedAdmin) {
      return Scaffold(
        backgroundColor: theme.primaryBackground,
        body: Center(
          child: SizedBox(
            width: 50.0,
            height: 50.0,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(theme.secondaryText),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        automaticallyImplyLeading: true,
        foregroundColor: theme.info,
        title: Text(
          'Business Claims',
          style: theme.headlineMedium.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            color: theme.info,
          ),
        ),
        centerTitle: false,
        elevation: 0.0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // No `where` on status - same reasoning as AdminSubmissionsPage:
        // an equality filter needs a composite index alongside orderBy,
        // and status is filtered client-side below instead.
        stream: ClaimRequestsRecord.collection
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: theme.primary));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  "Couldn't load claims. This screen is admin-only.",
                  textAlign: TextAlign.center,
                  style: theme.bodyMedium,
                ),
              ),
            );
          }

          final pending = (snapshot.data?.docs ?? [])
              .map((d) => ClaimRequestsRecord.fromSnapshot(d))
              .where((c) => c.status == 'pending')
              .toList();

          if (pending.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fact_check_outlined,
                        size: 48.0, color: theme.secondaryText),
                    const SizedBox(height: 12.0),
                    Text('Nothing waiting for review', style: theme.titleSmall),
                    const SizedBox(height: 4.0),
                    Text(
                      'Business claims submitted from the app show up here.',
                      textAlign: TextAlign.center,
                      style: theme.bodySmall.override(color: theme.secondaryText),
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
              final claim = pending[i];
              final busy = _busy.contains(claim.reference.id);

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
                      Text(claim.businessName,
                          style: theme.titleSmall
                              .override(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2.0),
                      Text(
                        '${claim.claimantName}'
                        '${claim.claimantRole.isNotEmpty ? ' · ${claim.claimantRole}' : ''}',
                        style: theme.bodySmall
                            .override(color: theme.secondaryText),
                      ),
                      if (claim.attestedAt != null)
                        Text(
                          'Attested ${DateFormat.yMMMd().add_jm().format(claim.attestedAt!)}',
                          style: theme.labelSmall
                              .override(color: theme.secondaryText),
                        ),
                      const SizedBox(height: 10.0),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          _chip(
                            theme,
                            claim.declaredBlackOwned
                                ? 'Declares Black-owned'
                                : 'Not declared Black-owned',
                            claim.declaredBlackOwned
                                ? theme.success
                                : theme.secondaryText,
                          ),
                          if (claim.declaredVeteran)
                            _chip(theme, 'Declares veteran-owned', theme.success),
                          if (claim.isMobileVendor)
                            _chip(theme, 'Mobile vendor', theme.warning),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      if (claim.contactEmail.isNotEmpty)
                        InkWell(
                          onTap: () => _openLink(claim.contactEmail, isEmail: true),
                          child: Text(
                            claim.contactEmail,
                            style: theme.bodySmall.override(
                              color: theme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      if (claim.contactPhone.isNotEmpty)
                        InkWell(
                          onTap: () => _openLink(claim.contactPhone, isPhone: true),
                          child: Text(
                            claim.contactPhone,
                            style: theme.bodySmall.override(
                              color: theme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      if (claim.verificationProofLink.isNotEmpty)
                        InkWell(
                          onTap: () => _openLink(claim.verificationProofLink),
                          child: Text(
                            'View proof link',
                            style: theme.bodySmall.override(
                              color: theme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12.0),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: busy ? null : () => _confirmReject(claim),
                              child: Text('Reject',
                                  style: theme.bodyMedium
                                      .override(color: theme.error)),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: busy ? null : () => _confirmApprove(claim),
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.primary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12.0),
                              ),
                              child: Text(
                                busy ? 'Working...' : 'Approve',
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
}
