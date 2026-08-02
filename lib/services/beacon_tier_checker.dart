import '/backend/backend.dart';

/// Utility for checking Location Beacon feature access based on subscription tier.
class BeaconTierChecker {
  /// List of subscription tiers that have Location Beacon access.
  /// Community/free tier is explicitly excluded.
  static const List<String> allowedTiers = [
    'Founding Local',
    'Founding Local+',
    'Elite Tier',
  ];

  /// Checks if a user's subscription tier allows Location Beacon feature.
  /// Returns true if tier is Founding Local or higher.
  /// Returns false if tier is Community/free or null.
  static bool canAccessBeacon(String? subscriptionTier) {
    if (subscriptionTier == null || subscriptionTier.isEmpty) {
      return false; // Default to free/community tier, no access
    }
    return allowedTiers.contains(subscriptionTier);
  }

  /// Checks if a business can broadcast a location beacon.
  /// Requires:
  /// 1. Business must be marked as mobile vendor
  /// 2. Business must be claimed and verified
  /// 3. Owner's subscription tier must support beacons
  static Future<bool> canBusinessBroadcast({
    required BusinessesRecord business,
    required String? userSubscriptionTier,
  }) async {
    // Must be marked as mobile vendor
    if (business.isMobileVendor != true) {
      return false;
    }

    // Must be claimed (non-null owner reference)
    if (business.claimedBy == null) {
      return false;
    }

    // Must have appropriate subscription tier
    if (!canAccessBeacon(userSubscriptionTier)) {
      return false;
    }

    return true;
  }

  /// Returns a user-friendly error message explaining why beacon access is denied.
  static String getAccessDenialMessage(
    String? subscriptionTier, {
    bool isMobileVendor = false,
    bool isClaimed = true,
  }) {
    if (!isMobileVendor) {
      return 'Location Beacon is only available for mobile businesses like food trucks and mobile services.';
    }

    if (!isClaimed) {
      return 'Claim your business first to access Location Beacon.';
    }

    if (!canAccessBeacon(subscriptionTier)) {
      return 'Upgrade to Founding Local ($59/month) to broadcast your location with Location Beacon.';
    }

    return 'Cannot access Location Beacon. Please check your subscription status.';
  }

  /// Returns a short string describing beacon tier requirements for UI display.
  static String getTierRequirementText() {
    return 'Founding Local+ tier required';
  }

  /// Returns the minimum price tier that supports beacons.
  static String getMinimumPricingTier() {
    return 'Founding Local (\$59/month)';
  }

  /// Checks if all conditions are met for broadcasting.
  /// Used for enabling/disabling the "Start Broadcasting" button.
  static Future<BeaconAccessStatus> checkBeaconAccess({
    required BusinessesRecord? business,
    required UsersRecord? user,
  }) async {
    // Null business
    if (business == null) {
      return BeaconAccessStatus.noBusiness;
    }

    // Null user (shouldn't happen in normal flow)
    if (user == null) {
      return BeaconAccessStatus.noUser;
    }

    // Not a mobile vendor
    if (business.isMobileVendor != true) {
      return BeaconAccessStatus.notMobileVendor;
    }

    // Business not claimed
    if (business.claimedBy == null) {
      return BeaconAccessStatus.notClaimed;
    }

    // Wrong subscription tier
    if (!canAccessBeacon(user.subscriptionTier)) {
      return BeaconAccessStatus.wrongTier;
    }

    // All checks passed
    return BeaconAccessStatus.allowed;
  }
}

/// Enum representing different access denial reasons.
enum BeaconAccessStatus {
  allowed,
  noBusiness,
  noUser,
  notMobileVendor,
  notClaimed,
  wrongTier,
}

/// Extension for user-friendly messages.
extension BeaconAccessStatusMessage on BeaconAccessStatus {
  String getMessage() {
    switch (this) {
      case BeaconAccessStatus.allowed:
        return 'Location Beacon available';
      case BeaconAccessStatus.noBusiness:
        return 'No business found';
      case BeaconAccessStatus.noUser:
        return 'User not authenticated';
      case BeaconAccessStatus.notMobileVendor:
        return 'Not a mobile business';
      case BeaconAccessStatus.notClaimed:
        return 'Business must be claimed first';
      case BeaconAccessStatus.wrongTier:
        return 'Upgrade to Founding Local (\$59/month)';
    }
  }

  bool get isAllowed => this == BeaconAccessStatus.allowed;
  bool get isDenied => !isAllowed;
}
