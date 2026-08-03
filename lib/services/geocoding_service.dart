import 'dart:convert';
import 'package:http/http.dart' as http;
import '/flutter_flow/lat_lng.dart';

/// Resolves a typed street address to coordinates via Google's Geocoding
/// API, as a fallback when the caller didn't pick a suggestion from
/// FlutterFlowPlacePicker.
///
/// The "Add a Business" flow only published instantly (or queued with
/// coordinates a reviewer could approve) when the place picker's dropdown
/// was tapped - typing an address and moving on, which reads as the more
/// natural way to fill in a text field, silently left business_location
/// null. For an admin that meant "the business never actually appears
/// anywhere"; for anyone else it meant an unapprovable queue entry, since
/// resolveBusinessSubmissionReview refuses to publish a submission with no
/// coordinates. This is the same Places platform behind the picker, just
/// invoked directly on the address string that's already been typed,
/// so neither case depends on a specific UI gesture succeeding.
class GeocodingService {
  // Same key already used by FlutterFlowPlacePicker in this flow (see
  // add_business_discovery_dialog.dart) - not a new credential, just a
  // second caller of it.
  static const _apiKey = 'AIzaSyD1w4m7IaWva5Bxl9fsbsZgILC7R8wf_Go';

  /// The first geocoded result for [address], or null if it's empty,
  /// unresolvable, or the request fails for any reason - callers treat a
  /// null the same as "no coordinates available" and fall back to
  /// whatever they did before this existed.
  static Future<LatLng?> geocodeAddress(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return null;

    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        'address': trimmed,
        'key': _apiKey,
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['status'] != 'OK') return null;

      final results = body['results'] as List?;
      if (results == null || results.isEmpty) return null;

      final location =
          (results.first as Map<String, dynamic>)['geometry']['location']
              as Map<String, dynamic>;
      final lat = (location['lat'] as num?)?.toDouble();
      final lng = (location['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;

      return LatLng(lat, lng);
    } catch (_) {
      return null;
    }
  }
}
