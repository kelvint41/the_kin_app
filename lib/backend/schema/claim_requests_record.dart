import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

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

  // "status" field. One of 'pending' | 'approved' | 'rejected'. Only ever
  // set to 'pending' from the client - firestore.rules makes claim_requests
  // write-only for clients, so approval is an Admin SDK operation.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  // "timestamp" field.
  DateTime? _timestamp;
  DateTime? get timestamp => _timestamp;
  bool hasTimestamp() => _timestamp != null;

  // "business_name" field. Denormalized off the business doc so a reviewer
  // can work the queue without a second read per request.
  String? _businessName;
  String get businessName => _businessName ?? '';
  bool hasBusinessName() => _businessName != null;

  // "claimant_name" field.
  String? _claimantName;
  String get claimantName => _claimantName ?? '';
  bool hasClaimantName() => _claimantName != null;

  // "claimant_role" field. Free text - 'Owner', 'Manager', etc.
  String? _claimantRole;
  String get claimantRole => _claimantRole ?? '';
  bool hasClaimantRole() => _claimantRole != null;

  // "contact_email" field. How the reviewer follows up. Deliberately the
  // only contact detail we ask for beyond what's already public.
  String? _contactEmail;
  String get contactEmail => _contactEmail ?? '';
  bool hasContactEmail() => _contactEmail != null;

  // "contact_phone" field.
  String? _contactPhone;
  String get contactPhone => _contactPhone ?? '';
  bool hasContactPhone() => _contactPhone != null;

  // "attested" field. True only if the claimant ticked the ownership
  // attestation. Stored with attested_at so there's a record of what was
  // agreed to and when.
  bool? _attested;
  bool get attested => _attested ?? false;
  bool hasAttested() => _attested != null;

  // "attested_at" field.
  DateTime? _attestedAt;
  DateTime? get attestedAt => _attestedAt;
  bool hasAttestedAt() => _attestedAt != null;

  // "declared_black_owned" field. Self-declared by the claimant, never
  // inferred and never evidenced by documentation - see the claim form.
  // Copied onto the business's is_black_owned only once a claim is approved.
  bool? _declaredBlackOwned;
  bool get declaredBlackOwned => _declaredBlackOwned ?? false;
  bool hasDeclaredBlackOwned() => _declaredBlackOwned != null;

  // "declared_veteran" field. Self-declared, same handling as above.
  bool? _declaredVeteran;
  bool get declaredVeteran => _declaredVeteran ?? false;
  bool hasDeclaredVeteran() => _declaredVeteran != null;

  void _initializeFields() {
    _businessId = snapshotData['business_id'] as String?;
    _applicantUserId = snapshotData['applicant_user_id'] as String?;
    _verificationProofLink = snapshotData['verification_proof_link'] as String?;
    _status = snapshotData['status'] as String?;
    _timestamp = snapshotData['timestamp'] as DateTime?;
    _businessName = snapshotData['business_name'] as String?;
    _claimantName = snapshotData['claimant_name'] as String?;
    _claimantRole = snapshotData['claimant_role'] as String?;
    _contactEmail = snapshotData['contact_email'] as String?;
    _contactPhone = snapshotData['contact_phone'] as String?;
    _attested = snapshotData['attested'] as bool?;
    _attestedAt = snapshotData['attested_at'] as DateTime?;
    _declaredBlackOwned = snapshotData['declared_black_owned'] as bool?;
    _declaredVeteran = snapshotData['declared_veteran'] as bool?;
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
  String? businessName,
  String? claimantName,
  String? claimantRole,
  String? contactEmail,
  String? contactPhone,
  bool? attested,
  DateTime? attestedAt,
  bool? declaredBlackOwned,
  bool? declaredVeteran,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'business_id': businessId,
      'applicant_user_id': applicantUserId,
      'verification_proof_link': verificationProofLink,
      'status': status,
      'timestamp': timestamp,
      'business_name': businessName,
      'claimant_name': claimantName,
      'claimant_role': claimantRole,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'attested': attested,
      'attested_at': attestedAt,
      'declared_black_owned': declaredBlackOwned,
      'declared_veteran': declaredVeteran,
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
        e1?.timestamp == e2?.timestamp &&
        e1?.businessName == e2?.businessName &&
        e1?.claimantName == e2?.claimantName &&
        e1?.claimantRole == e2?.claimantRole &&
        e1?.contactEmail == e2?.contactEmail &&
        e1?.contactPhone == e2?.contactPhone &&
        e1?.attested == e2?.attested &&
        e1?.attestedAt == e2?.attestedAt &&
        e1?.declaredBlackOwned == e2?.declaredBlackOwned &&
        e1?.declaredVeteran == e2?.declaredVeteran;
  }

  @override
  int hash(ClaimRequestsRecord? e) => const ListEquality().hash([
        e?.businessId,
        e?.applicantUserId,
        e?.verificationProofLink,
        e?.status,
        e?.timestamp,
        e?.businessName,
        e?.claimantName,
        e?.claimantRole,
        e?.contactEmail,
        e?.contactPhone,
        e?.attested,
        e?.attestedAt,
        e?.declaredBlackOwned,
        e?.declaredVeteran
      ]);

  @override
  bool isValidKey(Object? o) => o is ClaimRequestsRecord;
}
