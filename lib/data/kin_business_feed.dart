import '/backend/backend.dart';
import '/data/google_places_service.dart';
import '/models/kin_business_profile.dart';

/// Unified entry point for map and directory business data.
class KinBusinessFeed {
  KinBusinessFeed._();

  static Stream<List<KinBusinessProfile>> watchProfiles() =>
      queryBusinessesRecord()
          .map(KinBusinessDataMapper.fromFirestoreList)
          .map(sortProfiles);

  static List<KinBusinessProfile> profilesFromRecords(
    List<BusinessesRecord> records,
  ) =>
      sortProfiles(KinBusinessDataMapper.fromFirestoreList(records));

  /// Featured businesses first, then highest Kindex score.
  static int compareProfiles(KinBusinessProfile a, KinBusinessProfile b) {
    if (a.isFeatured != b.isFeatured) {
      return a.isFeatured ? -1 : 1;
    }

    return b.kindexScore.compareTo(a.kindexScore);
  }

  static List<KinBusinessProfile> sortProfiles(
    List<KinBusinessProfile> profiles,
  ) =>
      profiles.toList()..sort(compareProfiles);

  /// Merge Firestore profiles with an external partner/API payload.
  static List<KinBusinessProfile> mergeProfiles({
    required List<KinBusinessProfile> firestoreProfiles,
    required List<Map<String, dynamic>> externalPayload,
  }) {
    final merged = <String, KinBusinessProfile>{
      for (final profile in firestoreProfiles) profile.id: profile,
    };

    for (final item in externalPayload) {
      final profile = KinBusinessDataMapper.fromExternalFeed(item);
      final prior = merged[profile.id];
      merged[profile.id] = prior == null
          ? profile
          : profile.withPreservedFirestoreMetadata(prior);
    }

    return sortProfiles(merged.values.toList());
  }

  static Future<List<KinBusinessProfile>> loadExternalFeed(
    List<Map<String, dynamic>> payload,
  ) async =>
      sortProfiles(KinBusinessDataMapper.fromExternalFeedList(payload));

  /// Live Google Places lookup for a single Black-owned business profile.
  static Future<KinBusinessProfile?> loadProfileFromGooglePlaces({
    required String businessName,
    required String city,
    String state = '',
    String? apiKey,
  }) =>
      GooglePlacesService.fetchProfileForBusiness(
        businessName: businessName,
        city: city,
        state: state,
        apiKey: apiKey,
      );

  /// Raw Google Places payload (rating, review count, address, photo URLs).
  static Future<GooglePlacesLookupResult?> lookupBusinessOnGooglePlaces({
    required String businessName,
    required String city,
    String? apiKey,
  }) =>
      GooglePlacesService.searchBusinessByNameAndCity(
        businessName: businessName,
        city: city,
        apiKey: apiKey,
      );
}
