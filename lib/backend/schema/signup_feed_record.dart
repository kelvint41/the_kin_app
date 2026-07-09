import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class SignupFeedRecord extends FirestoreRecord {
  SignupFeedRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "user_ref" field.
  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  // "display_name" field.
  String? _displayName;
  String get displayName => _displayName ?? '';
  bool hasDisplayName() => _displayName != null;

  // "subscription_status" field.
  String? _subscriptionStatus;
  String get subscriptionStatus => _subscriptionStatus ?? '';
  bool hasSubscriptionStatus() => _subscriptionStatus != null;

  // "timestamp" field.
  DateTime? _timestamp;
  DateTime? get timestamp => _timestamp;
  bool hasTimestamp() => _timestamp != null;

  void _initializeFields() {
    _userRef = snapshotData['user_ref'] as DocumentReference?;
    _displayName = snapshotData['display_name'] as String?;
    _subscriptionStatus = snapshotData['subscription_status'] as String?;
    _timestamp = snapshotData['timestamp'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('signup_feed');

  static Stream<SignupFeedRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => SignupFeedRecord.fromSnapshot(s));

  static Future<SignupFeedRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => SignupFeedRecord.fromSnapshot(s));

  static SignupFeedRecord fromSnapshot(DocumentSnapshot snapshot) =>
      SignupFeedRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static SignupFeedRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      SignupFeedRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'SignupFeedRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is SignupFeedRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createSignupFeedRecordData({
  DocumentReference? userRef,
  String? displayName,
  String? subscriptionStatus,
  DateTime? timestamp,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'user_ref': userRef,
      'display_name': displayName,
      'subscription_status': subscriptionStatus,
      'timestamp': timestamp,
    }.withoutNulls,
  );

  return firestoreData;
}

class SignupFeedRecordDocumentEquality implements Equality<SignupFeedRecord> {
  const SignupFeedRecordDocumentEquality();

  @override
  bool equals(SignupFeedRecord? e1, SignupFeedRecord? e2) {
    return e1?.userRef == e2?.userRef &&
        e1?.displayName == e2?.displayName &&
        e1?.subscriptionStatus == e2?.subscriptionStatus &&
        e1?.timestamp == e2?.timestamp;
  }

  @override
  int hash(SignupFeedRecord? e) => const ListEquality()
      .hash([e?.userRef, e?.displayName, e?.subscriptionStatus, e?.timestamp]);

  @override
  bool isValidKey(Object? o) => o is SignupFeedRecord;
}
