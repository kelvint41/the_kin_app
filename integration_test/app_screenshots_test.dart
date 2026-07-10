// App Store / Play Store screenshot automation.
//
// This test doesn't capture pixels itself - Flutter's in-process screenshot
// APIs don't reliably produce the exact device resolutions stores require
// (e.g. 1290x2796 for a 6.7" iPhone), and behave differently per platform.
// Instead this test drives the app to a specific, stable screen and prints
// a marker line; the CI workflow (.github/workflows/screenshots.yml) tails
// the log for that marker and fires `xcrun simctl io booted screenshot` at
// exactly that moment, which captures the simulator's real framebuffer at
// native resolution - the same mechanism a human would use to take a
// screenshot by hand.
//
// Requires (see .github/workflows/screenshots.yml for how these are set):
//   --dart-define=DEV_PASSWORD=...      (the dev-bypass account's password)
//   --dart-define=DEV_EMAIL=...         (defaults to kelvin@apptest.com)
//   --dart-define=DEV_ROUTE=...         (which screen this run starts on)
//   --dart-define=SCREENSHOT_THEME=light|dark
// and a Firestore project seeded via firebase/scripts/seed_screenshot_demo.js.
//
// NOTE: written without access to a real iOS Simulator or Android emulator
// (none were available in the environment this was built in) - the
// marker/finder logic follows the app's actual widget structure, but treat
// the first real CI run as the first real test of this file, not a
// rerun of something already verified end-to-end.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:the_k_i_n_app/main.dart' as app;

/// Poll for [finder] to appear rather than a single pumpAndSettle() -
/// these screens load over a real Firestore network round-trip in CI,
/// which isn't the bounded animation/timer work pumpAndSettle waits out.
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 300));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure(
    'Timed out after $timeout waiting for $finder. '
    'Check the demo data seed (seed_screenshot_demo.js) ran successfully '
    'and DEV_ROUTE points at a real business.',
  );
}

/// Print + a short settle pause so the external `simctl` capture (fired the
/// moment this line appears in the driver log) lands on a fully-rendered,
/// non-mid-animation frame.
Future<void> markScreenshot(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 500));
  // ignore: avoid_print
  print('KIN_SCREENSHOT_READY: $name');
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture marketing screenshots', (tester) async {
    app.main();
    // The dev-bypass sign-in + business-doc lookup happens before the
    // first frame the router can act on; give it real time rather than a
    // fixed pump count.
    await waitFor(
      tester,
      find.byWidgetPredicate((_) => true), // any frame at all
      timeout: const Duration(seconds: 5),
    );
    await tester.pump(const Duration(seconds: 3));

    final onExchange = find.text('The Exchange').evaluate().isNotEmpty;
    final onBusinessProfile =
        find.byIcon(Icons.delivery_dining_sharp).evaluate().isNotEmpty ||
            find.text('Manage Your Business').evaluate().isNotEmpty;

    if (onExchange) {
      await waitFor(tester, find.text('Kindex Spotlight'));
      await markScreenshot(tester, 'the_exchange');

      await tester.tap(find.text('Kindex Spotlight').first);
      await waitFor(tester, find.text('Top Business Owners'));
      await markScreenshot(tester, 'leaderboard');
    } else if (onBusinessProfile) {
      await waitFor(tester, find.text('Open in Maps'));
      await markScreenshot(tester, 'business_profile');
    } else {
      throw TestFailure(
        'Landed on neither The Exchange nor Business Profile V2 - check '
        'the DEV_ROUTE dart-define passed to this run matches one of the '
        'two routes the workflow expects.',
      );
    }
  });
}
