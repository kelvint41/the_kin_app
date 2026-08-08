import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// A customer's bookmarked business ("Saved Places").
///
/// Uses a composite doc id, `{userId}_{businessId}`, for the same reason
/// `reviews` does: it makes a save idempotent. Tapping the heart twice
/// writes and then deletes one known document rather than stacking
/// duplicates, and "is this saved?" is a direct doc read instead of a
/// query. See [SavedBusinessesRecord.docId].
class SavedBusinessesRecord extends FirestoreRecord {
  SavedBusinessesRecord._(
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

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  void _initializeFields() {
    _userRef = snapshotData['user_ref'] as DocumentReference?;
    _businessRef = snapshotData['business_ref'] as DocumentReference?;
    _createdAt = snapshotData['created_at'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('saved_businesses');

  /// The deterministic id for one user's save of one business - see the
  /// class doc comment. Both halves are Firestore doc ids, which never
  /// contain '_', so the join is unambiguous.
  static String docId({
    required DocumentReference userRef,
    required DocumentReference businessRef,
  }) =>
      '${userRef.id}_${businessRef.id}';

  static Stream<SavedBusinessesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => SavedBusinessesRecord.fromSnapshot(s));

  static Future<SavedBusinessesRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => SavedBusinessesRecord.fromSnapshot(s));

  static SavedBusinessesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      SavedBusinessesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static SavedBusinessesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      SavedBusinessesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'SavedBusinessesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is SavedBusinessesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createSavedBusinessesRecordData({
  DocumentReference? userRef,
  DocumentReference? businessRef,
  DateTime? createdAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'user_ref': userRef,
      'business_ref': businessRef,
      'created_at': createdAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class SavedBusinessesRecordDocumentEquality
    implements Equality<SavedBusinessesRecord> {
  const SavedBusinessesRecordDocumentEquality();

  @override
  bool equals(SavedBusinessesRecord? e1, SavedBusinessesRecord? e2) {
    return e1?.userRef == e2?.userRef &&
        e1?.businessRef == e2?.businessRef &&
        e1?.createdAt == e2?.createdAt;
  }

  @override
  int hash(SavedBusinessesRecord? e) => const ListEquality()
      .hash([e?.userRef, e?.businessRef, e?.createdAt]);

  @override
  bool isValidKey(Object? o) => o is SavedBusinessesRecord;
}
