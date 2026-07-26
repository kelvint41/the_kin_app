import 'dart:convert';
import '../cloud_functions/cloud_functions.dart';

import 'package:flutter/foundation.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';

class GetBusinessDetailsCall {
  static Future<ApiCallResponse> call({
    String? placeId = '',
  }) async {
    final response = await makeCloudCall(
      _kPrivateApiFunctionName,
      {
        'callName': 'GetBusinessDetailsCall',
        'variables': {
          'placeId': placeId,
        },
      },
    );
    return ApiCallResponse.fromCloudCallResponse(response);
  }

  static String? businessname(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.result.name''',
      ));
  static String? address(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.result.formatted_address''',
      ));
  static String? phonenumber(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.result.formatted_phone_number''',
      ));
  static String? website(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.result.website''',
      ));
  static double? rating(dynamic response) => castToType<double>(getJsonField(
        response,
        r'''$.result.rating''',
      ));
  static int? totalreviews(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.result.user_ratings_total''',
      ));
}

class GooglePlacesAutocompleteCall {
  static Future<ApiCallResponse> call({
    String? searchQuery = '',
  }) async {
    final response = await makeCloudCall(
      _kPrivateApiFunctionName,
      {
        'callName': 'GooglePlacesAutocompleteCall',
        'variables': {
          'searchQuery': searchQuery,
        },
      },
    );
    return ApiCallResponse.fromCloudCallResponse(response);
  }
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  if (item is DocumentReference) {
    return item.path;
  }
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
}
