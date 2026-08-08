import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// One "Log a Visit / Spend" entry in the Community Impact tracker.
///
/// Auto-id rather than the composite id `saved_businesses` and `reviews`
/// use: those are one-per-user-per-business by definition, but a customer
/// can legitimately log many visits to the same business over time, and
/// each one is its own event.
///
/// [businessRef] is nullable on purpose. The logging sheet accepts a
/// free-text business name so a shopper can record a spend at a
/// Black-owned business KIN hasn't listed yet - that entry still counts
/// toward their totals, it just has no directory document to point at.
/// [businessName] is therefore always populated and [businessRef] only
/// sometimes.
class SpendLogsRecord extends FirestoreRecord {
  SpendLogsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "user_ref" field.
  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  // "business_ref" field. Null for free-text entries - see the class doc.
  DocumentReference? _businessRef;
  DocumentReference? get businessRef => _businessRef;
  bool hasBusinessRef() => _businessRef != null;

  // "business_name" field.
  String? _businessName;
  String get businessName => _businessName ?? '';
  bool hasBusinessName() => _businessName != null;

  // "business_city" field. Denormalized off the matched BusinessesRecord
  // at log time (empty for a free-text entry with no match) - this is
  // what lets the community_impact_stats aggregate break spend down by
  // city without a join, and without ever reading another user's entries
  // to do it (see firestore.rules' spend_logs comment).
  String? _businessCity;
  String get businessCity => _businessCity ?? '';
  bool hasBusinessCity() => _businessCity != null;

  // "business_category" field. Same denormalization as business_city,
  // for the Executive Dashboard's by-category breakdown.
  String? _businessCategory;
  String get businessCategory => _businessCategory ?? '';
  bool hasBusinessCategory() => _businessCategory != null;

  // "amount" field. Estimated spend in USD. Zero is valid and means a
  // check-in with no purchase.
  double? _amount;
  double get amount => _amount ?? 0.0;
  bool hasAmount() => _amount != null;

  // "spent_at" field. When the visit happened, which the customer can
  // backdate - distinct from created_at below, which is when they logged
  // it. Streak and month bucketing both read this one.
  DateTime? _spentAt;
  DateTime? get spentAt => _spentAt;
  bool hasSpentAt() => _spentAt != null;

  // "note" field.
  String? _note;
  String get note => _note ?? '';
  bool hasNote() => _note != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  void _initializeFields() {
    _userRef = snapshotData['user_ref'] as DocumentReference?;
    _businessRef = snapshotData['business_ref'] as DocumentReference?;
    _businessName = snapshotData['business_name'] as String?;
    _businessCity = snapshotData['business_city'] as String?;
    _businessCategory = snapshotData['business_category'] as String?;
    _amount = castToType<double>(snapshotData['amount']);
    _spentAt = snapshotData['spent_at'] as DateTime?;
    _note = snapshotData['note'] as String?;
    _createdAt = snapshotData['created_at'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('spend_logs');

  static Stream<SpendLogsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => SpendLogsRecord.fromSnapshot(s));

  static Future<SpendLogsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => SpendLogsRecord.fromSnapshot(s));

  static SpendLogsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      SpendLogsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static SpendLogsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      SpendLogsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'SpendLogsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is SpendLogsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createSpendLogsRecordData({
  DocumentReference? userRef,
  DocumentReference? businessRef,
  String? businessName,
  String? businessCity,
  String? businessCategory,
  double? amount,
  DateTime? spentAt,
  String? note,
  DateTime? createdAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'user_ref': userRef,
      'business_ref': businessRef,
      'business_name': businessName,
      'business_city': businessCity,
      'business_category': businessCategory,
      'amount': amount,
      'spent_at': spentAt,
      'note': note,
      'created_at': createdAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class SpendLogsRecordDocumentEquality implements Equality<SpendLogsRecord> {
  const SpendLogsRecordDocumentEquality();

  @override
  bool equals(SpendLogsRecord? e1, SpendLogsRecord? e2) {
    return e1?.userRef == e2?.userRef &&
        e1?.businessRef == e2?.businessRef &&
        e1?.businessName == e2?.businessName &&
        e1?.businessCity == e2?.businessCity &&
        e1?.businessCategory == e2?.businessCategory &&
        e1?.amount == e2?.amount &&
        e1?.spentAt == e2?.spentAt &&
        e1?.note == e2?.note &&
        e1?.createdAt == e2?.createdAt;
  }

  @override
  int hash(SpendLogsRecord? e) => const ListEquality().hash([
        e?.userRef,
        e?.businessRef,
        e?.businessName,
        e?.businessCity,
        e?.businessCategory,
        e?.amount,
        e?.spentAt,
        e?.note,
        e?.createdAt,
      ]);

  @override
  bool isValidKey(Object? o) => o is SpendLogsRecord;
}
