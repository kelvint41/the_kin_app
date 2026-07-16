/// Single source of truth for subscription tiers on the CLIENT.
///
/// This is a DISPLAY-ONLY mirror of the authoritative server table at
/// `firebase/custom_cloud_functions/tier_config.js`. Every real tier
/// decision (Power Hour caps, entitlement flags, AI Marketing access) is
/// enforced server-side; this copy exists so the UI can show/validate
/// against a tier's limits without a round-trip - e.g. the Power Hour
/// duration picker's maximum.
///
/// A literal can't be shared across the Dart and Node runtimes, so the two
/// files must be kept in agreement by hand. If you change a tier here,
/// change it in tier_config.js too.
///
/// Tier names are the exact `subscription_tier` strings the upgrade flow
/// writes (see merchant_pricing_suite_widget.dart).
class TierConfig {
  const TierConfig({
    required this.isPremium,
    required this.isPriorityPinned,
    required this.hasFlashBeacon,
    required this.powerHourDurationCapMinutes,
    required this.powerHourWeeklyLimit,
    required this.aiMarketingEntitled,
  });

  final bool isPremium;
  final bool isPriorityPinned;
  final bool hasFlashBeacon;
  final int powerHourDurationCapMinutes;

  /// Max Power Hours per rolling 7-day window. Null means unlimited.
  final int? powerHourWeeklyLimit;
  final bool aiMarketingEntitled;
}

/// The four real tiers. Keep in sync with `TIERS` in tier_config.js.
const kTierConfigs = <String, TierConfig>{
  'Community': TierConfig(
    isPremium: false,
    isPriorityPinned: false,
    hasFlashBeacon: false,
    powerHourDurationCapMinutes: 30,
    powerHourWeeklyLimit: 1,
    aiMarketingEntitled: false,
  ),
  'Founding Local': TierConfig(
    isPremium: true,
    isPriorityPinned: false,
    hasFlashBeacon: false,
    powerHourDurationCapMinutes: 45,
    powerHourWeeklyLimit: 2,
    aiMarketingEntitled: false,
  ),
  'Pro Growth': TierConfig(
    isPremium: true,
    isPriorityPinned: false,
    hasFlashBeacon: false,
    powerHourDurationCapMinutes: 60,
    powerHourWeeklyLimit: 3,
    aiMarketingEntitled: true,
  ),
  'Elite Growth': TierConfig(
    isPremium: true,
    isPriorityPinned: true,
    hasFlashBeacon: true,
    powerHourDurationCapMinutes: 90,
    powerHourWeeklyLimit: null,
    aiMarketingEntitled: true,
  ),
};

/// Config for [tier], falling back to Community's for an unknown value (a
/// typo, or an ad-hoc tier set outside the normal upgrade flow) rather than
/// risk showing broader limits than the server will actually allow. Mirrors
/// the server's `DEFAULT_TIER_KEY` fail-safe.
TierConfig tierConfigFor(String tier) =>
    kTierConfigs[tier] ?? kTierConfigs['Community']!;
