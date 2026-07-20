import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class MarketingCampaignsRecord extends FirestoreRecord {
  MarketingCampaignsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "title" field.
  String? _title;
  String get title => _title ?? '';
  bool hasTitle() => _title != null;

  // "description" field.
  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  // "owner_ref" field.
  DocumentReference? _ownerRef;
  DocumentReference? get ownerRef => _ownerRef;
  bool hasOwnerRef() => _ownerRef != null;

  // "business_ref" field.
  DocumentReference? _businessRef;
  DocumentReference? get businessRef => _businessRef;
  bool hasBusinessRef() => _businessRef != null;

  // "type" field.
  String? _type;
  String get type => _type ?? '';
  bool hasType() => _type != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  // "target_regions" field.
  List<String>? _targetRegions;
  List<String> get targetRegions => _targetRegions ?? const [];
  bool hasTargetRegions() => _targetRegions != null;

  // "default_region" field.
  String? _defaultRegion;
  String get defaultRegion => _defaultRegion ?? '';
  bool hasDefaultRegion() => _defaultRegion != null;

  // "start_date" field.
  DateTime? _startDate;
  DateTime? get startDate => _startDate;
  bool hasStartDate() => _startDate != null;

  // "end_date" field.
  DateTime? _endDate;
  DateTime? get endDate => _endDate;
  bool hasEndDate() => _endDate != null;

  // "referral_reward_tier" field.
  String? _referralRewardTier;
  String get referralRewardTier => _referralRewardTier ?? '';
  bool hasReferralRewardTier() => _referralRewardTier != null;

  // "referral_reward_days" field.
  int? _referralRewardDays;
  int get referralRewardDays => _referralRewardDays ?? 0;
  bool hasReferralRewardDays() => _referralRewardDays != null;

  // "max_referrals_per_user" field.
  int? _maxReferralsPerUser;
  int get maxReferralsPerUser => _maxReferralsPerUser ?? 0;
  bool hasMaxReferralsPerUser() => _maxReferralsPerUser != null;

  // "referral_count" field.
  int? _referralCount;
  int get referralCount => _referralCount ?? 0;
  bool hasReferralCount() => _referralCount != null;

  // "qualified_referral_count" field.
  int? _qualifiedReferralCount;
  int get qualifiedReferralCount => _qualifiedReferralCount ?? 0;
  bool hasQualifiedReferralCount() => _qualifiedReferralCount != null;

  // "reward_granted_count" field.
  int? _rewardGrantedCount;
  int get rewardGrantedCount => _rewardGrantedCount ?? 0;
  bool hasRewardGrantedCount() => _rewardGrantedCount != null;

  // "impression_count" field.
  int? _impressionCount;
  int get impressionCount => _impressionCount ?? 0;
  bool hasImpressionCount() => _impressionCount != null;

  // "click_count" field.
  int? _clickCount;
  int get clickCount => _clickCount ?? 0;
  bool hasClickCount() => _clickCount != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "updated_at" field.
  DateTime? _updatedAt;
  DateTime? get updatedAt => _updatedAt;
  bool hasUpdatedAt() => _updatedAt != null;

  void _initializeFields() {
    _title = snapshotData['title'] as String?;
    _description = snapshotData['description'] as String?;
    _ownerRef = snapshotData['owner_ref'] as DocumentReference?;
    _businessRef = snapshotData['business_ref'] as DocumentReference?;
    _type = snapshotData['type'] as String?;
    _status = snapshotData['status'] as String?;
    _targetRegions = getDataList(snapshotData['target_regions']);
    _defaultRegion = snapshotData['default_region'] as String?;
    _startDate = snapshotData['start_date'] as DateTime?;
    _endDate = snapshotData['end_date'] as DateTime?;
    _referralRewardTier = snapshotData['referral_reward_tier'] as String?;
    _referralRewardDays = castToType<int>(snapshotData['referral_reward_days']);
    _maxReferralsPerUser =
        castToType<int>(snapshotData['max_referrals_per_user']);
    _referralCount = castToType<int>(snapshotData['referral_count']);
    _qualifiedReferralCount =
        castToType<int>(snapshotData['qualified_referral_count']);
    _rewardGrantedCount =
        castToType<int>(snapshotData['reward_granted_count']);
    _impressionCount = castToType<int>(snapshotData['impression_count']);
    _clickCount = castToType<int>(snapshotData['click_count']);
    _createdAt = snapshotData['created_at'] as DateTime?;
    _updatedAt = snapshotData['updated_at'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('marketing_campaigns');

  static Stream<MarketingCampaignsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => MarketingCampaignsRecord.fromSnapshot(s));

  static Future<MarketingCampaignsRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => MarketingCampaignsRecord.fromSnapshot(s));

  static MarketingCampaignsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      MarketingCampaignsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static MarketingCampaignsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      MarketingCampaignsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'MarketingCampaignsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is MarketingCampaignsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createMarketingCampaignsRecordData({
  String? title,
  String? description,
  DocumentReference? ownerRef,
  DocumentReference? businessRef,
  String? type,
  String? status,
  String? defaultRegion,
  DateTime? startDate,
  DateTime? endDate,
  String? referralRewardTier,
  int? referralRewardDays,
  int? maxReferralsPerUser,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'title': title,
      'description': description,
      'owner_ref': ownerRef,
      'business_ref': businessRef,
      'type': type,
      'status': status,
      'default_region': defaultRegion,
      'start_date': startDate,
      'end_date': endDate,
      'referral_reward_tier': referralRewardTier,
      'referral_reward_days': referralRewardDays,
      'max_referrals_per_user': maxReferralsPerUser,
      'created_at': createdAt,
      'updated_at': updatedAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class MarketingCampaignsRecordDocumentEquality
    implements Equality<MarketingCampaignsRecord> {
  const MarketingCampaignsRecordDocumentEquality();

  @override
  bool equals(MarketingCampaignsRecord? e1, MarketingCampaignsRecord? e2) {
    const listEquality = ListEquality();
    return e1?.title == e2?.title &&
        e1?.description == e2?.description &&
        e1?.ownerRef == e2?.ownerRef &&
        e1?.businessRef == e2?.businessRef &&
        e1?.type == e2?.type &&
        e1?.status == e2?.status &&
        listEquality.equals(e1?.targetRegions, e2?.targetRegions) &&
        e1?.defaultRegion == e2?.defaultRegion &&
        e1?.startDate == e2?.startDate &&
        e1?.endDate == e2?.endDate &&
        e1?.referralRewardTier == e2?.referralRewardTier &&
        e1?.referralRewardDays == e2?.referralRewardDays &&
        e1?.maxReferralsPerUser == e2?.maxReferralsPerUser &&
        e1?.referralCount == e2?.referralCount &&
        e1?.qualifiedReferralCount == e2?.qualifiedReferralCount &&
        e1?.rewardGrantedCount == e2?.rewardGrantedCount &&
        e1?.impressionCount == e2?.impressionCount &&
        e1?.clickCount == e2?.clickCount &&
        e1?.createdAt == e2?.createdAt &&
        e1?.updatedAt == e2?.updatedAt;
  }

  @override
  int hash(MarketingCampaignsRecord? e) => const ListEquality().hash([
        e?.title,
        e?.description,
        e?.ownerRef,
        e?.businessRef,
        e?.type,
        e?.status,
        e?.targetRegions,
        e?.defaultRegion,
        e?.startDate,
        e?.endDate,
        e?.referralRewardTier,
        e?.referralRewardDays,
        e?.maxReferralsPerUser,
        e?.referralCount,
        e?.qualifiedReferralCount,
        e?.rewardGrantedCount,
        e?.impressionCount,
        e?.clickCount,
        e?.createdAt,
        e?.updatedAt,
      ]);

  @override
  bool isValidKey(Object? o) => o is MarketingCampaignsRecord;
}
