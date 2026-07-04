import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class UserEngagementEventsRecord extends FirestoreRecord {
  UserEngagementEventsRecord._(
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

  // "target_ref" field.
  DocumentReference? _targetRef;
  DocumentReference? get targetRef => _targetRef;
  bool hasTargetRef() => _targetRef != null;

  // "event_type" field.
  String? _eventType;
  String get eventType => _eventType ?? '';
  bool hasEventType() => _eventType != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  // "points_awarded" field.
  int? _pointsAwarded;
  int get pointsAwarded => _pointsAwarded ?? 0;
  bool hasPointsAwarded() => _pointsAwarded != null;

  // "weight_version" field.
  String? _weightVersion;
  String get weightVersion => _weightVersion ?? '';
  bool hasWeightVersion() => _weightVersion != null;

  // "error" field.
  String? _error;
  String get error => _error ?? '';
  bool hasError() => _error != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "processed_at" field.
  DateTime? _processedAt;
  DateTime? get processedAt => _processedAt;
  bool hasProcessedAt() => _processedAt != null;

  void _initializeFields() {
    _userRef = snapshotData['user_ref'] as DocumentReference?;
    _businessRef = snapshotData['business_ref'] as DocumentReference?;
    _targetRef = snapshotData['target_ref'] as DocumentReference?;
    _eventType = snapshotData['event_type'] as String?;
    _status = snapshotData['status'] as String?;
    _pointsAwarded = castToType<int>(snapshotData['points_awarded']);
    _weightVersion = snapshotData['weight_version'] as String?;
    _error = snapshotData['error'] as String?;
    _createdAt = snapshotData['created_at'] as DateTime?;
    _processedAt = snapshotData['processed_at'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('UserEngagementEvents');

  static Stream<UserEngagementEventsRecord> getDocument(
          DocumentReference ref) =>
      ref.snapshots().map((s) => UserEngagementEventsRecord.fromSnapshot(s));

  static Future<UserEngagementEventsRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => UserEngagementEventsRecord.fromSnapshot(s));

  static UserEngagementEventsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      UserEngagementEventsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static UserEngagementEventsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      UserEngagementEventsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'UserEngagementEventsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is UserEngagementEventsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

/// Creates a pending engagement event for the Kindex scoring Cloud Function
/// to process. `status` is always 'pending' on create — clients can never
/// set `points_awarded`, `weight_version`, or `processed_at` (Firestore
/// rules reject creates that include those fields), since only the
/// server-side scoring engine is allowed to resolve and record them.
Map<String, dynamic> createUserEngagementEventsRecordData({
  DocumentReference? userRef,
  DocumentReference? businessRef,
  DocumentReference? targetRef,
  String? eventType,
  DateTime? createdAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'user_ref': userRef,
      'business_ref': businessRef,
      'target_ref': targetRef,
      'event_type': eventType,
      'status': 'pending',
      'created_at': createdAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class UserEngagementEventsRecordDocumentEquality
    implements Equality<UserEngagementEventsRecord> {
  const UserEngagementEventsRecordDocumentEquality();

  @override
  bool equals(UserEngagementEventsRecord? e1, UserEngagementEventsRecord? e2) {
    return e1?.userRef == e2?.userRef &&
        e1?.businessRef == e2?.businessRef &&
        e1?.targetRef == e2?.targetRef &&
        e1?.eventType == e2?.eventType &&
        e1?.status == e2?.status &&
        e1?.pointsAwarded == e2?.pointsAwarded &&
        e1?.weightVersion == e2?.weightVersion &&
        e1?.error == e2?.error &&
        e1?.createdAt == e2?.createdAt &&
        e1?.processedAt == e2?.processedAt;
  }

  @override
  int hash(UserEngagementEventsRecord? e) => const ListEquality().hash([
        e?.userRef,
        e?.businessRef,
        e?.targetRef,
        e?.eventType,
        e?.status,
        e?.pointsAwarded,
        e?.weightVersion,
        e?.error,
        e?.createdAt,
        e?.processedAt,
      ]);

  @override
  bool isValidKey(Object? o) => o is UserEngagementEventsRecord;
}
