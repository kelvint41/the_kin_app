import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/components/main_menu_button.dart';

/// Shown in place of a feature that is built but deliberately not public yet.
///
/// This is the backstop rather than the only defence: the entry points that
/// lead here are hidden for non-admins too. Both exist because hiding a
/// button only stops taps - it does nothing about a deep link, a stale
/// back-stack entry, or a route pushed by code that forgot the check. The
/// route-level gate is what actually guarantees nobody lands on an unfinished
/// feature.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({
    super.key,
    this.featureName = 'This feature',
    this.blurb,
  });

  static String routeName = 'ComingSoon';
  static String routePath = '/comingSoon';

  final String featureName;
  final String? blurb;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        automaticallyImplyLeading: true,
        title: Text(
          'Coming soon',
          style: theme.headlineMedium.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            color: theme.info,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
            child: MainMenuButton(),
          ),
        ],
        centerTitle: false,
        elevation: 0.0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_top_rounded,
                  size: 56.0, color: theme.primary),
              const SizedBox(height: 20.0),
              Text(
                '$featureName is on the way',
                textAlign: TextAlign.center,
                style: theme.headlineSmall,
              ),
              const SizedBox(height: 12.0),
              Text(
                blurb ??
                    "We're still building this one. It'll show up here as "
                        'soon as it\'s ready.',
                textAlign: TextAlign.center,
                style: theme.bodyMedium.override(color: theme.secondaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
