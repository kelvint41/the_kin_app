import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

// Audit trail for the "Add a Business" discovery flow. Written by the
// submitBusinessDiscovery callable alongside incrementing
// businesses.businesses_discovered_count on the submitting owner's listing.
class BusinessSubmissionsRecord extends FirestoreRecord {
  BusinessSubmissionsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "submitted_by_business_ref" field.
  DocumentReference? _submittedByBusinessRef;
  DocumentReference? get submittedByBusinessRef => _submittedByBusinessRef;
  bool hasSubmittedByBusinessRef() => _submittedByBusinessRef != null;

  // "submitted_by_user_ref" field.
  DocumentReference? _submittedByUserRef;
  DocumentReference? get submittedByUserRef => _submittedByUserRef;
  bool hasSubmittedByUserRef() => _submittedByUserRef != null;

  // "business_name" field.
  String? _businessName;
  String get businessName => _businessName ?? '';
  bool hasBusinessName() => _businessName != null;

  // "address" field.
  String? _address;
  String get address => _address ?? '';
  bool hasAddress() => _address != null;

  // "category" field.
  String? _category;
  String get category => _category ?? '';
  bool hasCategory() => _category != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  void _initializeFields() {
    _submittedByBusinessRef =
        snapshotData['submitted_by_business_ref'] as DocumentReference?;
    _submittedByUserRef =
        snapshotData['submitted_by_user_ref'] as DocumentReference?;
    _businessName = snapshotData['business_name'] as String?;
    _address = snapshotData['address'] as String?;
    _category = snapshotData['category'] as String?;
    _createdAt = snapshotData['created_at'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('business_submissions');

  static Stream<BusinessSubmissionsRecord> getDocument(
          DocumentReference ref) =>
      ref.snapshots().map((s) => BusinessSubmissionsRecord.fromSnapshot(s));

  static Future<BusinessSubmissionsRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => BusinessSubmissionsRecord.fromSnapshot(s));

  static BusinessSubmissionsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      BusinessSubmissionsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static BusinessSubmissionsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      BusinessSubmissionsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'BusinessSubmissionsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is BusinessSubmissionsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createBusinessSubmissionsRecordData({
  DocumentReference? submittedByBusinessRef,
  DocumentReference? submittedByUserRef,
  String? businessName,
  String? address,
  String? category,
  DateTime? createdAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'submitted_by_business_ref': submittedByBusinessRef,
      'submitted_by_user_ref': submittedByUserRef,
      'business_name': businessName,
      'address': address,
      'category': category,
      'created_at': createdAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class BusinessSubmissionsRecordDocumentEquality
    implements Equality<BusinessSubmissionsRecord> {
  const BusinessSubmissionsRecordDocumentEquality();

  @override
  bool equals(BusinessSubmissionsRecord? e1, BusinessSubmissionsRecord? e2) {
    return e1?.submittedByBusinessRef == e2?.submittedByBusinessRef &&
        e1?.submittedByUserRef == e2?.submittedByUserRef &&
        e1?.businessName == e2?.businessName &&
        e1?.address == e2?.address &&
        e1?.category == e2?.category &&
        e1?.createdAt == e2?.createdAt;
  }

  @override
  int hash(BusinessSubmissionsRecord? e) => const ListEquality().hash([
        e?.submittedByBusinessRef,
        e?.submittedByUserRef,
        e?.businessName,
        e?.address,
        e?.category,
        e?.createdAt,
      ]);

  @override
  bool isValidKey(Object? o) => o is BusinessSubmissionsRecord;
}
