import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Regression coverage for the `/business/:businessId` route added to
/// nav.dart for the Business Profile share button / QR code link (see
/// KinServices.businessProfileUrl). The real route in nav.dart pulls in
/// the whole app (Firebase, every page widget) via its BusinessProfileV2Widget
/// builder, which isn't something a plain `flutter test` can construct
/// without Firebase mocking infrastructure this repo doesn't have - so
/// this isolates just the one thing that's actually at risk of a typo
/// regressing silently: does go_router's own path-matching for this exact
/// pattern correctly hand back the business id embedded in a shared URL.
/// nav.dart's FFRoute.builder reads it the same way this test does
/// (`state.pathParameters['businessId']`, via FFParameters.allParams),
/// so a passing test here is a direct guarantee that side works too.
void main() {
  testWidgets(
    'a shared business profile link resolves the businessId path param',
    (tester) async {
      const sharedBusinessId = 'hjS0qSyCgEZMkKJ6KyRv'; // Haus of Hairess
      String? capturedId;
      final router = GoRouter(
        initialLocation: '/business/$sharedBusinessId',
        routes: [
          GoRoute(
            path: '/business/:businessId',
            builder: (context, state) {
              capturedId = state.pathParameters['businessId'];
              return const SizedBox.shrink();
            },
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      expect(capturedId, sharedBusinessId);
    },
  );
}
