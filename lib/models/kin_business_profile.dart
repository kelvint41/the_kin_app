import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/models/kin_social_share.dart';

class KinBusinessReview {
  const KinBusinessReview({
    required this.authorName,
    required this.body,
    required this.rating,
    this.createdAt,
  });

  final String authorName;
  final String body;
  final double rating;
  final DateTime? createdAt;

  factory KinBusinessReview.fromMap(Map<String, dynamic> map) {
    return KinBusinessReview(
      authorName: map['author_name'] as String? ??
          map['author'] as String? ??
          map['authorName'] as String? ??
          'Community member',
      body: map['body'] as String? ??
          map['text'] as String? ??
          map['review'] as String? ??
          '',
      rating: _readDouble(map['rating'] ?? map['stars'], fallback: 0.0) ?? 0.0,
      createdAt: _readDateTime(map['created_at'] ?? map['createdAt']),
    );
  }
}

/// Growth-feature fields for businesses. Isolated from map/directory navigation
/// and external Google Places ingestion (defaults to empty unless Firestore).
class KinBusinessGrowthMetrics {
  const KinBusinessGrowthMetrics({
    this.verifiedCheckIns = '0',
    this.socialShareConfig = KinSocialShareConfig.empty,
  });

  static const empty = KinBusinessGrowthMetrics();

  /// Firestore stores this as a string counter (e.g. `"12"`, `"1,024"`).
  final String verifiedCheckIns;
  final KinSocialShareConfig socialShareConfig;

