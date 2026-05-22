import '/models/kin_business_profile.dart';
import '/models/kin_user_profile.dart';

/// Stored social-share preferences (Firestore `social_share_config` map).
/// Isolated from map, directory, and Places ingestion pipelines.
class KinSocialShareConfig {
  const KinSocialShareConfig({
    this.templateId = '',
    this.headline = '',
    this.message = '',
    this.shareUrl = '',
    this.imageUrl = '',
  });

  static const empty = KinSocialShareConfig();

  final String templateId;
  final String headline;
  final String message;
  final String shareUrl;
  final String imageUrl;

  bool get hasOverrides =>
      templateId.isNotEmpty ||
      headline.isNotEmpty ||
      message.isNotEmpty ||
      shareUrl.isNotEmpty ||
      imageUrl.isNotEmpty;

  factory KinSocialShareConfig.fromMap(Map<String, dynamic> map) {
    return KinSocialShareConfig(
      templateId: _readString(map['template_id'] ?? map['templateId']),
      headline: _readString(map['headline']),
      message: _readString(map['message']),
      shareUrl: _readString(map['share_url'] ?? map['shareUrl']),
      imageUrl: _readString(map['image_url'] ?? map['imageUrl']),
    );
  }

  Map<String, dynamic> toMap() => {
        'template_id': templateId,
        'headline': headline,
        'message': message,
        'share_url': shareUrl,
        'image_url': imageUrl,
      };
}

/// Generated share payload ready for platform share sheets.
class KinSocialSharePayload {
  const KinSocialSharePayload({
    required this.title,
    required this.message,
    this.imageUrl,
    this.url,
  });

  final String title;
  final String message;
  final String? imageUrl;
  final String? url;

  Map<String, dynamic> toShareSheetMap() => {
        'title': title,
        'message': message,
        if (imageUrl != null && imageUrl!.isNotEmpty) 'image_url': imageUrl,
        if (url != null && url!.isNotEmpty) 'url': url,
      };
}

/// Builds share copy from profile data plus optional stored overrides.
class KinSocialShareGenerator {
  KinSocialShareGenerator._();

  static KinSocialSharePayload forBusiness({
    required KinBusinessProfile profile,
    KinSocialShareConfig? configOverride,
  }) {
    final config = configOverride ?? profile.growthMetrics.socialShareConfig;
    final kindex = profile.kindexScore.toStringAsFixed(0);
    final checkIns = profile.growthMetrics.verifiedCheckIns;

    final defaultTitle = '${profile.displayName} on KIN';
    final defaultMessage = profile.displayName.isNotEmpty
        ? 'Discover ${profile.displayName} on KIN — Kindex $kindex'
        : 'Discover this Black-owned business on KIN';

    if (checkIns != '0' && checkIns.isNotEmpty) {
      return KinSocialSharePayload(
        title: config.headline.isNotEmpty ? config.headline : defaultTitle,
        message: config.message.isNotEmpty
            ? config.message
            : '$defaultMessage · $checkIns verified check-ins',
        imageUrl: config.imageUrl.isNotEmpty
            ? config.imageUrl
            : profile.primaryImageUrl,
        url: config.shareUrl,
      );
    }

    return KinSocialSharePayload(
      title: config.headline.isNotEmpty ? config.headline : defaultTitle,
      message: config.message.isNotEmpty ? config.message : defaultMessage,
      imageUrl: config.imageUrl.isNotEmpty
          ? config.imageUrl
          : profile.primaryImageUrl,
      url: config.shareUrl,
    );
  }

  static KinSocialSharePayload forUser({
    required KinUserProfile profile,
    KinSocialShareConfig? configOverride,
  }) {
    final config = configOverride ?? profile.growthMetrics.socialShareConfig;
    final defaultTitle = profile.displayName.isNotEmpty
        ? '${profile.displayName} on KIN'
        : 'Join me on KIN';
    final defaultMessage = profile.displayName.isNotEmpty
        ? '${profile.displayName} is building community on KIN.'
        : 'Join the KIN community and support Black-owned businesses.';

    return KinSocialSharePayload(
      title: config.headline.isNotEmpty ? config.headline : defaultTitle,
      message: config.message.isNotEmpty ? config.message : defaultMessage,
      imageUrl: config.imageUrl.isNotEmpty ? config.imageUrl : profile.photoUrl,
      url: config.shareUrl,
    );
  }
}

String _readString(dynamic value) {
  if (value is String) {
    return value.trim();
  }
  return '';
}
