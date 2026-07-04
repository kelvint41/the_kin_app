import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AnalyticsEventsRecord extends FirestoreRecord {
  AnalyticsEventsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "event_name" field.
  String? _eventName;
  String get eventName => _eventName ?? '';
  bool hasEventName() => _eventName != null;

  // "user_id" field.
  DocumentReference? _userId;
  DocumentReference? get userId => _userId;
  bool hasUserId() => _userId != null;

  // "business_id" field.
  DocumentReference? _businessId;
  DocumentReference? get businessId => _businessId;
  bool hasBusinessId() => _businessId != null;

  // "timestamp" field.
  DateTime? _timestamp;
  DateTime? get timestamp => _timestamp;
  bool hasTimestamp() => _timestamp != null;

  // "location" field.
  LatLng? _location;
  LatLng? get location => _location;
  bool hasLocation() => _location != null;

  // "is_black_owned_event" field.
  bool? _isBlackOwnedEvent;
  bool get isBlackOwnedEvent => _isBlackOwnedEvent ?? false;
  bool hasIsBlackOwnedEvent() => _isBlackOwnedEvent != null;

  void _initializeFields() {
    _eventName = snapshotData['event_name'] as String?;
    _userId = snapshotData['user_id'] as DocumentReference?;
    _businessId = snapshotData['business_id'] as DocumentReference?;
    _timestamp = snapshotData['timestamp'] as DateTime?;
    _location = snapshotData['location'] as LatLng?;
    _isBlackOwnedEvent = snapshotData['is_black_owned_event'] as bool?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('analytics_events');

  static Stream<AnalyticsEventsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => AnalyticsEventsRecord.fromSnapshot(s));

  static Future<AnalyticsEventsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => AnalyticsEventsRecord.fromSnapshot(s));

  static AnalyticsEventsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      AnalyticsEventsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static AnalyticsEventsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      AnalyticsEventsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'AnalyticsEventsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is AnalyticsEventsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createAnalyticsEventsRecordData({
  String? eventName,
  DocumentReference? userId,
  DocumentReference? businessId,
  DateTime? timestamp,
  LatLng? location,
  bool? isBlackOwnedEvent,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'event_name': eventName,
      'user_id': userId,
      'business_id': businessId,
      'timestamp': timestamp,
      'location': location,
      'is_black_owned_event': isBlackOwnedEvent,
    }.withoutNulls,
  );

  return firestoreData;
}

class AnalyticsEventsRecordDocumentEquality
    implements Equality<AnalyticsEventsRecord> {
  const AnalyticsEventsRecordDocumentEquality();

  @override
  bool equals(AnalyticsEventsRecord? e1, AnalyticsEventsRecord? e2) {
    return e1?.eventName == e2?.eventName &&
        e1?.userId == e2?.userId &&
        e1?.businessId == e2?.businessId &&
        e1?.timestamp == e2?.timestamp &&
        e1?.location == e2?.location &&
        e1?.isBlackOwnedEvent == e2?.isBlackOwnedEvent;
  }

  @override
  int hash(AnalyticsEventsRecord? e) => const ListEquality().hash([
        e?.eventName,
        e?.userId,
        e?.businessId,
        e?.timestamp,
        e?.location,
        e?.isBlackOwnedEvent
      ]);

  @override
  bool isValidKey(Object? o) => o is AnalyticsEventsRecord;
}
