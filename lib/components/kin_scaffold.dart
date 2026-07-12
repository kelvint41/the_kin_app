import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/flutter_flow/flutter_flow_theme.dart';

/// Persistent bottom-navigation host for the app's four main tabs
/// (Explore / Map / Favorites / Account).
///
/// Rendered by the `StatefulShellRoute.indexedStack` in
/// `flutter_flow/nav/nav.dart`. Because that route type is backed by an
/// `IndexedStack`, each tab keeps its own `Navigator` — and therefore its
/// navigation stack and scroll position — alive when you switch away and
/// back. The app "remembers where the user is" per tab for free; there is
/// no manual index bookkeeping to maintain.
class KinScaffold extends StatelessWidget {
  const KinScaffold({super.key, required this.navigationShell});

  /// The shell handed in by StatefulShellRoute.indexedStack. Owns the
  /// current branch index and the per-branch Navigators.
  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    // Switch branches, preserving each branch's state. Tapping the tab you
    // are already on returns that branch to its root — the expected mobile
    // behavior — via initialLocation.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        backgroundColor: theme.primary, // KIN Evergreen #0B3D2E
        indicatorColor: theme.accent1.withOpacity(0.20), // brand gold wash
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined, color: theme.secondaryText),
            selectedIcon: Icon(Icons.explore, color: theme.accent1),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined, color: theme.secondaryText),
            selectedIcon: Icon(Icons.map, color: theme.accent1),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline, color: theme.secondaryText),
            selectedIcon: Icon(Icons.favorite, color: theme.accent1),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: theme.secondaryText),
            selectedIcon: Icon(Icons.person, color: theme.accent1),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
