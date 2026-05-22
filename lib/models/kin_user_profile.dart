import '/backend/backend.dart';
import '/models/kin_social_share.dart';

/// Growth-feature fields for users. Not used by navigation or Places feeds.
class KinUserGrowthMetrics {
  const KinUserGrowthMetrics({
    this.verifiedCheckIns = '0',
    this.socialShareConfig = KinSocialShareConfig.empty,
  });

  static const empty = KinUserGrowthMetrics();

  /// Firestore stores this as a string counter (e.g. `"12"`, `"1,024"`).
  final String verifiedCheckIns;
  final KinSocialShareConfig socialShareConfig;

  int get verifiedCheckInsCount {
    final digitsOnly = verifiedCheckIns.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digitsOnly) ?? 0;
  }

  factory KinUserGrowthMetrics.fromFirestore({
    String? verifiedCheckIns,
    Map<String, dynamic>? socialShareConfig,
  }) {
    return KinUserGrowthMetrics(
      verifiedCheckIns: verifiedCheckIns?.trim().isNotEmpty == true
          ? verifiedCheckIns!.trim()
          : '0',
      socialShareConfig:
          KinSocialShareConfig.fromMap(socialShareConfig ?? const {}),
    );
  }

  factory KinUserGrowthMetrics.fromUsersRecord(UsersRecord record) {
    return KinUserGrowthMetrics.fromFirestore(
      verifiedCheckIns:
          record.hasVerifiedCheckIns() ? record.verifiedCheckIns : null,
      socialShareConfig: record.snapshotData['social_share_config'] is Map
          ? Map<String, dynamic>.from(
              record.snapshotData['social_share_config'] as Map,
            )
          : null,
    );
  }

  Map<String, dynamic> toFirestoreMap() => {
        'verified_check_ins': verifiedCheckIns,
        'social_share_config': socialShareConfig.toMap(),
      };
}

/// Normalized user profile configuration for growth and social features.
class KinUserProfile {
  const KinUserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.phoneNumber,
    required this.subscriptionStatus,
    required this.isEliteFounder,
    required this.isActive,
    this.growthMetrics = KinUserGrowthMetrics.empty,
  });

  final String id;
  final String email;
  final String displayName;
  final String photoUrl;
  final String phoneNumber;
  final String subscriptionStatus;
  final bool isEliteFounder;
  final bool isActive;
  final KinUserGrowthMetrics growthMetrics;

  factory KinUserProfile.fromUsersRecord(UsersRecord record) {
    return KinUserProfile(
      id: record.reference.id,
      email: record.email,
      displayName: record.displayName,
      photoUrl: record.photoUrl,
      phoneNumber: record.phoneNumber,
      subscriptionStatus: record.subscriptionStatus,
      isEliteFounder: record.isEliteFounder,
      isActive: record.isActive,
      growthMetrics: KinUserGrowthMetrics.fromUsersRecord(record),
    );
  }
}

class KinUserProfileMapper {
  KinUserProfileMapper._();

  static KinUserProfile fromUsersRecord(UsersRecord record) =>
      KinUserProfile.fromUsersRecord(record);

  static List<KinUserProfile> fromUsersRecordList(List<UsersRecord> records) =>
      records.map(fromUsersRecord).toList();
}
