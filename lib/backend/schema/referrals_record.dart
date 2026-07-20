import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ReferralsRecord extends FirestoreRecord {
  ReferralsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "code" field.
  String? _code;
  String get code => _code ?? '';
  bool hasCode() => _code != null;

  // "campaign_ref" field.
  DocumentReference? _campaignRef;
  DocumentReference? get campaignRef => _campaignRef;
  bool hasCampaignRef() => _campaignRef != null;

  // "referrer_ref" field.
  DocumentReference? _referrerRef;
  DocumentReference? get referrerRef => _referrerRef;
  bool hasReferrerRef() => _referrerRef != null;

  // "referee_ref" field.
  DocumentReference? _refereeRef;
  DocumentReference? get refereeRef => _refereeRef;
  bool hasRefereeRef() => _refereeRef != null;

  // "region" field.
  String? _region;
  String get region => _region ?? '';
  bool hasRegion() => _region != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  // "reject_reason" field.
  String? _rejectReason;
  String get rejectReason => _rejectReason ?? '';
  bool hasRejectReason() => _rejectReason != null;

  // "referrer_points_awarded" field.
  int? _referrerPointsAwarded;
  int get referrerPointsAwarded => _referrerPointsAwarded ?? 0;
  bool hasReferrerPointsAwarded() => _referrerPointsAwarded != null;

  // "referee_points_awarded" field.
  int? _refereePointsAwarded;
  int get refereePointsAwarded => _refereePointsAwarded ?? 0;
  bool hasRefereePointsAwarded() => _refereePointsAwarded != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "processed_at" field.
  DateTime? _processedAt;
  DateTime? get processedAt => _processedAt;
  bool hasProcessedAt() => _processedAt != null;

  void _initializeFields() {
    _code = snapshotData['code'] as String?;
    _campaignRef = snapshotData['campaign_ref'] as DocumentReference?;
    _referrerRef = snapshotData['referrer_ref'] as DocumentReference?;
    _refereeRef = snapshotData['referee_ref'] as DocumentReference?;
    _region = snapshotData['region'] as String?;
    _status = snapshotData['status'] as String?;
    _rejectReason = snapshotData['reject_reason'] as String?;
    _referrerPointsAwarded =
        castToType<int>(snapshotData['referrer_points_awarded']);
    _refereePointsAwarded =
        castToType<int>(snapshotData['referee_points_awarded']);
    _createdAt = snapshotData['created_at'] as DateTime?;
    _processedAt = snapshotData['processed_at'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('referrals');

  static Stream<ReferralsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ReferralsRecord.fromSnapshot(s));

  static Future<ReferralsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ReferralsRecord.fromSnapshot(s));

  static ReferralsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ReferralsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ReferralsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ReferralsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ReferralsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ReferralsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

class ReferralsRecordDocumentEquality implements Equality<ReferralsRecord> {
  const ReferralsRecordDocumentEquality();

  @override
  bool equals(ReferralsRecord? e1, ReferralsRecord? e2) {
    return e1?.code == e2?.code &&
        e1?.campaignRef == e2?.campaignRef &&
        e1?.referrerRef == e2?.referrerRef &&
        e1?.refereeRef == e2?.refereeRef &&
        e1?.region == e2?.region &&
        e1?.status == e2?.status &&
        e1?.rejectReason == e2?.rejectReason &&
        e1?.referrerPointsAwarded == e2?.referrerPointsAwarded &&
        e1?.refereePointsAwarded == e2?.refereePointsAwarded &&
        e1?.createdAt == e2?.createdAt &&
        e1?.processedAt == e2?.processedAt;
  }

  @override
  int hash(ReferralsRecord? e) => const ListEquality().hash([
        e?.code,
        e?.campaignRef,
        e?.referrerRef,
        e?.refereeRef,
        e?.region,
        e?.status,
        e?.rejectReason,
        e?.referrerPointsAwarded,
        e?.refereePointsAwarded,
        e?.createdAt,
        e?.processedAt,
      ]);

  @override
  bool isValidKey(Object? o) => o is ReferralsRecord;
}
