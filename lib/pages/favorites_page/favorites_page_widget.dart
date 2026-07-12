import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';

/// Generic favorites screen for the [Favorites] tab of the persistent bottom
/// navigation (see `components/kin_scaffold.dart`). Placeholder for now —
/// will list the businesses the user has saved.
class FavoritesPageWidget extends StatelessWidget {
  const FavoritesPageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        automaticallyImplyLeading: false,
        title: Text(
          'Favorites',
          style: theme.headlineSmall.copyWith(color: theme.info),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border, size: 48, color: theme.secondaryText),
              const SizedBox(height: 16),
              Text(
                'No favorites yet',
                style: theme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Businesses you save will appear here.',
                style: theme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
