import '/backend/backend.dart';
import '/data/google_places_service.dart';
import '/models/kin_business_profile.dart';

/// Unified entry point for map and directory business data.
class KinBusinessFeed {
  KinBusinessFeed._();

  static Stream<List<KinBusinessProfile>> watchProfiles() =>
      queryBusinessesRecord().map(KinBusinessDataMapper.fromFirestoreList);

  static List<KinBusinessProfile> profilesFromRecords(
    List<BusinessesRecord> records,
  ) =>
      KinBusinessDataMapper.fromFirestoreList(records);

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
          : profile.withPreservedGrowthMetrics(prior.growthMetrics);
    }

    return merged.values.toList()
      ..sort((a, b) => b.kindexScore.compareTo(a.kindexScore));
  }

  static Future<List<KinBusinessProfile>> loadExternalFeed(
    List<Map<String, dynamic>> payload,
  ) async =>
      KinBusinessDataMapper.fromExternalFeedList(payload);

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
