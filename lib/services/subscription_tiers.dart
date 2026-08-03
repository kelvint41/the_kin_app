/// Canonical tier order, lowest to highest.
///
/// Matches the exact strings `KinServices.upgradeBusinessTier` writes and
/// the tier cards on merchant_pricing_suite_widget.dart - the one place a
/// business's tier is actually assigned. `downgradeToCommunity` and
/// `registerBusiness` write `'Community'` for the free tier; legacy
/// bulk-imported rows carry `'Free'` instead, which deliberately has no
/// entry here (see [tierAtLeast]).
const List<String> kSubscriptionTierOrder = [
  'Community',
  'Founder',
  'Founding Local',
  'Premium Local',
  'Elite',
];

/// Whether [tier] is at or above [minimum] in [kSubscriptionTierOrder].
///
/// An unrecognized [tier] (the legacy `'Free'` value, an empty string, a
/// typo) ranks below everything rather than throwing - the failure mode
/// for "which tier is this" being unclear should be "nothing is unlocked,"
/// never "everything is."
bool tierAtLeast(String tier, String minimum) {
  final tierIndex = kSubscriptionTierOrder.indexOf(tier);
  final minIndex = kSubscriptionTierOrder.indexOf(minimum);
  if (tierIndex == -1) return false;
  return tierIndex >= minIndex;
}
