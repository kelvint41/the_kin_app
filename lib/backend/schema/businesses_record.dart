import 'dart:async';

import 'package:from_css_color/from_css_color.dart';
import '/backend/algolia/serialization_util.dart';
import '/backend/algolia/algolia_manager.dart';
import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class BusinessesRecord extends FirestoreRecord {
  BusinessesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "is_black_owned" field.
  bool? _isBlackOwned;
  bool get isBlackOwned => _isBlackOwned ?? false;
  bool hasIsBlackOwned() => _isBlackOwned != null;

  // "is_certified_black_owned" field.
  //
  // Distinct from is_black_owned, which arrived from the bulk import as a
  // blanket per-file constant and carries no real information. This one is
  // only ever set by firebase/scripts/apply_bob_certification.js against a
  // named certification body, with the source and its date alongside, so it
  // is the only ownership signal safe to surface to users.
  //
  // Read-only in the app: nothing here writes it, so it is deliberately
  // absent from createBusinessesRecordData.
  bool? _isCertifiedBlackOwned;
  bool get isCertifiedBlackOwned => _isCertifiedBlackOwned ?? false;
  bool hasIsCertifiedBlackOwned() => _isCertifiedBlackOwned != null;

  // "certification_source" field.
  String? _certificationSource;
  String get certificationSource => _certificationSource ?? '';
  bool hasCertificationSource() => _certificationSource != null;

  // "certification_as_of" field.
  //
  // The date of the *source list*, not of the import, so the staleness of a
  // certification travels with the record instead of looking freshly checked.
  String? _certificationAsOf;
  String get certificationAsOf => _certificationAsOf ?? '';
  bool hasCertificationAsOf() => _certificationAsOf != null;

  // "category" field.
  String? _category;
  String get category => _category ?? '';
  bool hasCategory() => _category != null;

  // "business_type" field.
  String? _businessType;
  String get businessType => _businessType ?? '';
  bool hasBusinessType() => _businessType != null;

  // "website" field.
  String? _website;
  String get website => _website ?? '';
  bool hasWebsite() => _website != null;

  // "ticker_symbol" field.
  String? _tickerSymbol;
  String get tickerSymbol => _tickerSymbol ?? '';
  bool hasTickerSymbol() => _tickerSymbol != null;

  // "hero_image" field.
  String? _heroImage;
  String get heroImage => _heroImage ?? '';
  bool hasHeroImage() => _heroImage != null;

  // "business_location" field.
  LatLng? _businessLocation;
  LatLng? get businessLocation => _businessLocation;
  bool hasBusinessLocation() => _businessLocation != null;

  // "address" field.
  String? _address;
  String get address => _address ?? '';
  bool hasAddress() => _address != null;

  // "tier_level" field.
  String? _tierLevel;
  String get tierLevel => _tierLevel ?? '';
  bool hasTierLevel() => _tierLevel != null;

  // "kindex_score" field.
  double? _kindexScore;
  double get kindexScore => _kindexScore ?? 0.0;
  bool hasKindexScore() => _kindexScore != null;

  // "description" field.
  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  // "phone_number" field.
  String? _phoneNumber;
  String get phoneNumber => _phoneNumber ?? '';
  bool hasPhoneNumber() => _phoneNumber != null;

  // "is_premium" field.
  bool? _isPremium;
  bool get isPremium => _isPremium ?? false;
  bool hasIsPremium() => _isPremium != null;

  // "city" field.
  String? _city;
  String get city => _city ?? '';
  bool hasCity() => _city != null;

  // "business_name" field.
  String? _businessName;
  String get businessName => _businessName ?? '';
  bool hasBusinessName() => _businessName != null;

  // "is_veteran" field.
  bool? _isVeteran;
  bool get isVeteran => _isVeteran ?? false;
  bool hasIsVeteran() => _isVeteran != null;

  // "is_ecommerce" field.
  bool? _isEcommerce;
  bool get isEcommerce => _isEcommerce ?? false;
  bool hasIsEcommerce() => _isEcommerce != null;

  // "zip_code_postcode" field.
  String? _zipCodePostcode;
  String get zipCodePostcode => _zipCodePostcode ?? '';
  bool hasZipCodePostcode() => _zipCodePostcode != null;

  // "email" field.
  String? _email;
  String get email => _email ?? '';
  bool hasEmail() => _email != null;

  // "owner_name" field.
  String? _ownerName;
  String get ownerName => _ownerName ?? '';
  bool hasOwnerName() => _ownerName != null;

  // "ar_asset_url" field.
  String? _arAssetUrl;
  String get arAssetUrl => _arAssetUrl ?? '';
  bool hasArAssetUrl() => _arAssetUrl != null;

  // "is_ar_enabled" field.
  bool? _isArEnabled;
  bool get isArEnabled => _isArEnabled ?? false;
  bool hasIsArEnabled() => _isArEnabled != null;

  // "subscription_tier" field.
  String? _subscriptionTier;
  String get subscriptionTier => _subscriptionTier ?? '';
  bool hasSubscriptionTier() => _subscriptionTier != null;

  // "rarity_tier" field. One of Standard/Rare/Hidden Gem. Missing/empty
  // reads as Standard - most businesses are never explicitly tagged.
  // Drives both The KIN Quest page's glow/diamond treatment and the
  // tighter check-in geofence for Rare/Hidden Gem spots (see
  // firebase/custom_cloud_functions/visit_verification.js).
  String? _rarityTier;
  String get rarityTier =>
      _rarityTier == null || _rarityTier!.isEmpty ? 'Standard' : _rarityTier!;
  bool hasRarityTier() => _rarityTier != null;

  // "points_multiplier" field. Quest-point award multiplier for a
  // verified check-in at this business - 1 for Standard, 3 for Rare, 5 for
  // Hidden Gem by convention (see visit_verification.js's
  // BASE_CHECKIN_POINTS), but stored per-business so an individual spot
  // can be tuned without a client release.
  double? _pointsMultiplier;
  double get pointsMultiplier => _pointsMultiplier ?? 1.0;
  bool hasPointsMultiplier() => _pointsMultiplier != null;

  // "active_hours_start" / "active_hours_end" fields. Minutes since
  // midnight, business-local time. For mobile spots (food trucks) that are
  // only physically present part of the day - null on either means "no
  // published window", which the check-in flow treats as always active,
  // same as every fixed storefront today.
  int? _activeHoursStart;
  int? get activeHoursStart => _activeHoursStart;
  bool hasActiveHoursStart() => _activeHoursStart != null;

  int? _activeHoursEnd;
  int? get activeHoursEnd => _activeHoursEnd;
  bool hasActiveHoursEnd() => _activeHoursEnd != null;

  // "trial_status" field. One of not_started/active/expired/converted.
  // Missing/empty reads as not_started - a business that has never
  // touched the trial flow. Set by startFoundingLocalTrial and the
  // processFoundingLocalTrials nightly sweep (see
  // firebase/custom_cloud_functions/founding_local_trial.js).
  String? _trialStatus;
  String get trialStatus => _trialStatus ?? '';
  bool hasTrialStatus() => _trialStatus != null;

  // "trial_start_at" field.
  DateTime? _trialStartAt;
  DateTime? get trialStartAt => _trialStartAt;
  bool hasTrialStartAt() => _trialStartAt != null;

  // "trial_end_at" field.
  DateTime? _trialEndAt;
  DateTime? get trialEndAt => _trialEndAt;
  bool hasTrialEndAt() => _trialEndAt != null;

  // "has_used_trial" field. Permanent once true - the one-trial-per-
  // -business guard. Never reset by unclaiming/reclaiming the business.
  bool? _hasUsedTrial;
  bool get hasUsedTrial => _hasUsedTrial ?? false;
  bool hasHasUsedTrial() => _hasUsedTrial != null;

  // "trial_reminder_stage" field. '' (or missing) / 'day10' / 'day13' -
  // which in-app trial reminder banner, if any, the owner profile should
  // currently show. Cleared back to '' on conversion or expiry.
  String? _trialReminderStage;
  String get trialReminderStage => _trialReminderStage ?? '';
  bool hasTrialReminderStage() => _trialReminderStage != null;

  // "has_flash_beacon" field.
  bool? _hasFlashBeacon;
  bool get hasFlashBeacon => _hasFlashBeacon ?? false;
  bool hasHasFlashBeacon() => _hasFlashBeacon != null;

  // "flash_beacon_expires_at" field. Read by the checkAndExpireBeacons
  // Cloud Function (firebase/custom_cloud_functions), which flips
  // has_flash_beacon back to false once this passes.
  DateTime? _flashBeaconExpiresAt;
  DateTime? get flashBeaconExpiresAt => _flashBeaconExpiresAt;
  bool hasFlashBeaconExpiresAt() => _flashBeaconExpiresAt != null;

  // "flash_beacon_duration_minutes" field.
  int? _flashBeaconDurationMinutes;
  int get flashBeaconDurationMinutes => _flashBeaconDurationMinutes ?? 0;
  bool hasFlashBeaconDurationMinutes() => _flashBeaconDurationMinutes != null;

  // "flash_beacon_message" field. The owner's own blast message for the
  // active Power Hour ('20% off all orders for the next hour'). Set by
  // startPowerHour, cleared alongside has_flash_beacon on expiry/early end.
  String? _flashBeaconMessage;
  String get flashBeaconMessage => _flashBeaconMessage ?? '';
  bool hasFlashBeaconMessage() => _flashBeaconMessage != null;

  // "flash_beacon_image_url" field. Optional flyer/promo image for the
  // active Power Hour, already uploaded to Storage by the time
  // startPowerHour is called.
  String? _flashBeaconImageUrl;
  String get flashBeaconImageUrl => _flashBeaconImageUrl ?? '';
  bool hasFlashBeaconImageUrl() => _flashBeaconImageUrl != null;

  // "power_hour_usage_count" field. Count of Power Hours started within
  // the current rolling 7-day window (see power_hour_last_reset).
  int? _powerHourUsageCount;
  int get powerHourUsageCount => _powerHourUsageCount ?? 0;
  bool hasPowerHourUsageCount() => _powerHourUsageCount != null;

  // "power_hour_last_reset" field. When the rolling 7-day usage window
  // last reset; power_hour_usage_count is treated as 0 once 7 days have
  // passed since this timestamp.
  DateTime? _powerHourLastReset;
  DateTime? get powerHourLastReset => _powerHourLastReset;
  bool hasPowerHourLastReset() => _powerHourLastReset != null;

  // "is_priority_pinned" field.
  bool? _isPriorityPinned;
  bool get isPriorityPinned => _isPriorityPinned ?? false;
  bool hasIsPriorityPinned() => _isPriorityPinned != null;

  // "loi_signed" field.
  bool? _loiSigned;
  bool get loiSigned => _loiSigned ?? false;
  bool hasLoiSigned() => _loiSigned != null;

  // "loi_date" field.
  DateTime? _loiDate;
  DateTime? get loiDate => _loiDate;
  bool hasLoiDate() => _loiDate != null;

  // "is_claimed" field.
  bool? _isClaimed;
  bool get isClaimed => _isClaimed ?? false;
  bool hasIsClaimed() => _isClaimed != null;

  // "claimed_by_user_id" field.
  String? _claimedByUserId;
  String get claimedByUserId => _claimedByUserId ?? '';
  bool hasClaimedByUserId() => _claimedByUserId != null;

  // "marketing_tier" field.
  String? _marketingTier;
  String get marketingTier => _marketingTier ?? '';
  bool hasMarketingTier() => _marketingTier != null;

  // "marketing_generations_used" field.
  int? _marketingGenerationsUsed;
  int get marketingGenerationsUsed => _marketingGenerationsUsed ?? 0;
  bool hasMarketingGenerationsUsed() => _marketingGenerationsUsed != null;

  // "scheduled_promo_date" field.
  DateTime? _scheduledPromoDate;
  DateTime? get scheduledPromoDate => _scheduledPromoDate;
  bool hasScheduledPromoDate() => _scheduledPromoDate != null;

  // "latitude" field.
  double? _latitude;
  double get latitude => _latitude ?? 0.0;
  bool hasLatitude() => _latitude != null;

  // "longitude" field.
  double? _longitude;
  double get longitude => _longitude ?? 0.0;
  bool hasLongitude() => _longitude != null;

  // "state" field.
  String? _state;
  String get state => _state ?? '';
  bool hasState() => _state != null;

  // "established_year" field.
  int? _establishedYear;
  int get establishedYear => _establishedYear ?? 0;
  bool hasEstablishedYear() => _establishedYear != null;

  // "review_score" field.
  double? _reviewScore;
  double get reviewScore => _reviewScore ?? 0.0;
  bool hasReviewScore() => _reviewScore != null;

  // "owner_ref" field.
  DocumentReference? _ownerRef;
  DocumentReference? get ownerRef => _ownerRef;
  bool hasOwnerRef() => _ownerRef != null;

  // "instagram_url" field.
  String? _instagramUrl;
  String get instagramUrl => _instagramUrl ?? '';
  bool hasInstagramUrl() => _instagramUrl != null;

  // "is_verified" field.
  bool? _isVerified;
  bool get isVerified => _isVerified ?? false;
  bool hasIsVerified() => _isVerified != null;

  // "facebook_url" field.
  String? _facebookUrl;
  String get facebookUrl => _facebookUrl ?? '';
  bool hasFacebookUrl() => _facebookUrl != null;

  // "tiktok_url" field.
  String? _tiktokUrl;
  String get tiktokUrl => _tiktokUrl ?? '';
  bool hasTiktokUrl() => _tiktokUrl != null;

  // "linkedin_url" field.
  String? _linkedinUrl;
  String get linkedinUrl => _linkedinUrl ?? '';
  bool hasLinkedinUrl() => _linkedinUrl != null;

  // "doordash_url" field.
  String? _doordashUrl;
  String get doordashUrl => _doordashUrl ?? '';
  bool hasDoordashUrl() => _doordashUrl != null;

  // "ubereats_url" field.
  String? _ubereatsUrl;
  String get ubereatsUrl => _ubereatsUrl ?? '';
  bool hasUbereatsUrl() => _ubereatsUrl != null;

  // "grubhub_url" field.
  String? _grubhubUrl;
  String get grubhubUrl => _grubhubUrl ?? '';
  bool hasGrubhubUrl() => _grubhubUrl != null;

  // "is_delivery_eligible" field.
  bool? _isDeliveryEligible;
  bool get isDeliveryEligible => _isDeliveryEligible ?? false;
  bool hasIsDeliveryEligible() => _isDeliveryEligible != null;

  // "kindex_velocity" field.
  int? _kindexVelocity;
  int get kindexVelocity => _kindexVelocity ?? 0;
  bool hasKindexVelocity() => _kindexVelocity != null;

  // "business_ref" field.
  DocumentReference? _businessRef;
  DocumentReference? get businessRef => _businessRef;
  bool hasBusinessRef() => _businessRef != null;

  // "review_count" field.
  int? _reviewCount;
  int get reviewCount => _reviewCount ?? 0;
  bool hasReviewCount() => _reviewCount != null;

  // "interaction_count" field.
  int? _interactionCount;
  int get interactionCount => _interactionCount ?? 0;
  bool hasInteractionCount() => _interactionCount != null;

  // "total_sentiment_score" field.
  double? _totalSentimentScore;
  double get totalSentimentScore => _totalSentimentScore ?? 0.0;
  bool hasTotalSentimentScore() => _totalSentimentScore != null;

  // "is_farmer" field.
  bool? _isFarmer;
  bool get isFarmer => _isFarmer ?? false;
  bool hasIsFarmer() => _isFarmer != null;

  // "is_wholesale" field.
  bool? _isWholesale;
  bool get isWholesale => _isWholesale ?? false;
  bool hasIsWholesale() => _isWholesale != null;

  // "is_retail" field.
  bool? _isRetail;
  bool get isRetail => _isRetail ?? false;
  bool hasIsRetail() => _isRetail != null;

  // "arc_asset_url" field.
  int? _arcAssetUrl;
  int get arcAssetUrl => _arcAssetUrl ?? 0;
  bool hasArcAssetUrl() => _arcAssetUrl != null;

  // "coordinates" field.
  LatLng? _coordinates;
  LatLng? get coordinates => _coordinates;
  bool hasCoordinates() => _coordinates != null;

  // "businesses_discovered_count" field. Incremented by the
  // submitBusinessDiscovery Cloud Function when this business's owner adds a
  // new listing to the directory; watched by generateMysteryReward for the
  // 5/15/30 milestone thresholds. Not written directly by the client.
  int? _businessesDiscoveredCount;
  int get businessesDiscoveredCount => _businessesDiscoveredCount ?? 0;
  bool hasBusinessesDiscoveredCount() => _businessesDiscoveredCount != null;

  // "monthly_promo_count" field.
  int? _monthlyPromoCount;
  int get monthlyPromoCount => _monthlyPromoCount ?? 0;
  bool hasMonthlyPromoCount() => _monthlyPromoCount != null;

  // "monthly_promo_reset_date" field.
  DateTime? _monthlyPromoResetDate;
  DateTime? get monthlyPromoResetDate => _monthlyPromoResetDate;
  bool hasMonthlyPromoResetDate() => _monthlyPromoResetDate != null;

  // "connection_count" field.
  int? _connectionCount;
  int get connectionCount => _connectionCount ?? 0;
  bool hasConnectionCount() => _connectionCount != null;

  // "opening_time" field.
  String? _openingTime;
  String get openingTime => _openingTime ?? '';
  bool hasOpeningTime() => _openingTime != null;

  // "closing_time" field.
  String? _closingTime;
  String get closingTime => _closingTime ?? '';
  bool hasClosingTime() => _closingTime != null;

  // "photo_gallery" field.
  List<String>? _photoGallery;
  List<String> get photoGallery => _photoGallery ?? const [];
  bool hasPhotoGallery() => _photoGallery != null;

  void _initializeFields() {
    _isBlackOwned = snapshotData['is_black_owned'] as bool?;
    _isCertifiedBlackOwned = snapshotData['is_certified_black_owned'] as bool?;
    _certificationSource = snapshotData['certification_source'] as String?;
    _certificationAsOf = snapshotData['certification_as_of'] as String?;
    _category = snapshotData['category'] as String?;
    _businessType = snapshotData['business_type'] as String?;
    _website = snapshotData['website'] as String?;
    _tickerSymbol = snapshotData['ticker_symbol'] as String?;
    _heroImage = snapshotData['hero_image'] as String?;
    _businessLocation = snapshotData['business_location'] as LatLng?;
    _address = snapshotData['address'] as String?;
    _tierLevel = snapshotData['tier_level'] as String?;
    _kindexScore = castToType<double>(snapshotData['kindex_score']);
    _description = snapshotData['description'] as String?;
    _phoneNumber = snapshotData['phone_number'] as String?;
    _isPremium = snapshotData['is_premium'] as bool?;
    _city = snapshotData['city'] as String?;
    _businessName = snapshotData['business_name'] as String?;
    _isVeteran = snapshotData['is_veteran'] as bool?;
    _isEcommerce = snapshotData['is_ecommerce'] as bool?;
    _zipCodePostcode = snapshotData['zip_code_postcode'] as String?;
    _email = snapshotData['email'] as String?;
    _ownerName = snapshotData['owner_name'] as String?;
    _arAssetUrl = snapshotData['ar_asset_url'] as String?;
    _isArEnabled = snapshotData['is_ar_enabled'] as bool?;
    _subscriptionTier = snapshotData['subscription_tier'] as String?;
    _rarityTier = snapshotData['rarity_tier'] as String?;
    _pointsMultiplier = castToType<double>(snapshotData['points_multiplier']);
    _activeHoursStart = castToType<int>(snapshotData['active_hours_start']);
    _activeHoursEnd = castToType<int>(snapshotData['active_hours_end']);
    _trialStatus = snapshotData['trial_status'] as String?;
    _trialStartAt = snapshotData['trial_start_at'] as DateTime?;
    _trialEndAt = snapshotData['trial_end_at'] as DateTime?;
    _hasUsedTrial = snapshotData['has_used_trial'] as bool?;
    _trialReminderStage = snapshotData['trial_reminder_stage'] as String?;
    _hasFlashBeacon = snapshotData['has_flash_beacon'] as bool?;
    _flashBeaconExpiresAt =
        snapshotData['flash_beacon_expires_at'] as DateTime?;
    _flashBeaconDurationMinutes =
        castToType<int>(snapshotData['flash_beacon_duration_minutes']);
    _flashBeaconMessage = snapshotData['flash_beacon_message'] as String?;
    _flashBeaconImageUrl = snapshotData['flash_beacon_image_url'] as String?;
    _powerHourUsageCount =
        castToType<int>(snapshotData['power_hour_usage_count']);
    _powerHourLastReset = snapshotData['power_hour_last_reset'] as DateTime?;
    _isPriorityPinned = snapshotData['is_priority_pinned'] as bool?;
    _loiSigned = snapshotData['loi_signed'] as bool?;
    _loiDate = snapshotData['loi_date'] as DateTime?;
    _isClaimed = snapshotData['is_claimed'] as bool?;
    _claimedByUserId = snapshotData['claimed_by_user_id'] as String?;
    _marketingTier = snapshotData['marketing_tier'] as String?;
    _marketingGenerationsUsed =
        castToType<int>(snapshotData['marketing_generations_used']);
    _scheduledPromoDate = snapshotData['scheduled_promo_date'] as DateTime?;
    _latitude = castToType<double>(snapshotData['latitude']);
    _longitude = castToType<double>(snapshotData['longitude']);
    _state = snapshotData['state'] as String?;
    _establishedYear = castToType<int>(snapshotData['established_year']);
    _reviewScore = castToType<double>(snapshotData['review_score']);
    _ownerRef = snapshotData['owner_ref'] as DocumentReference?;
    _instagramUrl = snapshotData['instagram_url'] as String?;
    _isVerified = snapshotData['is_verified'] as bool?;
    _facebookUrl = snapshotData['facebook_url'] as String?;
    _tiktokUrl = snapshotData['tiktok_url'] as String?;
    _linkedinUrl = snapshotData['linkedin_url'] as String?;
    _doordashUrl = snapshotData['doordash_url'] as String?;
    _ubereatsUrl = snapshotData['ubereats_url'] as String?;
    _grubhubUrl = snapshotData['grubhub_url'] as String?;
    _isDeliveryEligible = snapshotData['is_delivery_eligible'] as bool?;
    _kindexVelocity = castToType<int>(snapshotData['kindex_velocity']);
    _businessRef = snapshotData['business_ref'] as DocumentReference?;
    _reviewCount = castToType<int>(snapshotData['review_count']);
    _interactionCount = castToType<int>(snapshotData['interaction_count']);
    _totalSentimentScore =
        castToType<double>(snapshotData['total_sentiment_score']);
    _isFarmer = snapshotData['is_farmer'] as bool?;
    _isWholesale = snapshotData['is_wholesale'] as bool?;
    _isRetail = snapshotData['is_retail'] as bool?;
    _arcAssetUrl = castToType<int>(snapshotData['arc_asset_url']);
    _coordinates = snapshotData['coordinates'] as LatLng?;
    _businessesDiscoveredCount =
        castToType<int>(snapshotData['businesses_discovered_count']);
    _monthlyPromoCount = castToType<int>(snapshotData['monthly_promo_count']);
    _monthlyPromoResetDate =
        snapshotData['monthly_promo_reset_date'] as DateTime?;
    _connectionCount = castToType<int>(snapshotData['connection_count']);
    _openingTime = snapshotData['opening_time'] as String?;
    _closingTime = snapshotData['closing_time'] as String?;
    _photoGallery = getDataList(snapshotData['photo_gallery']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('businesses');

  static Stream<BusinessesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => BusinessesRecord.fromSnapshot(s));

  static Future<BusinessesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => BusinessesRecord.fromSnapshot(s));

  static BusinessesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      BusinessesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static BusinessesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      BusinessesRecord._(reference, mapFromFirestore(data));

  static BusinessesRecord fromAlgolia(AlgoliaObjectSnapshot snapshot) =>
      BusinessesRecord.getDocumentFromData(
        {
          'is_black_owned': snapshot.data['is_black_owned'],
          'category': snapshot.data['category'],
          'website': snapshot.data['website'],
          'ticker_symbol': snapshot.data['ticker_symbol'],
          'hero_image': snapshot.data['hero_image'],
          'business_location': convertAlgoliaParam(
            snapshot.data,
            ParamType.LatLng,
            false,
          ),
          'address': snapshot.data['address'],
          'tier_level': snapshot.data['tier_level'],
          'kindex_score': convertAlgoliaParam(
            snapshot.data['kindex_score'],
            ParamType.double,
            false,
          ),
          'description': snapshot.data['description'],
          'phone_number': snapshot.data['phone_number'],
          'is_premium': snapshot.data['is_premium'],
          'city': snapshot.data['city'],
          'business_name': snapshot.data['business_name'],
          'is_veteran': snapshot.data['is_veteran'],
          'is_ecommerce': snapshot.data['is_ecommerce'],
          'zip_code_postcode': snapshot.data['zip_code_postcode'],
          'email': snapshot.data['email'],
          'owner_name': snapshot.data['owner_name'],
          'ar_asset_url': snapshot.data['ar_asset_url'],
          'is_ar_enabled': snapshot.data['is_ar_enabled'],
          'subscription_tier': snapshot.data['subscription_tier'],
          'has_flash_beacon': snapshot.data['has_flash_beacon'],
          'is_priority_pinned': snapshot.data['is_priority_pinned'],
          'loi_signed': snapshot.data['loi_signed'],
          'loi_date': convertAlgoliaParam(
            snapshot.data['loi_date'],
            ParamType.DateTime,
            false,
          ),
          'is_claimed': snapshot.data['is_claimed'],
          'claimed_by_user_id': snapshot.data['claimed_by_user_id'],
          'marketing_tier': snapshot.data['marketing_tier'],
          'marketing_generations_used': convertAlgoliaParam(
            snapshot.data['marketing_generations_used'],
            ParamType.int,
            false,
          ),
          'scheduled_promo_date': convertAlgoliaParam(
            snapshot.data['scheduled_promo_date'],
            ParamType.DateTime,
            false,
          ),
          'latitude': convertAlgoliaParam(
            snapshot.data['latitude'],
            ParamType.double,
            false,
          ),
          'longitude': convertAlgoliaParam(
            snapshot.data['longitude'],
            ParamType.double,
            false,
          ),
          'state': snapshot.data['state'],
          'established_year': convertAlgoliaParam(
            snapshot.data['established_year'],
            ParamType.int,
            false,
          ),
          'review_score': convertAlgoliaParam(
            snapshot.data['review_score'],
            ParamType.double,
            false,
          ),
          'owner_ref': convertAlgoliaParam(
            snapshot.data['owner_ref'],
            ParamType.DocumentReference,
            false,
          ),
          'instagram_url': snapshot.data['instagram_url'],
          'is_verified': snapshot.data['is_verified'],
          'facebook_url': snapshot.data['facebook_url'],
          'tiktok_url': snapshot.data['tiktok_url'],
          'linkedin_url': snapshot.data['linkedin_url'],
          'doordash_url': snapshot.data['doordash_url'],
          'ubereats_url': snapshot.data['ubereats_url'],
          'grubhub_url': snapshot.data['grubhub_url'],
          'is_delivery_eligible': snapshot.data['is_delivery_eligible'],
          'kindex_velocity': convertAlgoliaParam(
            snapshot.data['kindex_velocity'],
            ParamType.int,
            false,
          ),
          'business_ref': convertAlgoliaParam(
            snapshot.data['business_ref'],
            ParamType.DocumentReference,
            false,
          ),
          'review_count': convertAlgoliaParam(
            snapshot.data['review_count'],
            ParamType.int,
            false,
          ),
          'interaction_count': convertAlgoliaParam(
            snapshot.data['interaction_count'],
            ParamType.int,
            false,
          ),
          'total_sentiment_score': convertAlgoliaParam(
            snapshot.data['total_sentiment_score'],
            ParamType.double,
            false,
          ),
          'is_farmer': snapshot.data['is_farmer'],
          'is_wholesale': snapshot.data['is_wholesale'],
          'is_retail': snapshot.data['is_retail'],
          'arc_asset_url': convertAlgoliaParam(
            snapshot.data['arc_asset_url'],
            ParamType.int,
            false,
          ),
          'coordinates': convertAlgoliaParam(
            snapshot.data,
            ParamType.LatLng,
            false,
          ),
          'monthly_promo_count': convertAlgoliaParam(
            snapshot.data['monthly_promo_count'],
            ParamType.int,
            false,
          ),
          'monthly_promo_reset_date': convertAlgoliaParam(
            snapshot.data['monthly_promo_reset_date'],
            ParamType.DateTime,
            false,
          ),
          'connection_count': convertAlgoliaParam(
            snapshot.data['connection_count'],
            ParamType.int,
            false,
          ),
          'opening_time': snapshot.data['opening_time'],
          'closing_time': snapshot.data['closing_time'],
          'photo_gallery': safeGet(
            () => snapshot.data['photo_gallery'].toList(),
          ),
        },
        BusinessesRecord.collection.doc(snapshot.objectID),
      );

  static Future<List<BusinessesRecord>> search({
    String? term,
    FutureOr<LatLng>? location,
    int? maxResults,
    double? searchRadiusMeters,
    bool useCache = false,
  }) =>
      FFAlgoliaManager.instance
          .algoliaQuery(
            index: 'businesses',
            term: term,
            maxResults: maxResults,
            location: location,
            searchRadiusMeters: searchRadiusMeters,
            useCache: useCache,
          )
          .then((r) => r.map(fromAlgolia).toList());

  @override
  String toString() =>
      'BusinessesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is BusinessesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createBusinessesRecordData({
  bool? isBlackOwned,
  String? category,
  String? businessType,
  String? website,
  String? tickerSymbol,
  String? heroImage,
  LatLng? businessLocation,
  String? address,
  String? tierLevel,
  double? kindexScore,
  String? description,
  String? phoneNumber,
  bool? isPremium,
  String? city,
  String? businessName,
  bool? isVeteran,
  bool? isEcommerce,
  String? zipCodePostcode,
  String? email,
  String? ownerName,
  String? arAssetUrl,
  bool? isArEnabled,
  String? subscriptionTier,
  String? rarityTier,
  double? pointsMultiplier,
  int? activeHoursStart,
  int? activeHoursEnd,
  String? trialStatus,
  DateTime? trialStartAt,
  DateTime? trialEndAt,
  bool? hasUsedTrial,
  String? trialReminderStage,
  bool? hasFlashBeacon,
  DateTime? flashBeaconExpiresAt,
  int? flashBeaconDurationMinutes,
  String? flashBeaconMessage,
  String? flashBeaconImageUrl,
  int? powerHourUsageCount,
  DateTime? powerHourLastReset,
  bool? isPriorityPinned,
  bool? loiSigned,
  DateTime? loiDate,
  bool? isClaimed,
  String? claimedByUserId,
  String? marketingTier,
  int? marketingGenerationsUsed,
  DateTime? scheduledPromoDate,
  double? latitude,
  double? longitude,
  String? state,
  int? establishedYear,
  double? reviewScore,
  DocumentReference? ownerRef,
  String? instagramUrl,
  bool? isVerified,
  String? facebookUrl,
  String? tiktokUrl,
  String? linkedinUrl,
  String? doordashUrl,
  String? ubereatsUrl,
  String? grubhubUrl,
  bool? isDeliveryEligible,
  int? kindexVelocity,
  DocumentReference? businessRef,
  int? reviewCount,
  int? interactionCount,
  double? totalSentimentScore,
  bool? isFarmer,
  bool? isWholesale,
  bool? isRetail,
  int? arcAssetUrl,
  LatLng? coordinates,
  int? businessesDiscoveredCount,
  int? monthlyPromoCount,
  DateTime? monthlyPromoResetDate,
  int? connectionCount,
  String? openingTime,
  String? closingTime,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'is_black_owned': isBlackOwned,
      'category': category,
      'business_type': businessType,
      'website': website,
      'ticker_symbol': tickerSymbol,
      'hero_image': heroImage,
      'business_location': businessLocation,
      'address': address,
      'tier_level': tierLevel,
      'kindex_score': kindexScore,
      'description': description,
      'phone_number': phoneNumber,
      'is_premium': isPremium,
      'city': city,
      'business_name': businessName,
      'is_veteran': isVeteran,
      'is_ecommerce': isEcommerce,
      'zip_code_postcode': zipCodePostcode,
      'email': email,
      'owner_name': ownerName,
      'ar_asset_url': arAssetUrl,
      'is_ar_enabled': isArEnabled,
      'subscription_tier': subscriptionTier,
      'rarity_tier': rarityTier,
      'points_multiplier': pointsMultiplier,
      'active_hours_start': activeHoursStart,
      'active_hours_end': activeHoursEnd,
      'trial_status': trialStatus,
      'trial_start_at': trialStartAt,
      'trial_end_at': trialEndAt,
      'has_used_trial': hasUsedTrial,
      'trial_reminder_stage': trialReminderStage,
      'has_flash_beacon': hasFlashBeacon,
      'flash_beacon_expires_at': flashBeaconExpiresAt,
      'flash_beacon_duration_minutes': flashBeaconDurationMinutes,
      'flash_beacon_message': flashBeaconMessage,
      'flash_beacon_image_url': flashBeaconImageUrl,
      'power_hour_usage_count': powerHourUsageCount,
      'power_hour_last_reset': powerHourLastReset,
      'is_priority_pinned': isPriorityPinned,
      'loi_signed': loiSigned,
      'loi_date': loiDate,
      'is_claimed': isClaimed,
      'claimed_by_user_id': claimedByUserId,
      'marketing_tier': marketingTier,
      'marketing_generations_used': marketingGenerationsUsed,
      'scheduled_promo_date': scheduledPromoDate,
      'latitude': latitude,
      'longitude': longitude,
      'state': state,
      'established_year': establishedYear,
      'review_score': reviewScore,
      'owner_ref': ownerRef,
      'instagram_url': instagramUrl,
      'is_verified': isVerified,
      'facebook_url': facebookUrl,
      'tiktok_url': tiktokUrl,
      'linkedin_url': linkedinUrl,
      'doordash_url': doordashUrl,
      'ubereats_url': ubereatsUrl,
      'grubhub_url': grubhubUrl,
      'is_delivery_eligible': isDeliveryEligible,
      'kindex_velocity': kindexVelocity,
      'business_ref': businessRef,
      'review_count': reviewCount,
      'interaction_count': interactionCount,
      'total_sentiment_score': totalSentimentScore,
      'is_farmer': isFarmer,
      'is_wholesale': isWholesale,
      'is_retail': isRetail,
      'arc_asset_url': arcAssetUrl,
      'coordinates': coordinates,
      'businesses_discovered_count': businessesDiscoveredCount,
      'monthly_promo_count': monthlyPromoCount,
      'monthly_promo_reset_date': monthlyPromoResetDate,
      'connection_count': connectionCount,
      'opening_time': openingTime,
      'closing_time': closingTime,
    }.withoutNulls,
  );

  return firestoreData;
}

