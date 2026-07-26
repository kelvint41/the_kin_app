// ignore_for_file: unnecessary_getters_setters
import '/backend/algolia/serialization_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class BusinessMetricStruct extends FFFirebaseStruct {
  BusinessMetricStruct({
    DocumentReference? businessRef,
    int? viewCount,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _businessRef = businessRef,
        _viewCount = viewCount,
        super(firestoreUtilData);

  // "business_ref" field.
  DocumentReference? _businessRef;
  DocumentReference? get businessRef => _businessRef;
  set businessRef(DocumentReference? val) => _businessRef = val;

  bool hasBusinessRef() => _businessRef != null;

  // "view_count" field.
  int? _viewCount;
  int get viewCount => _viewCount ?? 0;
  set viewCount(int? val) => _viewCount = val;

  void incrementViewCount(int amount) => viewCount = viewCount + amount;

  bool hasViewCount() => _viewCount != null;

  static BusinessMetricStruct fromMap(Map<String, dynamic> data) =>
      BusinessMetricStruct(
        businessRef: data['business_ref'] as DocumentReference?,
        viewCount: castToType<int>(data['view_count']),
      );

  static BusinessMetricStruct? maybeFromMap(dynamic data) => data is Map
      ? BusinessMetricStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'business_ref': _businessRef,
        'view_count': _viewCount,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'business_ref': serializeParam(
          _businessRef,
          ParamType.DocumentReference,
        ),
        'view_count': serializeParam(
          _viewCount,
          ParamType.int,
        ),
      }.withoutNulls;

  static BusinessMetricStruct fromSerializableMap(Map<String, dynamic> data) =>
      BusinessMetricStruct(
        businessRef: deserializeParam(
          data['business_ref'],
          ParamType.DocumentReference,
          false,
          collectionNamePath: ['businesses'],
        ),
        viewCount: deserializeParam(
          data['view_count'],
          ParamType.int,
          false,
        ),
      );

  static BusinessMetricStruct fromAlgoliaData(Map<String, dynamic> data) =>
      BusinessMetricStruct(
        businessRef: convertAlgoliaParam(
          data['business_ref'],
          ParamType.DocumentReference,
          false,
        ),
        viewCount: convertAlgoliaParam(
          data['view_count'],
          ParamType.int,
          false,
        ),
        firestoreUtilData: FirestoreUtilData(
          clearUnsetFields: false,
          create: true,
        ),
      );

  @override
  String toString() => 'BusinessMetricStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is BusinessMetricStruct &&
        businessRef == other.businessRef &&
        viewCount == other.viewCount;
  }

  @override
  int get hashCode => const ListEquality().hash([businessRef, viewCount]);
}

BusinessMetricStruct createBusinessMetricStruct({
  DocumentReference? businessRef,
  int? viewCount,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    BusinessMetricStruct(
      businessRef: businessRef,
      viewCount: viewCount,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

BusinessMetricStruct? updateBusinessMetricStruct(
  BusinessMetricStruct? businessMetric, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    businessMetric
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addBusinessMetricStructData(
  Map<String, dynamic> firestoreData,
  BusinessMetricStruct? businessMetric,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (businessMetric == null) {
    return;
  }
  if (businessMetric.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && businessMetric.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final businessMetricData =
      getBusinessMetricFirestoreData(businessMetric, forFieldValue);
  final nestedData =
      businessMetricData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = businessMetric.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getBusinessMetricFirestoreData(
  BusinessMetricStruct? businessMetric, [
  bool forFieldValue = false,
]) {
  if (businessMetric == null) {
    return {};
  }
  final firestoreData = mapToFirestore(businessMetric.toMap());

  // Add any Firestore field values
  mapToFirestore(businessMetric.firestoreUtilData.fieldValues)
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getBusinessMetricListFirestoreData(
  List<BusinessMetricStruct>? businessMetrics,
) =>
    businessMetrics
        ?.map((e) => getBusinessMetricFirestoreData(e, true))
        .toList() ??
    [];
