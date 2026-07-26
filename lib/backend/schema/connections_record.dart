import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ConnectionsRecord extends FirestoreRecord {
  ConnectionsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "sender_business_ref" field.
  DocumentReference? _senderBusinessRef;
  DocumentReference? get senderBusinessRef => _senderBusinessRef;
  bool hasSenderBusinessRef() => _senderBusinessRef != null;

  // "receiver_business_ref" field.
  DocumentReference? _receiverBusinessRef;
  DocumentReference? get receiverBusinessRef => _receiverBusinessRef;
  bool hasReceiverBusinessRef() => _receiverBusinessRef != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  void _initializeFields() {
    _senderBusinessRef =
        snapshotData['sender_business_ref'] as DocumentReference?;
    _receiverBusinessRef =
        snapshotData['receiver_business_ref'] as DocumentReference?;
    _status = snapshotData['status'] as String?;
    _createdAt = snapshotData['created_at'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('connections');

  static Stream<ConnectionsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ConnectionsRecord.fromSnapshot(s));

  static Future<ConnectionsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ConnectionsRecord.fromSnapshot(s));

  static ConnectionsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ConnectionsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ConnectionsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ConnectionsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ConnectionsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ConnectionsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createConnectionsRecordData({
  DocumentReference? senderBusinessRef,
  DocumentReference? receiverBusinessRef,
  String? status,
  DateTime? createdAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'sender_business_ref': senderBusinessRef,
      'receiver_business_ref': receiverBusinessRef,
      'status': status,
      'created_at': createdAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class ConnectionsRecordDocumentEquality implements Equality<ConnectionsRecord> {
  const ConnectionsRecordDocumentEquality();

  @override
  bool equals(ConnectionsRecord? e1, ConnectionsRecord? e2) {
    return e1?.senderBusinessRef == e2?.senderBusinessRef &&
        e1?.receiverBusinessRef == e2?.receiverBusinessRef &&
        e1?.status == e2?.status &&
        e1?.createdAt == e2?.createdAt;
  }

  @override
  int hash(ConnectionsRecord? e) => const ListEquality().hash(
      [e?.senderBusinessRef, e?.receiverBusinessRef, e?.status, e?.createdAt]);

  @override
  bool isValidKey(Object? o) => o is ConnectionsRecord;
}
