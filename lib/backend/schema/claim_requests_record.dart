import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ClaimRequestsRecord extends FirestoreRecord {
  ClaimRequestsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "business_id" field.
  String? _businessId;
  String get businessId => _businessId ?? '';
  bool hasBusinessId() => _businessId != null;

  // "applicant_user_id" field.
  String? _applicantUserId;
  String get applicantUserId => _applicantUserId ?? '';
  bool hasApplicantUserId() => _applicantUserId != null;

  // "verification_proof_link" field.
  String? _verificationProofLink;
  String get verificationProofLink => _verificationProofLink ?? '';
  bool hasVerificationProofLink() => _verificationProofLink != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  // "timestamp" field.
  DateTime? _timestamp;
  DateTime? get timestamp => _timestamp;
  bool hasTimestamp() => _timestamp != null;

  void _initializeFields() {
    _businessId = snapshotData['business_id'] as String?;
    _applicantUserId = snapshotData['applicant_user_id'] as String?;
    _verificationProofLink = snapshotData['verification_proof_link'] as String?;
    _status = snapshotData['status'] as String?;
    _timestamp = snapshotData['timestamp'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('claim_requests');

  static Stream<ClaimRequestsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ClaimRequestsRecord.fromSnapshot(s));

  static Future<ClaimRequestsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ClaimRequestsRecord.fromSnapshot(s));

  static ClaimRequestsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ClaimRequestsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ClaimRequestsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ClaimRequestsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ClaimRequestsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ClaimRequestsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createClaimRequestsRecordData({
  String? businessId,
  String? applicantUserId,
  String? verificationProofLink,
  String? status,
  DateTime? timestamp,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'business_id': businessId,
      'applicant_user_id': applicantUserId,
      'verification_proof_link': verificationProofLink,
      'status': status,
      'timestamp': timestamp,
    }.withoutNulls,
  );

  return firestoreData;
}

class ClaimRequestsRecordDocumentEquality
    implements Equality<ClaimRequestsRecord> {
  const ClaimRequestsRecordDocumentEquality();

  @override
  bool equals(ClaimRequestsRecord? e1, ClaimRequestsRecord? e2) {
    return e1?.businessId == e2?.businessId &&
        e1?.applicantUserId == e2?.applicantUserId &&
        e1?.verificationProofLink == e2?.verificationProofLink &&
        e1?.status == e2?.status &&
        e1?.timestamp == e2?.timestamp;
  }

  @override
  int hash(ClaimRequestsRecord? e) => const ListEquality().hash([
        e?.businessId,
        e?.applicantUserId,
        e?.verificationProofLink,
        e?.status,
        e?.timestamp
      ]);

  @override
  bool isValidKey(Object? o) => o is ClaimRequestsRecord;
}
