// Single source of truth for subscription tiers on the SERVER.
//
// Every server-side tier decision reads from here: entitlement flags
// (set_business_subscription.js), Power Hour caps (power_hour.js), and AI
// Marketing access (ai_marketing_orchestrator.js). Before this file those
// three lived as three separate literals that had to be kept in sync by
// hand.
//
// The Dart client has a MIRROR of this table at lib/services/tier_config.dart
// (used for display only - duration pickers, pricing labels). A literal
// can't be shared across the Node and Dart runtimes, so the two files must
// be kept in agreement manually. If you change a tier here, change it there
// too.
//
// Tier names are the exact subscription_tier strings the upgrade flow writes
// (see merchant_pricing_suite_widget.dart) - not generic Community/Pro/Elite.
//
// powerHourWeeklyLimit: null means unlimited (skip the frequency check).
//
// revenueCatProductId: the RevenueCat/store product identifier a purchase of
// this tier grants (matches the package ids in
// merchant_pricing_suite_widget.dart). null for the free Community tier.
// setBusinessSubscription verifies an active subscription to this product
// against RevenueCat before writing a paid tier. If your RevenueCat product
// identifiers differ from these package ids, update them here.
//
// NOTE (pre-existing parity): 'Elite Growth' has hasFlashBeacon true with no
// expiry set at upgrade time. checkAndExpireBeacons only clears docs where
// flash_beacon_expires_at < now, so an Elite upgrade's beacon stays on until
// a Power Hour or downgrade overwrites it. Flip to false here if that's not
// intended (Elite owners can still start real Power Hours).
const TIERS = {
  "Community": {
    isPremium: false,
    isPriorityPinned: false,
    hasFlashBeacon: false,
    powerHourDurationCapMinutes: 30,
    powerHourWeeklyLimit: 1,
    aiMarketingEntitled: false,
    // Free tier - no purchase, so no product to verify against RevenueCat.
    revenueCatProductId: null,
  },
  "Founding Local": {
    isPremium: true,
    isPriorityPinned: false,
    hasFlashBeacon: false,
    powerHourDurationCapMinutes: 45,
    powerHourWeeklyLimit: 2,
    aiMarketingEntitled: false,
    revenueCatProductId: "founding_local_monthly",
  },
  "Pro Growth": {
    isPremium: true,
    isPriorityPinned: false,
    hasFlashBeacon: false,
    powerHourDurationCapMinutes: 60,
    powerHourWeeklyLimit: 3,
    aiMarketingEntitled: true,
    revenueCatProductId: "pro_growth_monthly",
  },
  "Elite Growth": {
    isPremium: true,
    isPriorityPinned: true,
    hasFlashBeacon: true,
    powerHourDurationCapMinutes: 90,
    powerHourWeeklyLimit: null,
    aiMarketingEntitled: true,
    revenueCatProductId: "elite_growth_monthly",
  },
};

// Fallback for a subscription_tier that isn't a known key (a typo, or an
// ad-hoc value like 'Founder'/'unlimited' set outside the normal upgrade
// flow). Fails safe to Community's Power Hour limits rather than granting
// broader access. Used only where a tier is expected to already exist
// (Power Hour); setBusinessSubscription instead rejects unknown tiers.
const DEFAULT_TIER_KEY = "Community";

function isKnownTier(tier) {
  return Object.prototype.hasOwnProperty.call(TIERS, tier);
}

// Entitlement flags to write on the business doc for a given tier.
function flagsForTier(tier) {
  const t = TIERS[tier];
  if (!t) return null;
  return {
    is_premium: t.isPremium,
    is_priority_pinned: t.isPriorityPinned,
    has_flash_beacon: t.hasFlashBeacon,
  };
}

// Power Hour caps for a tier, falling back to the default tier's caps for
// an unknown tier.
function powerHourLimits(tier) {
  const t = TIERS[tier] || TIERS[DEFAULT_TIER_KEY];
  return {
    durationCapMinutes: t.powerHourDurationCapMinutes,
    weeklyLimit: t.powerHourWeeklyLimit,
  };
}

function isAiMarketingEntitled(tier) {
  return !!(TIERS[tier] && TIERS[tier].aiMarketingEntitled);
}

// RevenueCat/store product id a paid tier requires, or null for a free tier
// (or an unknown tier). null means "no purchase to verify".
function revenueCatProductId(tier) {
  return (TIERS[tier] && TIERS[tier].revenueCatProductId) || null;
}

module.exports = {
  TIERS,
  isKnownTier,
  flagsForTier,
  powerHourLimits,
  isAiMarketingEntitled,
  revenueCatProductId,
};
