import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

// Top-level collection (not a users/{uid} subcollection) so it follows the
// same query helper pattern as every other record in this codebase; scoped
// per-user via the user_ref field instead.
class UnlockedRewardsRecord extends FirestoreRecord {
  UnlockedRewardsRecord._(
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

  // "reward_type" field. One of: POWER_HOUR, GLOWING_PIN,
  // TIER_FOUNDING_LOCAL, TIER_PRO_GROWTH, TIER_ELITE_GROWTH.
  String? _rewardType;
  String get rewardType => _rewardType ?? '';
  bool hasRewardType() => _rewardType != null;

  // "tier_unlocked" field.
  String? _tierUnlocked;
  String get tierUnlocked => _tierUnlocked ?? 'None';
  bool hasTierUnlocked() => _tierUnlocked != null;

  // "duration_months" field.
  int? _durationMonths;
  int get durationMonths => _durationMonths ?? 0;
  bool hasDurationMonths() => _durationMonths != null;

  // "date_won" field.
  DateTime? _dateWon;
  DateTime? get dateWon => _dateWon;
  bool hasDateWon() => _dateWon != null;

  // "expiration_date" field.
  DateTime? _expirationDate;
  DateTime? get expirationDate => _expirationDate;
  bool hasExpirationDate() => _expirationDate != null;

  // "is_redeemed" field.
  bool? _isRedeemed;
  bool get isRedeemed => _isRedeemed ?? false;
  bool hasIsRedeemed() => _isRedeemed != null;

  // "date_redeemed" field.
  DateTime? _dateRedeemed;
  DateTime? get dateRedeemed => _dateRedeemed;
  bool hasDateRedeemed() => _dateRedeemed != null;

  // "promo_code" field.
  String? _promoCode;
  String get promoCode => _promoCode ?? '';
  bool hasPromoCode() => _promoCode != null;

  // "reveal_animation_shown" field. Client-set once the scratch-off reveal
  // has played, so revisiting the dashboard doesn't replay it.
  bool? _revealAnimationShown;
  bool get revealAnimationShown => _revealAnimationShown ?? false;
  bool hasRevealAnimationShown() => _revealAnimationShown != null;

  void _initializeFields() {
    _userRef = snapshotData['user_ref'] as DocumentReference?;
    _businessRef = snapshotData['business_ref'] as DocumentReference?;
    _rewardType = snapshotData['reward_type'] as String?;
    _tierUnlocked = snapshotData['tier_unlocked'] as String?;
    _durationMonths = castToType<int>(snapshotData['duration_months']);
    _dateWon = snapshotData['date_won'] as DateTime?;
    _expirationDate = snapshotData['expiration_date'] as DateTime?;
    _isRedeemed = snapshotData['is_redeemed'] as bool?;
    _dateRedeemed = snapshotData['date_redeemed'] as DateTime?;
    _promoCode = snapshotData['promo_code'] as String?;
    _revealAnimationShown =
        snapshotData['reveal_animation_shown'] as bool?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('unlocked_rewards');

  static Stream<UnlockedRewardsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => UnlockedRewardsRecord.fromSnapshot(s));

  static Future<UnlockedRewardsRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => UnlockedRewardsRecord.fromSnapshot(s));

  static UnlockedRewardsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      UnlockedRewardsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static UnlockedRewardsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      UnlockedRewardsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'UnlockedRewardsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is UnlockedRewardsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createUnlockedRewardsRecordData({
  DocumentReference? userRef,
  DocumentReference? businessRef,
  String? rewardType,
  String? tierUnlocked,
  int? durationMonths,
  DateTime? dateWon,
  DateTime? expirationDate,
  bool? isRedeemed,
  DateTime? dateRedeemed,
  String? promoCode,
  bool? revealAnimationShown,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'user_ref': userRef,
      'business_ref': businessRef,
      'reward_type': rewardType,
      'tier_unlocked': tierUnlocked,
      'duration_months': durationMonths,
      'date_won': dateWon,
      'expiration_date': expirationDate,
      'is_redeemed': isRedeemed,
      'date_redeemed': dateRedeemed,
      'promo_code': promoCode,
      'reveal_animation_shown': revealAnimationShown,
    }.withoutNulls,
  );

  return firestoreData;
}

class UnlockedRewardsRecordDocumentEquality
    implements Equality<UnlockedRewardsRecord> {
  const UnlockedRewardsRecordDocumentEquality();

  @override
  bool equals(UnlockedRewardsRecord? e1, UnlockedRewardsRecord? e2) {
    return e1?.userRef == e2?.userRef &&
        e1?.businessRef == e2?.businessRef &&
        e1?.rewardType == e2?.rewardType &&
        e1?.tierUnlocked == e2?.tierUnlocked &&
        e1?.durationMonths == e2?.durationMonths &&
        e1?.dateWon == e2?.dateWon &&
        e1?.expirationDate == e2?.expirationDate &&
        e1?.isRedeemed == e2?.isRedeemed &&
        e1?.dateRedeemed == e2?.dateRedeemed &&
        e1?.promoCode == e2?.promoCode &&
        e1?.revealAnimationShown == e2?.revealAnimationShown;
  }

  @override
  int hash(UnlockedRewardsRecord? e) => const ListEquality().hash([
        e?.userRef,
        e?.businessRef,
        e?.rewardType,
        e?.tierUnlocked,
        e?.durationMonths,
        e?.dateWon,
        e?.expirationDate,
        e?.isRedeemed,
        e?.dateRedeemed,
        e?.promoCode,
        e?.revealAnimationShown,
      ]);

  @override
  bool isValidKey(Object? o) => o is UnlockedRewardsRecord;
}
