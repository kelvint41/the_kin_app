import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class UservisitsRecord extends FirestoreRecord {
  UservisitsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "user_ref" field.
  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  // "business_ref" field.
  DocumentReference? _businessRef;
  DocumentReference? get businessRef => _businessRef;
  bool hasBusinessRef() => _businessRef != null;

  // "visit_timestamp" field.
  DateTime? _visitTimestamp;
  DateTime? get visitTimestamp => _visitTimestamp;
  bool hasVisitTimestamp() => _visitTimestamp != null;

  void _initializeFields() {
    _userRef = snapshotData['user_ref'] as DocumentReference?;
    _businessRef = snapshotData['business_ref'] as DocumentReference?;
    _visitTimestamp = snapshotData['visit_timestamp'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('uservisits');

  static Stream<UservisitsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => UservisitsRecord.fromSnapshot(s));

  static Future<UservisitsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => UservisitsRecord.fromSnapshot(s));

  static UservisitsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      UservisitsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static UservisitsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      UservisitsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'UservisitsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is UservisitsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createUservisitsRecordData({
  DocumentReference? userRef,
  DocumentReference? businessRef,
  DateTime? visitTimestamp,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'user_ref': userRef,
      'business_ref': businessRef,
      'visit_timestamp': visitTimestamp,
    }.withoutNulls,
  );

  return firestoreData;
}

class UservisitsRecordDocumentEquality implements Equality<UservisitsRecord> {
  const UservisitsRecordDocumentEquality();

  @override
  bool equals(UservisitsRecord? e1, UservisitsRecord? e2) {
    return e1?.userRef == e2?.userRef &&
        e1?.businessRef == e2?.businessRef &&
        e1?.visitTimestamp == e2?.visitTimestamp;
  }

  @override
  int hash(UservisitsRecord? e) => const ListEquality()
      .hash([e?.userRef, e?.businessRef, e?.visitTimestamp]);

  @override
  bool isValidKey(Object? o) => o is UservisitsRecord;
}
