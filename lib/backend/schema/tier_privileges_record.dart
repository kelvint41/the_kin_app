import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class TierPrivilegesRecord extends FirestoreRecord {
  TierPrivilegesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "business_ref" field.
  DocumentReference? _businessRef;
  DocumentReference? get businessRef => _businessRef;
  bool hasBusinessRef() => _businessRef != null;

  // "subscription_tier" field.
  String? _subscriptionTier;
  String get subscriptionTier => _subscriptionTier ?? '';
  bool hasSubscriptionTier() => _subscriptionTier != null;

  // "is_premium" field.
  bool? _isPremium;
  bool get isPremium => _isPremium ?? false;
  bool hasIsPremium() => _isPremium != null;

  // "is_priority_pinned" field.
  bool? _isPriorityPinned;
  bool get isPriorityPinned => _isPriorityPinned ?? false;
  bool hasIsPriorityPinned() => _isPriorityPinned != null;

  // "has_flash_beacon" field.
  bool? _hasFlashBeacon;
  bool get hasFlashBeacon => _hasFlashBeacon ?? false;
  bool hasHasFlashBeacon() => _hasFlashBeacon != null;

  // "owner_id" field.
  String? _ownerId;
  String get ownerId => _ownerId ?? '';
  bool hasOwnerId() => _ownerId != null;

  void _initializeFields() {
    _businessRef = snapshotData['business_ref'] as DocumentReference?;
    _subscriptionTier = snapshotData['subscription_tier'] as String?;
    _isPremium = snapshotData['is_premium'] as bool?;
    _isPriorityPinned = snapshotData['is_priority_pinned'] as bool?;
    _hasFlashBeacon = snapshotData['has_flash_beacon'] as bool?;
    _ownerId = snapshotData['owner_id'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('tier_privileges');

  static Stream<TierPrivilegesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => TierPrivilegesRecord.fromSnapshot(s));

  static Future<TierPrivilegesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => TierPrivilegesRecord.fromSnapshot(s));

  static TierPrivilegesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      TierPrivilegesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static TierPrivilegesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      TierPrivilegesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'TierPrivilegesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is TierPrivilegesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createTierPrivilegesRecordData({
  DocumentReference? businessRef,
  String? subscriptionTier,
  bool? isPremium,
  bool? isPriorityPinned,
  bool? hasFlashBeacon,
  String? ownerId,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'business_ref': businessRef,
      'subscription_tier': subscriptionTier,
      'is_premium': isPremium,
      'is_priority_pinned': isPriorityPinned,
      'has_flash_beacon': hasFlashBeacon,
      'owner_id': ownerId,
    }.withoutNulls,
  );

  return firestoreData;
}

class TierPrivilegesRecordDocumentEquality
    implements Equality<TierPrivilegesRecord> {
  const TierPrivilegesRecordDocumentEquality();

  @override
  bool equals(TierPrivilegesRecord? e1, TierPrivilegesRecord? e2) {
    return e1?.businessRef == e2?.businessRef &&
        e1?.subscriptionTier == e2?.subscriptionTier &&
        e1?.isPremium == e2?.isPremium &&
        e1?.isPriorityPinned == e2?.isPriorityPinned &&
        e1?.hasFlashBeacon == e2?.hasFlashBeacon &&
        e1?.ownerId == e2?.ownerId;
  }

  @override
  int hash(TierPrivilegesRecord? e) => const ListEquality().hash([
        e?.businessRef,
        e?.subscriptionTier,
        e?.isPremium,
        e?.isPriorityPinned,
        e?.hasFlashBeacon,
        e?.ownerId
      ]);

  @override
  bool isValidKey(Object? o) => o is TierPrivilegesRecord;
}