class BusinessesRecordDocumentEquality implements Equality<BusinessesRecord> {
  const BusinessesRecordDocumentEquality();

  @override
  bool equals(BusinessesRecord? e1, BusinessesRecord? e2) {
    const listEquality = ListEquality();
    return e1?.isBlackOwned == e2?.isBlackOwned &&
        e1?.category == e2?.category &&
        e1?.businessType == e2?.businessType &&
        e1?.website == e2?.website &&
        e1?.tickerSymbol == e2?.tickerSymbol &&
        e1?.heroImage == e2?.heroImage &&
        e1?.businessLocation == e2?.businessLocation &&
        e1?.address == e2?.address &&
        e1?.tierLevel == e2?.tierLevel &&
        e1?.kindexScore == e2?.kindexScore &&
        e1?.description == e2?.description &&
        e1?.phoneNumber == e2?.phoneNumber &&
        e1?.isPremium == e2?.isPremium &&
        e1?.city == e2?.city &&
        e1?.businessName == e2?.businessName &&
        e1?.isVeteran == e2?.isVeteran &&
        e1?.isEcommerce == e2?.isEcommerce &&
        e1?.zipCodePostcode == e2?.zipCodePostcode &&
        e1?.email == e2?.email &&
        e1?.ownerName == e2?.ownerName &&
        e1?.arAssetUrl == e2?.arAssetUrl &&
        e1?.isArEnabled == e2?.isArEnabled &&
        e1?.subscriptionTier == e2?.subscriptionTier &&
        e1?.rarityTier == e2?.rarityTier &&
        e1?.pointsMultiplier == e2?.pointsMultiplier &&
        e1?.activeHoursStart == e2?.activeHoursStart &&
        e1?.activeHoursEnd == e2?.activeHoursEnd &&
        e1?.trialStatus == e2?.trialStatus &&
        e1?.trialStartAt == e2?.trialStartAt &&
        e1?.trialEndAt == e2?.trialEndAt &&
        e1?.hasUsedTrial == e2?.hasUsedTrial &&
        e1?.trialReminderStage == e2?.trialReminderStage &&
        e1?.hasFlashBeacon == e2?.hasFlashBeacon &&
        e1?.flashBeaconExpiresAt == e2?.flashBeaconExpiresAt &&
        e1?.flashBeaconDurationMinutes == e2?.flashBeaconDurationMinutes &&
        e1?.flashBeaconMessage == e2?.flashBeaconMessage &&
        e1?.flashBeaconImageUrl == e2?.flashBeaconImageUrl &&
        e1?.powerHourUsageCount == e2?.powerHourUsageCount &&
        e1?.powerHourLastReset == e2?.powerHourLastReset &&
        e1?.isPriorityPinned == e2?.isPriorityPinned &&
        e1?.loiSigned == e2?.loiSigned &&
        e1?.loiDate == e2?.loiDate &&
        e1?.isClaimed == e2?.isClaimed &&
        e1?.claimedByUserId == e2?.claimedByUserId &&
        e1?.marketingTier == e2?.marketingTier &&
        e1?.marketingGenerationsUsed == e2?.marketingGenerationsUsed &&
        e1?.scheduledPromoDate == e2?.scheduledPromoDate &&
        e1?.latitude == e2?.latitude &&
        e1?.longitude == e2?.longitude &&
        e1?.state == e2?.state &&
        e1?.establishedYear == e2?.establishedYear &&
        e1?.reviewScore == e2?.reviewScore &&
        e1?.ownerRef == e2?.ownerRef &&
        e1?.instagramUrl == e2?.instagramUrl &&
        e1?.isVerified == e2?.isVerified &&
        e1?.facebookUrl == e2?.facebookUrl &&
        e1?.tiktokUrl == e2?.tiktokUrl &&
        e1?.linkedinUrl == e2?.linkedinUrl &&
        e1?.doordashUrl == e2?.doordashUrl &&
        e1?.ubereatsUrl == e2?.ubereatsUrl &&
        e1?.grubhubUrl == e2?.grubhubUrl &&
        e1?.isDeliveryEligible == e2?.isDeliveryEligible &&
        e1?.kindexVelocity == e2?.kindexVelocity &&
        e1?.businessRef == e2?.businessRef &&
        e1?.reviewCount == e2?.reviewCount &&
        e1?.interactionCount == e2?.interactionCount &&
        e1?.totalSentimentScore == e2?.totalSentimentScore &&
        e1?.isFarmer == e2?.isFarmer &&
        e1?.isWholesale == e2?.isWholesale &&
        e1?.isRetail == e2?.isRetail &&
        e1?.arcAssetUrl == e2?.arcAssetUrl &&
        e1?.coordinates == e2?.coordinates &&
        e1?.businessesDiscoveredCount == e2?.businessesDiscoveredCount &&
        e1?.monthlyPromoCount == e2?.monthlyPromoCount &&
        e1?.monthlyPromoResetDate == e2?.monthlyPromoResetDate &&
        e1?.connectionCount == e2?.connectionCount &&
        e1?.openingTime == e2?.openingTime &&
        e1?.closingTime == e2?.closingTime &&
        listEquality.equals(e1?.photoGallery, e2?.photoGallery);
  }

