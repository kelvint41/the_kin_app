import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';

/// Generic account screen for the [Account] tab of the persistent bottom
/// navigation (see `components/kin_scaffold.dart`).
///
/// Intentionally a simple placeholder for now. The premium / "Upgrade"
/// branching lands once the RevenueCat entitlement webhook is in place
/// (PAYMENTS_BLUEPRINT.md, Phase B): at that point this screen will read
/// live entitlement from RevenueCat's `CustomerInfo` and show either the
/// active subscription status or an upgrade call-to-action, rather than the
/// static "coming soon" panel below.
class AccountPageWidget extends StatelessWidget {
  const AccountPageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        automaticallyImplyLeading: false,
        title: Text(
          'Account',
          style: theme.headlineSmall.copyWith(color: theme.info),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Account', style: theme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Manage your profile and subscription here.',
                style: theme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.secondaryBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.alternate),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Subscription', style: theme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Plan management is coming soon.',
                      style: theme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
