import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

// Global live-feed backing store for the Community Shoutouts carousel.
// Deliberately separate from the existing `activity_logs` collection, which
// is an analytics event log (page views, engagement stats) read by the
// executive dashboard — this collection is display-only feed content.
class KinFeedEventsRecord extends FirestoreRecord {
  KinFeedEventsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "user_ref" field.
  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  // "user_name" field.
  String? _userName;
  String get userName => _userName ?? '';
  bool hasUserName() => _userName != null;

  // "city" field.
  String? _city;
  String get city => _city ?? '';
  bool hasCity() => _city != null;

  // "action_type" field. One of: KIN_QUEST_STAMP, NEW_DISCOVERY,
  // EXCHANGE_POST, REWARD_UNLOCKED.
  String? _actionType;
  String get actionType => _actionType ?? '';
  bool hasActionType() => _actionType != null;

  // "business_ref" field.
  DocumentReference? _businessRef;
  DocumentReference? get businessRef => _businessRef;
  bool hasBusinessRef() => _businessRef != null;

  // "business_name" field.
  String? _businessName;
  String get businessName => _businessName ?? '';
  bool hasBusinessName() => _businessName != null;

  // "timestamp" field.
  DateTime? _timestamp;
  DateTime? get timestamp => _timestamp;
  bool hasTimestamp() => _timestamp != null;

  void _initializeFields() {
    _userRef = snapshotData['user_ref'] as DocumentReference?;
    _userName = snapshotData['user_name'] as String?;
    _city = snapshotData['city'] as String?;
    _actionType = snapshotData['action_type'] as String?;
    _businessRef = snapshotData['business_ref'] as DocumentReference?;
    _businessName = snapshotData['business_name'] as String?;
    _timestamp = snapshotData['timestamp'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('kin_feed_events');

  static Stream<KinFeedEventsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => KinFeedEventsRecord.fromSnapshot(s));

  static Future<KinFeedEventsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => KinFeedEventsRecord.fromSnapshot(s));

  static KinFeedEventsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      KinFeedEventsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static KinFeedEventsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      KinFeedEventsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'KinFeedEventsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is KinFeedEventsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createKinFeedEventsRecordData({
  DocumentReference? userRef,
  String? userName,
  String? city,
  String? actionType,
  DocumentReference? businessRef,
  String? businessName,
  DateTime? timestamp,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'user_ref': userRef,
      'user_name': userName,
      'city': city,
      'action_type': actionType,
      'business_ref': businessRef,
      'business_name': businessName,
      'timestamp': timestamp,
    }.withoutNulls,
  );

  return firestoreData;
}

class KinFeedEventsRecordDocumentEquality
    implements Equality<KinFeedEventsRecord> {
  const KinFeedEventsRecordDocumentEquality();

  @override
  bool equals(KinFeedEventsRecord? e1, KinFeedEventsRecord? e2) {
    return e1?.userRef == e2?.userRef &&
        e1?.userName == e2?.userName &&
        e1?.city == e2?.city &&
        e1?.actionType == e2?.actionType &&
        e1?.businessRef == e2?.businessRef &&
        e1?.businessName == e2?.businessName &&
        e1?.timestamp == e2?.timestamp;
  }

  @override
  int hash(KinFeedEventsRecord? e) => const ListEquality().hash([
        e?.userRef,
        e?.userName,
        e?.city,
        e?.actionType,
        e?.businessRef,
        e?.businessName,
        e?.timestamp,
      ]);

  @override
  bool isValidKey(Object? o) => o is KinFeedEventsRecord;
}