  @override
  int hash(BusinessesRecord? e) => const ListEquality().hash([
        e?.isBlackOwned,
        e?.category,
        e?.businessType,
        e?.website,
        e?.tickerSymbol,
        e?.heroImage,
        e?.businessLocation,
        e?.address,
        e?.tierLevel,
        e?.kindexScore,
        e?.description,
        e?.phoneNumber,
        e?.isPremium,
        e?.city,
        e?.businessName,
        e?.isVeteran,
        e?.isEcommerce,
        e?.zipCodePostcode,
        e?.email,
        e?.ownerName,
        e?.arAssetUrl,
        e?.isArEnabled,
        e?.subscriptionTier,
        e?.rarityTier,
        e?.pointsMultiplier,
        e?.activeHoursStart,
        e?.activeHoursEnd,
        e?.trialStatus,
        e?.trialStartAt,
        e?.trialEndAt,
        e?.hasUsedTrial,
        e?.trialReminderStage,
        e?.hasFlashBeacon,
        e?.flashBeaconExpiresAt,
        e?.flashBeaconDurationMinutes,
        e?.flashBeaconMessage,
        e?.flashBeaconImageUrl,
        e?.powerHourUsageCount,
        e?.powerHourLastReset,
        e?.isPriorityPinned,
        e?.loiSigned,
        e?.loiDate,
        e?.isClaimed,
        e?.claimedByUserId,
        e?.marketingTier,
        e?.marketingGenerationsUsed,
        e?.scheduledPromoDate,
        e?.latitude,
        e?.longitude,
        e?.state,
        e?.establishedYear,
        e?.reviewScore,
        e?.ownerRef,
        e?.instagramUrl,
        e?.isVerified,
        e?.facebookUrl,
        e?.tiktokUrl,
        e?.linkedinUrl,
        e?.doordashUrl,
        e?.ubereatsUrl,
        e?.grubhubUrl,
        e?.isDeliveryEligible,
        e?.kindexVelocity,
        e?.businessRef,
        e?.reviewCount,
        e?.interactionCount,
        e?.totalSentimentScore,
        e?.isFarmer,
        e?.isWholesale,
        e?.isRetail,
        e?.arcAssetUrl,
        e?.coordinates,
        e?.businessesDiscoveredCount,
        e?.monthlyPromoCount,
        e?.monthlyPromoResetDate,
        e?.connectionCount,
        e?.openingTime,
        e?.closingTime,
        e?.photoGallery
      ]);

  @override
  bool isValidKey(Object? o) => o is BusinessesRecord;
}
