import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/revenue_cat_util.dart' as revenue_cat;

/// "Manage Subscription" and "Restore Purchases", shown under the owner's
/// current-plan card.
///
/// Both are App Store requirements, not conveniences:
///
///  - Apple's Guideline 3.1.2 requires an app selling auto-renewing
///    subscriptions to link the user to where they can manage and cancel
///    one. The app itself cannot cancel: neither Apple nor Google exposes
///    an API for it, by design. All any app can do is deep-link to the
///    store's own subscription settings, which is what this does.
///  - Restore is what lets someone who reinstalls, or signs in on a second
///    device, get back a subscription they already paid for. Without it
///    that person has simply lost their money, and reviewers check for it.
///
/// Deliberately NOT gated on having an active subscription. Someone whose
/// purchase failed to attach to their account is exactly the person who
/// needs Restore, and they are the one whose entitlement looks inactive.
class SubscriptionManagementRow extends StatefulWidget {
  const SubscriptionManagementRow({super.key});

  @override
  State<SubscriptionManagementRow> createState() =>
      _SubscriptionManagementRowState();
}

class _SubscriptionManagementRowState extends State<SubscriptionManagementRow> {
  bool _restoring = false;

  Future<void> _openManagement() async {
    final url = Uri.parse(revenue_cat.subscriptionManagementUrl());
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Couldn't open your store's subscription settings. You can "
            'manage your plan from the App Store or Play Store app.',
          ),
        ),
      );
    }
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    final restored = await revenue_cat.restorePurchases();
    if (!mounted) return;
    setState(() => _restoring = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored
              ? 'Your subscription has been restored.'
              : 'No previous purchases found for this account.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24.0, 12.0, 24.0, 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextButton.icon(
            onPressed: _openManagement,
            icon: Icon(Icons.open_in_new_rounded,
                size: 18.0, color: theme.primary),
            label: Text(
              'Manage or Cancel Subscription',
              style: theme.bodyMedium.override(color: theme.primary),
            ),
          ),
          TextButton(
            onPressed: _restoring ? null : _restore,
            child: Text(
              _restoring ? 'Restoring...' : 'Restore Purchases',
              style: theme.bodySmall.override(color: theme.secondaryText),
            ),
          ),
          // Sets expectations before the user leaves the app, and explains
          // why cancelling doesn't take effect instantly - the single most
          // common "your app charged me again" support ticket.
          Text(
            'Cancelling stops future renewals. You keep your plan until the '
            'end of the period you already paid for.',
            textAlign: TextAlign.center,
            style: theme.labelSmall.override(color: theme.secondaryText),
          ),
        ],
      ),
    );
  }
}
