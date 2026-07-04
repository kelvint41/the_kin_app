import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Read-only from the client. Firestore rules block create/update/delete
/// on this collection entirely — the score is only ever written by the
/// Kindex scoring Cloud Function via the Admin SDK, which bypasses rules.
class KindexScoresRecord extends FirestoreRecord {
  KindexScoresRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "user_ref" field.
  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  // "score" field.
  double? _score;
  double get score => _score ?? 0.0;
  bool hasScore() => _score != null;

  // "last_event_id" field.
  String? _lastEventId;
  String get lastEventId => _lastEventId ?? '';
  bool hasLastEventId() => _lastEventId != null;

  // "last_updated" field.
  DateTime? _lastUpdated;
  DateTime? get lastUpdated => _lastUpdated;
  bool hasLastUpdated() => _lastUpdated != null;

  void _initializeFields() {
    _userRef = snapshotData['user_ref'] as DocumentReference?;
    _score = castToType<double>(snapshotData['score']);
    _lastEventId = snapshotData['last_event_id'] as String?;
    _lastUpdated = snapshotData['last_updated'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('KindexScores');

  static Stream<KindexScoresRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => KindexScoresRecord.fromSnapshot(s));

  static Future<KindexScoresRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => KindexScoresRecord.fromSnapshot(s));

  static KindexScoresRecord fromSnapshot(DocumentSnapshot snapshot) =>
      KindexScoresRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static KindexScoresRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      KindexScoresRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'KindexScoresRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is KindexScoresRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

class KindexScoresRecordDocumentEquality
    implements Equality<KindexScoresRecord> {
  const KindexScoresRecordDocumentEquality();

  @override
  bool equals(KindexScoresRecord? e1, KindexScoresRecord? e2) {
    return e1?.userRef == e2?.userRef &&
        e1?.score == e2?.score &&
        e1?.lastEventId == e2?.lastEventId &&
        e1?.lastUpdated == e2?.lastUpdated;
  }

  @override
  int hash(KindexScoresRecord? e) => const ListEquality().hash([
        e?.userRef,
        e?.score,
        e?.lastEventId,
        e?.lastUpdated,
      ]);

  @override
  bool isValidKey(Object? o) => o is KindexScoresRecord;
}
