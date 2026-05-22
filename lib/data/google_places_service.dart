import 'dart:convert';

import '/backend/api_requests/api_manager.dart';
import '/core/env/kin_env_config.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/models/kin_business_profile.dart';

class GooglePlacesException implements Exception {
  GooglePlacesException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'GooglePlacesException($message, statusCode: $statusCode)';
}

/// Parsed subset of a Google Places Text Search result.
class GooglePlacesLookupResult {
  const GooglePlacesLookupResult({
    required this.placeId,
    required this.displayName,
    required this.formattedAddress,
    required this.rating,
    required this.userRatingCount,
    required this.photoUrls,
    required this.location,
    required this.category,
  });

  final String placeId;
  final String displayName;
  final String formattedAddress;
  final double rating;
  final int userRatingCount;
  final List<String> photoUrls;
  final LatLng? location;
  final String category;

  Map<String, dynamic> toExternalFeedMap({
    required String city,
    String state = '',
  }) {
    return {
      'id': placeId,
      'placeID': placeId,
      'business_name': displayName,
      'name': displayName,
      'address': formattedAddress,
      'city': city,
      'state': state,
      'hero_image': photoUrls.isNotEmpty ? photoUrls.first : null,
      'gallery_images': photoUrls,
      'latitude': location?.latitude,
      'longitude': location?.longitude,
      'category': category,
      'rating': rating,
      'user_rating_count': userRatingCount,
      'reviews': userRatingCount > 0
          ? [
              {
                'author_name': 'Google Places',
                'rating': rating,
                'body':
                    'Aggregated rating from $userRatingCount Google reviews.',
              },
            ]
          : [],
      'is_black_owned': true,
      'source': 'google_places_text_search',
    };
  }
}

/// Live Google Places Text Search integration for [KinBusinessProfile].
class GooglePlacesService {
  GooglePlacesService._();

  static const _textSearchUrl = 'https://places.googleapis.com/v1/places:searchText';
  static final _fieldMask = [
    'places.id',
    'places.displayName',
    'places.formattedAddress',
    'places.rating',
    'places.userRatingCount',
    'places.photos',
    'places.location',
    'places.primaryType',
    'places.types',
  ].join(',');

  /// Searches Google Places by business name + city and returns the top match.
  static Future<GooglePlacesLookupResult?> searchBusinessByNameAndCity({
    required String businessName,
    required String city,
    String? apiKey,
  }) async {
    final trimmedName = businessName.trim();
    final trimmedCity = city.trim();
    if (trimmedName.isEmpty || trimmedCity.isEmpty) {
      throw GooglePlacesException('Business name and city are required.');
    }

    final resolvedApiKey = apiKey ?? KinEnvConfig.requireGooglePlacesApiKey();
    final textQuery = '$trimmedName in $trimmedCity';

    final response = await ApiManager.instance.makeApiCall(
      callName: 'googlePlacesTextSearch',
      apiUrl: _textSearchUrl,
      callType: ApiCallType.POST,
      headers: {
        'X-Goog-Api-Key': resolvedApiKey,
        'X-Goog-FieldMask': _fieldMask,
        'Content-Type': 'application/json',
      },
      params: const {},
      body: jsonEncode({'textQuery': textQuery}),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: true,
    );

    if (!response.succeeded) {
      throw GooglePlacesException(
        _readErrorMessage(response.jsonBody) ??
            'Google Places Text Search failed.',
        statusCode: response.statusCode,
      );
    }

    return _parseTopPlace(
      response.jsonBody,
      apiKey: resolvedApiKey,
    );
  }

  /// Convenience helper that returns a populated [KinBusinessProfile].
  static Future<KinBusinessProfile?> fetchProfileForBusiness({
    required String businessName,
    required String city,
    String? apiKey,
    String state = '',
  }) async {
    final lookup = await searchBusinessByNameAndCity(
      businessName: businessName,
      city: city,
      apiKey: apiKey,
    );

    if (lookup == null) {
      return null;
    }

    return KinBusinessProfile.fromExternalFeed(
      lookup.toExternalFeedMap(city: city, state: state),
    );
  }

  static GooglePlacesLookupResult? _parseTopPlace(
    dynamic jsonBody, {
    required String apiKey,
  }) {
    if (jsonBody is! Map<String, dynamic>) {
      return null;
    }

    final places = jsonBody['places'];
    if (places is! List || places.isEmpty) {
      return null;
    }

    final place = places.first;
    if (place is! Map<String, dynamic>) {
      return null;
    }

    final placeId = _readString(place['id']) ?? _readString(place['name']) ?? '';
    if (placeId.isEmpty) {
      return null;
    }

    return GooglePlacesLookupResult(
      placeId: placeId,
      displayName: _readDisplayName(place['displayName']),
      formattedAddress: _readString(place['formattedAddress']) ?? '',
      rating: _readDouble(place['rating']) ?? 0.0,
      userRatingCount: _readInt(place['userRatingCount']) ?? 0,
      photoUrls: _buildPhotoUrls(place['photos'], apiKey),
      location: _readLocation(place['location']),
      category: _readCategory(place),
    );
  }

  static String? _readErrorMessage(dynamic jsonBody) {
    if (jsonBody is! Map<String, dynamic>) {
      return null;
    }

    final error = jsonBody['error'];
    if (error is Map<String, dynamic>) {
      return _readString(error['message']) ?? _readString(error['status']);
    }

    return _readString(jsonBody['message']);
  }

  static String _readDisplayName(dynamic value) {
    if (value is Map<String, dynamic>) {
      return _readString(value['text']) ?? '';
    }
    return _readString(value) ?? '';
  }

  static LatLng? _readLocation(dynamic value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }

    final latitude = _readDouble(value['latitude']);
    final longitude = _readDouble(value['longitude']);
    if (latitude == null || longitude == null) {
      return null;
    }

    return LatLng(latitude, longitude);
  }

  static String _readCategory(Map<String, dynamic> place) {
    final primaryType = _readString(place['primaryType']);
    if (primaryType != null && primaryType.isNotEmpty) {
      return _humanizePlaceType(primaryType);
    }

    final types = place['types'];
    if (types is List && types.isNotEmpty) {
      final firstType = types.first;
      if (firstType is String && firstType.isNotEmpty) {
        return _humanizePlaceType(firstType);
      }
    }

    return '';
  }

  static List<String> _buildPhotoUrls(dynamic photos, String apiKey) {
    if (photos is! List) {
      return const [];
    }

    return photos
        .whereType<Map>()
        .map((photo) => _readString(photo['name']))
        .whereType<String>()
        .map(
          (photoName) => Uri.parse(
            'https://places.googleapis.com/v1/$photoName/media',
          ).replace(
            queryParameters: {
              'maxHeightPx': '800',
              'maxWidthPx': '800',
              'key': apiKey,
            },
          ).toString(),
        )
        .toList();
  }

  static String _humanizePlaceType(String rawType) {
    return rawType
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  static String? _readString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  static double? _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static int? _readInt(dynamic value) {
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
}
