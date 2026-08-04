import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';

/// A persistent floating "Get Support" launcher for business owners.
///
/// Get Support existed only as one row inside the hamburger menu - findable,
/// but not obviously so for an owner who doesn't yet know the menu has it.
/// This is the same destination (SupportChatWidget), just always one tap
/// away as a fixed bubble, the way a chat launcher works in most apps.
///
/// Meant for [Scaffold.floatingActionButton] on owner-facing pages (Owner
/// Profile, Growth Tools) rather than every page in the app - customers
/// already have Get Support one hamburger-tap away too, but the bubble is
/// scoped to where the owner actually spends their time managing the
/// business, not layered onto every customer screen as well.
class SupportBubbleWidget extends StatelessWidget {
  const SupportBubbleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return FloatingActionButton(
      heroTag: 'supportBubble',
      backgroundColor: theme.primary,
      foregroundColor: theme.onPrimary,
      elevation: 4.0,
      onPressed: () => context.pushNamed(SupportChatWidget.routeName),
      child: Icon(Icons.headset_mic_rounded, size: 26.0),
    );
  }
}
