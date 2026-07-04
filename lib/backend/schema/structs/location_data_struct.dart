// ignore_for_file: unnecessary_getters_setters
import '/backend/algolia/serialization_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class LocationDataStruct extends FFFirebaseStruct {
  LocationDataStruct({
    double? lat,
    double? lng,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _lat = lat,
        _lng = lng,
        super(firestoreUtilData);

  // "lat" field.
  double? _lat;
  double get lat => _lat ?? 0.0;
  set lat(double? val) => _lat = val;

  void incrementLat(double amount) => lat = lat + amount;

  bool hasLat() => _lat != null;

  // "lng" field.
  double? _lng;
  double get lng => _lng ?? 0.0;
  set lng(double? val) => _lng = val;

  void incrementLng(double amount) => lng = lng + amount;

  bool hasLng() => _lng != null;

  static LocationDataStruct fromMap(Map<String, dynamic> data) =>
      LocationDataStruct(
        lat: castToType<double>(data['lat']),
        lng: castToType<double>(data['lng']),
      );

  static LocationDataStruct? maybeFromMap(dynamic data) => data is Map
      ? LocationDataStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'lat': _lat,
        'lng': _lng,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'lat': serializeParam(
          _lat,
          ParamType.double,
        ),
        'lng': serializeParam(
          _lng,
          ParamType.double,
        ),
      }.withoutNulls;

  static LocationDataStruct fromSerializableMap(Map<String, dynamic> data) =>
      LocationDataStruct(
        lat: deserializeParam(
          data['lat'],
          ParamType.double,
          false,
        ),
        lng: deserializeParam(
          data['lng'],
          ParamType.double,
          false,
        ),
      );

  static LocationDataStruct fromAlgoliaData(Map<String, dynamic> data) =>
      LocationDataStruct(
        lat: convertAlgoliaParam(
          data['lat'],
          ParamType.double,
          false,
        ),
        lng: convertAlgoliaParam(
          data['lng'],
          ParamType.double,
          false,
        ),
        firestoreUtilData: FirestoreUtilData(
          clearUnsetFields: false,
          create: true,
        ),
      );

  @override
  String toString() => 'LocationDataStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is LocationDataStruct && lat == other.lat && lng == other.lng;
  }

  @override
  int get hashCode => const ListEquality().hash([lat, lng]);
}

LocationDataStruct createLocationDataStruct({
  double? lat,
  double? lng,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    LocationDataStruct(
      lat: lat,
      lng: lng,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

LocationDataStruct? updateLocationDataStruct(
  LocationDataStruct? locationData, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    locationData
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addLocationDataStructData(
  Map<String, dynamic> firestoreData,
  LocationDataStruct? locationData,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (locationData == null) {
    return;
  }
  if (locationData.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && locationData.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final locationDataData =
      getLocationDataFirestoreData(locationData, forFieldValue);
  final nestedData =
      locationDataData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = locationData.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getLocationDataFirestoreData(
  LocationDataStruct? locationData, [
  bool forFieldValue = false,
]) {
  if (locationData == null) {
    return {};
  }
  final firestoreData = mapToFirestore(locationData.toMap());

  // Add any Firestore field values
  mapToFirestore(locationData.firestoreUtilData.fieldValues)
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getLocationDataListFirestoreData(
  List<LocationDataStruct>? locationDatas,
) =>
    locationDatas?.map((e) => getLocationDataFirestoreData(e, true)).toList() ??
    [];
