import '/auth/firebase_auth/auth_util.dart';

/// Features that exist in the build but aren't ready for the public.
///
/// One source of truth on purpose. The Exchange is reachable from five
/// different places (hamburger menu, shoutout carousel, Customer Profile,
/// Business Profile, and the Feed tab), and a flag checked independently in
/// five places is a flag that will be wrong in at least one of them.
class FeatureFlags {
  /// The Exchange and the Nearby Feed - the app's social layer.
  ///
  /// Held back until video posting and moderation are settled. Admins keep
  /// full access so the feature can be built and tested against real data
  /// while the public sees a Coming Soon screen.
  ///
  /// Covers the Nearby Feed as well as The Exchange itself, which is easy to
  /// miss: the Feed tab renders the same `exchange_posts` content,
  /// aggregated across nearby businesses. Gating only The Exchange would
  /// leave the identical social feed one tap away on the bottom nav.
  static bool get exchangeEnabled => currentUserDocument?.isAdmin == true;
}
