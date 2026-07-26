// ignore_for_file: unnecessary_getters_setters
import '/backend/algolia/serialization_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class CategoryMetricStruct extends FFFirebaseStruct {
  CategoryMetricStruct({
    String? categoryName,
    int? viewCount,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _categoryName = categoryName,
        _viewCount = viewCount,
        super(firestoreUtilData);

  // "category_name" field.
  String? _categoryName;
  String get categoryName => _categoryName ?? '';
  set categoryName(String? val) => _categoryName = val;

  bool hasCategoryName() => _categoryName != null;

  // "view_count" field.
  int? _viewCount;
  int get viewCount => _viewCount ?? 0;
  set viewCount(int? val) => _viewCount = val;

  void incrementViewCount(int amount) => viewCount = viewCount + amount;

  bool hasViewCount() => _viewCount != null;

  static CategoryMetricStruct fromMap(Map<String, dynamic> data) =>
      CategoryMetricStruct(
        categoryName: data['category_name'] as String?,
        viewCount: castToType<int>(data['view_count']),
      );

  static CategoryMetricStruct? maybeFromMap(dynamic data) => data is Map
      ? CategoryMetricStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'category_name': _categoryName,
        'view_count': _viewCount,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'category_name': serializeParam(
          _categoryName,
          ParamType.String,
        ),
        'view_count': serializeParam(
          _viewCount,
          ParamType.int,
        ),
      }.withoutNulls;

  static CategoryMetricStruct fromSerializableMap(Map<String, dynamic> data) =>
      CategoryMetricStruct(
        categoryName: deserializeParam(
          data['category_name'],
          ParamType.String,
          false,
        ),
        viewCount: deserializeParam(
          data['view_count'],
          ParamType.int,
          false,
        ),
      );

  static CategoryMetricStruct fromAlgoliaData(Map<String, dynamic> data) =>
      CategoryMetricStruct(
        categoryName: convertAlgoliaParam(
          data['category_name'],
          ParamType.String,
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
  String toString() => 'CategoryMetricStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is CategoryMetricStruct &&
        categoryName == other.categoryName &&
        viewCount == other.viewCount;
  }

  @override
  int get hashCode => const ListEquality().hash([categoryName, viewCount]);
}

CategoryMetricStruct createCategoryMetricStruct({
  String? categoryName,
  int? viewCount,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    CategoryMetricStruct(
      categoryName: categoryName,
      viewCount: viewCount,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

CategoryMetricStruct? updateCategoryMetricStruct(
  CategoryMetricStruct? categoryMetric, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    categoryMetric
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addCategoryMetricStructData(
  Map<String, dynamic> firestoreData,
  CategoryMetricStruct? categoryMetric,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (categoryMetric == null) {
    return;
  }
  if (categoryMetric.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && categoryMetric.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final categoryMetricData =
      getCategoryMetricFirestoreData(categoryMetric, forFieldValue);
  final nestedData =
      categoryMetricData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = categoryMetric.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getCategoryMetricFirestoreData(
  CategoryMetricStruct? categoryMetric, [
  bool forFieldValue = false,
]) {
  if (categoryMetric == null) {
    return {};
  }
  final firestoreData = mapToFirestore(categoryMetric.toMap());

  // Add any Firestore field values
  mapToFirestore(categoryMetric.firestoreUtilData.fieldValues)
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getCategoryMetricListFirestoreData(
  List<CategoryMetricStruct>? categoryMetrics,
) =>
    categoryMetrics
        ?.map((e) => getCategoryMetricFirestoreData(e, true))
        .toList() ??
    [];
