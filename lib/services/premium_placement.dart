// Premium ("Founding Local") placement in the map page's bottom carousel.
//
// Eligibility is subscription status only - there is deliberately no
// Kindex, review or distance ranking here. A merchant pays for the slot,
// so the only question the carousel asks is "is this business on a paid
// plan right now", and every paid business gets an equal share of the
// exposure via `selectPremiumRotation`.

import '/backend/backend.dart';

/// The `businesses.subscription_tier` values that count as a paid plan.
///
/// These are the exact strings the live upgrade flow writes - see
/// `KinServices.upgradeBusinessTier` (called from
/// merchant_pricing_suite_widget.dart) and the tier cards on that page.
/// The free tier is written as `'Community'` by
/// `KinServices.registerBusiness`/`downgradeToCommunity`, and bulk-imported
/// directory rows carry the legacy value `'Free'`; neither is eligible, and
/// neither needs to be listed here because this is an allow-list.
///
/// `'Pro Growth'` is included because it is the tier *above* Founding
/// Local - a merchant paying more than a Founding Local should not lose
/// the placement that the cheaper paid plan grants.
const Set<String> kPaidSubscriptionTiers = {
  'Founding Local',
  'Pro Growth',
};

/// How many businesses the carousel shows at once.
const int kPremiumCarouselSlots = 3;

/// How long a given set of [kPremiumCarouselSlots] businesses stays on
/// screen before the next set takes over. Six windows per day.
const Duration kPremiumRotationWindow = Duration(hours: 4);

/// Businesses currently on a paid plan, in a stable, device-independent
/// order.
///
/// Sorted by document id purely so that every client agrees on the
/// ordering - the id carries no meaning, it just has to be the same
/// everywhere for [selectPremiumRotation] to be deterministic.
List<BusinessesRecord> eligiblePremiumBusinesses(
  List<BusinessesRecord> businesses,
) =>
    businesses
        .where((b) => kPaidSubscriptionTiers.contains(b.subscriptionTier))
        .toList()
      ..sort((a, b) => a.reference.id.compareTo(b.reference.id));

/// Index of the rotation window [now] falls in, counted from the Unix
/// epoch in UTC so that it is the same number on every device regardless
/// of local timezone.
int premiumRotationWindowIndex(
  DateTime now, {
  Duration window = kPremiumRotationWindow,
}) =>
    now.toUtc().millisecondsSinceEpoch ~/ window.inMilliseconds;

/// The [slots] entries of [ordered] that are on display during [now]'s
/// rotation window.
///
/// The starting offset advances by [slots] each window and wraps, so
/// consecutive windows show disjoint sets and every entry has had a turn
/// after `ceil(ordered.length / slots)` windows - at the default 4-hour
/// window that is a full cycle every 4h per group of three paid
/// businesses. The result depends only on [ordered] and the window index,
/// never on load time or a random seed, so re-entering the page inside a
/// window shows the same businesses.
///
/// Returns everything (unrotated) when there is nothing to rotate.
List<T> selectPremiumRotation<T>(
  List<T> ordered, {
  required DateTime now,
  int slots = kPremiumCarouselSlots,
  Duration window = kPremiumRotationWindow,
}) {
  if (ordered.length <= slots) return List<T>.from(ordered);
  final offset = (premiumRotationWindowIndex(now, window: window) * slots) %
      ordered.length;
  return List<T>.generate(
    slots,
    (i) => ordered[(offset + i) % ordered.length],
  );
}

/// The paid businesses to show in the carousel right now.
List<BusinessesRecord> premiumCarouselBusinesses(
  List<BusinessesRecord> businesses, {
  DateTime? now,
}) =>
    selectPremiumRotation(
      eligiblePremiumBusinesses(businesses),
      now: now ?? DateTime.now(),
    );