  int get verifiedCheckInsCount {
    final digitsOnly = verifiedCheckIns.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digitsOnly) ?? 0;
  }

  factory KinBusinessGrowthMetrics.fromFirestore({
    String? verifiedCheckIns,
    Map<String, dynamic>? socialShareConfig,
  }) {
    return KinBusinessGrowthMetrics(
      verifiedCheckIns: verifiedCheckIns?.trim().isNotEmpty == true
          ? verifiedCheckIns!.trim()
          : '0',
      socialShareConfig:
          KinSocialShareConfig.fromMap(socialShareConfig ?? const {}),
    );
  }

  factory KinBusinessGrowthMetrics.fromBusinessRecord(BusinessesRecord record) {
    return KinBusinessGrowthMetrics.fromFirestore(
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

/// Normalized business profile for map pins and directory cards.
/// Supports Firestore records and external JSON/API feeds.
class KinBusinessProfile {
  const KinBusinessProfile({
    required this.id,
    required this.displayName,
    required this.category,
    required this.address,
    required this.city,
    required this.state,
    required this.heroImageUrl,
    required this.galleryImageUrls,
    required this.location,
    required this.kindexScore,
    required this.tickerSymbol,
    required this.isBlackOwned,
    required this.isBobVerified,
    required this.isFeatured,
    required this.isVeteran,
    required this.phone,
    required this.website,
    required this.description,
    required this.reviews,
    required this.averageReviewRating,
    this.growthMetrics = KinBusinessGrowthMetrics.empty,
  });

  final String id;
  final String displayName;
  final String category;
  final String address;
  final String city;
  final String state;
  final String? heroImageUrl;
  final List<String> galleryImageUrls;
  final LatLng? location;
  final double kindexScore;
  final String? tickerSymbol;
  final bool isBlackOwned;
  final bool isBobVerified;
  final bool isFeatured;
  final bool isVeteran;
  final String? phone;
  final String? website;
  final String? description;
  final List<KinBusinessReview> reviews;
  final double averageReviewRating;
  final KinBusinessGrowthMetrics growthMetrics;

  bool get hasMapLocation => location != null;

  /// Keeps Firestore growth metrics when an external feed overwrites map data.
  KinBusinessProfile withPreservedGrowthMetrics(
    KinBusinessGrowthMetrics metrics,
  ) {
    return KinBusinessProfile(
      id: id,
      displayName: displayName,
      category: category,
      address: address,
      city: city,
      state: state,
      heroImageUrl: heroImageUrl,
      galleryImageUrls: galleryImageUrls,
      location: location,
      kindexScore: kindexScore,
      tickerSymbol: tickerSymbol,
      isBlackOwned: isBlackOwned,
      isBobVerified: isBobVerified,
      isFeatured: isFeatured,
      isVeteran: isVeteran,
      phone: phone,
      website: website,
      description: description,
      reviews: reviews,
      averageReviewRating: averageReviewRating,
      growthMetrics: metrics,
    );
  }

  /// Applies Firestore-only metadata when merging an external feed profile.
  KinBusinessProfile withPreservedFirestoreMetadata(
    KinBusinessProfile prior,
  ) {
    return KinBusinessProfile(
      id: id,
      displayName: displayName,
      category: category,
      address: address,
      city: city,
      state: state,
      heroImageUrl: heroImageUrl,
      galleryImageUrls: galleryImageUrls,
      location: location,
      kindexScore: kindexScore,
      tickerSymbol: tickerSymbol,
      isBlackOwned: prior.isBlackOwned || isBlackOwned,
      isBobVerified: isBobVerified,
      isFeatured: prior.isFeatured || isFeatured,
      isVeteran: prior.isVeteran || isVeteran,
      phone: phone,
      website: website,
      description: description,
      reviews: reviews,
      averageReviewRating: averageReviewRating,
      growthMetrics: prior.growthMetrics,
    );
  }

  String get formattedAddress {
    final parts = [
      address,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
    ].where((part) => part.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  String get primaryImageUrl =>
      heroImageUrl ??
      (galleryImageUrls.isNotEmpty ? galleryImageUrls.first : null) ??
      '';

  /// Applies one review rating to a running Kindex score (100–750 clamp).
  static int applyReviewToKindexScore({
    required double currentScore,
    required int reviewRating,
  }) {
    double scoreChange = 0.0;

    switch (reviewRating) {
      case 5:
        scoreChange = 15.0;
        break;
      case 4:
        scoreChange = 5.0;
        break;
      case 1:
        scoreChange = -15.0;
        break;
      case 2:
        scoreChange = -5.0;
        break;
      default:
        scoreChange = 0.0;
    }

    return (currentScore + scoreChange).round().clamp(100, 750);
  }

  /// Computes Kindex from review-driven math, starting at 100 unless reviews
  /// or an aggregate rating (e.g. Google Places) are available.
  static double computeKindexScore({
    List<KinBusinessReview> reviews = const [],
    double? aggregateRating,
  }) {
    var score = 100.0;

    if (reviews.isNotEmpty) {
      for (final review in reviews) {
        score = applyReviewToKindexScore(
          currentScore: score,
          reviewRating: review.rating.round().clamp(1, 5),
        ).toDouble();
      }
      return score;
    }

    if (aggregateRating != null) {
      return applyReviewToKindexScore(
        currentScore: score,
        reviewRating: aggregateRating.round().clamp(1, 5),
      ).toDouble();
    }

    return score;
  }

  factory KinBusinessProfile.fromFirestore(BusinessesRecord record) {
    final reviews = _readReviews(record.snapshotData['reviews']);
    return KinBusinessProfile(
      id: record.reference.id,
      displayName: _firstNonEmpty([
        record.businessName,
        record.name,
      ]) ?? '',
      category: record.category,
      address: record.address,
      city: record.city,
      state: record.state,
      heroImageUrl: _firstNonEmpty([record.heroImage]),
      galleryImageUrls: _readStringList(record.snapshotData['gallery_images']),
      location: _resolveLocation(record),
      kindexScore: computeKindexScore(reviews: reviews),
      tickerSymbol: _firstNonEmpty([record.tickerSymbol]),
      isBlackOwned: record.isBlackOwned,
      isBobVerified: record.isBobVerified,
      isFeatured: record.isFeatured,
      isVeteran: record.isVeteran,
      phone: _firstNonEmpty([record.phoneNumber, record.phone]),
      website: _firstNonEmpty([record.website]),
      description: record.description,
      reviews: reviews,
      averageReviewRating: _averageRating(reviews),
      growthMetrics: KinBusinessGrowthMetrics.fromBusinessRecord(record),
    );
  }

  factory KinBusinessProfile.fromExternalFeed(Map<String, dynamic> json) {
    final reviews = _readReviews(json['reviews']);
    final gallery = _readStringList(
      json['gallery_images'] ?? json['galleryImages'] ?? json['photos'],
    );
    final heroImage = _firstNonEmpty([
      json['hero_image'] as String?,
      json['heroImage'] as String?,
      json['image'] as String?,
      json['picture'] as String?,
      if (gallery.isNotEmpty) gallery.first,
    ]);

    return KinBusinessProfile(
      id: _firstNonEmpty([
        json['id'] as String?,
        json['business_id'] as String?,
        json['placeID'] as String?,
        json['place_id'] as String?,
      ]) ??
          displayNameFromFeed(json),
      displayName: displayNameFromFeed(json),
      category: json['category'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? json['State'] as String? ?? '',
      heroImageUrl: heroImage,
      galleryImageUrls: gallery,
      location: _readLatLng(json),
      kindexScore: computeKindexScore(
        reviews: reviews,
        aggregateRating: _readDouble(json['rating']),
      ),
      tickerSymbol: _firstNonEmpty([
        json['ticker_symbol'] as String?,
        json['tickerSymbol'] as String?,
      ]),
      isBlackOwned: json['is_black_owned'] as bool? ??
          json['isBlackOwned'] as bool? ??
          true,
      isBobVerified: json['is_bob_verified'] as bool? ??
          json['isBobVerified'] as bool? ??
          false,
      isFeatured: json['is_featured'] as bool? ??
          json['isFeatured'] as bool? ??
          false,
      isVeteran: json['is_veteran'] as bool? ??
          json['isVeteran'] as bool? ??
          false,
      phone: _firstNonEmpty([
        json['phone_number'] as String?,
        json['phoneNumber'] as String?,
        json['phone'] as String?,
        json['Phone'] as String?,
      ]),
      website: json['website'] as String?,
      description: _readString(json['description']) ??
          _googlePlacesDescription(json),
      reviews: reviews,
      averageReviewRating: reviews.isNotEmpty
          ? _averageRating(reviews)
          : (_readDouble(json['rating'], fallback: 0.0) ?? 0.0),
      growthMetrics: KinBusinessGrowthMetrics.empty,
    );
  }
}

class KinBusinessDataMapper {
  KinBusinessDataMapper._();

  static KinBusinessProfile fromFirestore(BusinessesRecord record) =>
      KinBusinessProfile.fromFirestore(record);

  static KinBusinessProfile fromExternalFeed(Map<String, dynamic> json) =>
      KinBusinessProfile.fromExternalFeed(json);

  static List<KinBusinessProfile> fromFirestoreList(
    List<BusinessesRecord> records,
  ) =>
      records.map(fromFirestore).toList();

  static List<KinBusinessProfile> fromExternalFeedList(
    List<Map<String, dynamic>> payload,
  ) =>
      payload.map(fromExternalFeed).toList();
}

String displayNameFromFeed(Map<String, dynamic> json) => _firstNonEmpty([
      json['business_name'] as String?,
      json['businessName'] as String?,
      json['name'] as String?,
    ]) ??
    '';

String? _googlePlacesDescription(Map<String, dynamic> json) {
  final count = _readInt(json['user_rating_count'] ?? json['userRatingCount']);
  if (count != null && count > 0) {
    return 'Google Places listing with $count verified ratings.';
  }
  return null;
}

int? _readInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

LatLng? _resolveLocation(BusinessesRecord record) {
  if (record.hasBusinessLocation()) {
    return record.businessLocation;
  }
  if (record.hasCoordinates()) {
    return record.coordinates;
  }
  if (record.hasLatitude() && record.hasLongitude()) {
    return LatLng(record.latitude, record.longitude);
  }
  return null;
}

LatLng? _readLatLng(Map<String, dynamic> json) {
  final location = json['location'];
  if (location is Map) {
    final lat = _readDouble(location['lat'] ?? location['latitude']);
    final lng = _readDouble(location['lng'] ?? location['longitude']);
    if (lat != null && lng != null) {
      return LatLng(lat, lng);
    }
  }

  final lat = _readDouble(json['latitude'] ?? json['Latitude']);
  final lng = _readDouble(json['longitude'] ?? json['Longitude']);
  if (lat != null && lng != null) {
    return LatLng(lat, lng);
  }

  return null;
}

String? _readString(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return null;
}

List<String> _readStringList(dynamic value) {
  if (value is List) {
    return value
        .whereType<String>()
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }
  return const [];
}

List<KinBusinessReview> _readReviews(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => KinBusinessReview.fromMap(Map<String, dynamic>.from(item)))
        .where((review) => review.body.isNotEmpty || review.rating > 0)
        .toList();
  }
  return const [];
}

double _averageRating(List<KinBusinessReview> reviews) {
  if (reviews.isEmpty) {
    return 0.0;
  }
  final total = reviews.fold<double>(0, (sum, review) => sum + review.rating);
  return total / reviews.length;
}

double? _readDouble(dynamic value, {double? fallback}) {
  if (value == null) {
    return fallback;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}

DateTime? _readDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
