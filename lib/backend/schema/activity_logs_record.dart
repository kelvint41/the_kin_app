import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ActivityLogsRecord extends FirestoreRecord {
  ActivityLogsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "event_type" field.
  String? _eventType;
  String get eventType => _eventType ?? '';
  bool hasEventType() => _eventType != null;

  // "business_ref" field.
  DocumentReference? _businessRef;
  DocumentReference? get businessRef => _businessRef;
  bool hasBusinessRef() => _businessRef != null;

  // "user_ref" field.
  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  // "city" field.
  String? _city;
  String get city => _city ?? '';
  bool hasCity() => _city != null;

  // "page_name" field.
  String? _pageName;
  String get pageName => _pageName ?? '';
  bool hasPageName() => _pageName != null;

  // "category" field.
  String? _category;
  String get category => _category ?? '';
  bool hasCategory() => _category != null;

  // "is_black_owned" field.
  bool? _isBlackOwned;
  bool get isBlackOwned => _isBlackOwned ?? false;
  bool hasIsBlackOwned() => _isBlackOwned != null;

  // "platform" field.
  String? _platform;
  String get platform => _platform ?? '';
  bool hasPlatform() => _platform != null;

  // "timestamp" field.
  DateTime? _timestamp;
  DateTime? get timestamp => _timestamp;
  bool hasTimestamp() => _timestamp != null;

  // "session_id" field.
  String? _sessionId;
  String get sessionId => _sessionId ?? '';
  bool hasSessionId() => _sessionId != null;

  void _initializeFields() {
    _eventType = snapshotData['event_type'] as String?;
    _businessRef = snapshotData['business_ref'] as DocumentReference?;
    _userRef = snapshotData['user_ref'] as DocumentReference?;
    _city = snapshotData['city'] as String?;
    _pageName = snapshotData['page_name'] as String?;
    _category = snapshotData['category'] as String?;
    _isBlackOwned = snapshotData['is_black_owned'] as bool?;
    _platform = snapshotData['platform'] as String?;
    _timestamp = snapshotData['timestamp'] as DateTime?;
    _sessionId = snapshotData['session_id'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('activity_logs');

  static Stream<ActivityLogsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ActivityLogsRecord.fromSnapshot(s));

  static Future<ActivityLogsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ActivityLogsRecord.fromSnapshot(s));

  static ActivityLogsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ActivityLogsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ActivityLogsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ActivityLogsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ActivityLogsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ActivityLogsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createActivityLogsRecordData({
  String? eventType,
  DocumentReference? businessRef,
  DocumentReference? userRef,
  String? city,
  String? pageName,
  String? category,
  bool? isBlackOwned,
  String? platform,
  DateTime? timestamp,
  String? sessionId,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'event_type': eventType,
      'business_ref': businessRef,
      'user_ref': userRef,
      'city': city,
      'page_name': pageName,
      'category': category,
      'is_black_owned': isBlackOwned,
      'platform': platform,
      'timestamp': timestamp,
      'session_id': sessionId,
    }.withoutNulls,
  );

  return firestoreData;
}

class ActivityLogsRecordDocumentEquality
    implements Equality<ActivityLogsRecord> {
  const ActivityLogsRecordDocumentEquality();

  @override
  bool equals(ActivityLogsRecord? e1, ActivityLogsRecord? e2) {
    return e1?.eventType == e2?.eventType &&
        e1?.businessRef == e2?.businessRef &&
        e1?.userRef == e2?.userRef &&
        e1?.city == e2?.city &&
        e1?.pageName == e2?.pageName &&
        e1?.category == e2?.category &&
        e1?.isBlackOwned == e2?.isBlackOwned &&
        e1?.platform == e2?.platform &&
        e1?.timestamp == e2?.timestamp &&
        e1?.sessionId == e2?.sessionId;
  }

  @override
  int hash(ActivityLogsRecord? e) => const ListEquality().hash([
        e?.eventType,
        e?.businessRef,
        e?.userRef,
        e?.city,
        e?.pageName,
        e?.category,
        e?.isBlackOwned,
        e?.platform,
        e?.timestamp,
        e?.sessionId
      ]);

  @override
  bool isValidKey(Object? o) => o is ActivityLogsRecord;
}
