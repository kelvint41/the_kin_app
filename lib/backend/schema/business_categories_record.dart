import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// The shared, ever-growing category vocabulary used by Business Setup
/// and both "Add a Business" discovery dialogs. Doc ID is the
/// lowercase/trimmed category name (see kin_services.dart's
/// ensureBusinessCategoryExists) - a `.set()` against an already-taken ID
/// is a no-op merge, not a duplicate, so no query is needed to check
/// existence before adding a new one.
class BusinessCategoriesRecord extends FirestoreRecord {
  BusinessCategoriesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "display_name" field.
  String? _displayName;
  String get displayName => _displayName ?? '';
  bool hasDisplayName() => _displayName != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "quest_eligible" field. Whether businesses in this category can appear
  // in the KIN Quest. Defaults to true when absent so an unflagged or
  // newly-added category behaves the way every category did before this
  // existed - only an explicit `false` opts a category out.
  //
  // Exists for service-area businesses (home care and similar): the client
  // never visits the office, so a check-in Quest entry makes no sense, even
  // though the business should still be listed and on the Job Board.
  bool? _questEligible;
  bool get questEligible => _questEligible ?? true;
  bool hasQuestEligible() => _questEligible != null;

  void _initializeFields() {
    _displayName = snapshotData['display_name'] as String?;
    _createdAt = snapshotData['created_at'] as DateTime?;
    _questEligible = snapshotData['quest_eligible'] as bool?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('business_categories');

  static Stream<BusinessCategoriesRecord> getDocument(
          DocumentReference ref) =>
      ref.snapshots().map((s) => BusinessCategoriesRecord.fromSnapshot(s));

  static Future<BusinessCategoriesRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => BusinessCategoriesRecord.fromSnapshot(s));

  static BusinessCategoriesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      BusinessCategoriesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static BusinessCategoriesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      BusinessCategoriesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'BusinessCategoriesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is BusinessCategoriesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createBusinessCategoriesRecordData({
  String? displayName,
  DateTime? createdAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'display_name': displayName,
      'created_at': createdAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class BusinessCategoriesRecordDocumentEquality
    implements Equality<BusinessCategoriesRecord> {
  const BusinessCategoriesRecordDocumentEquality();

  @override
  bool equals(BusinessCategoriesRecord? e1, BusinessCategoriesRecord? e2) {
    return e1?.displayName == e2?.displayName && e1?.createdAt == e2?.createdAt;
  }

  @override
  int hash(BusinessCategoriesRecord? e) =>
      const ListEquality().hash([e?.displayName, e?.createdAt]);

  @override
  bool isValidKey(Object? o) => o is BusinessCategoriesRecord;
}
