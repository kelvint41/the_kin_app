import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class PrestigePointsRecord extends FirestoreRecord {
  PrestigePointsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "kindex_score" field.
  int? _kindexScore;
  int get kindexScore => _kindexScore ?? 0;
  bool hasKindexScore() => _kindexScore != null;

  // "display_name" field.
  String? _displayName;
  String get displayName => _displayName ?? '';
  bool hasDisplayName() => _displayName != null;

  // "is_business" field.
  bool? _isBusiness;
  bool get isBusiness => _isBusiness ?? false;
  bool hasIsBusiness() => _isBusiness != null;

  // "entity_ref" field.
  String? _entityRef;
  String get entityRef => _entityRef ?? '';
  bool hasEntityRef() => _entityRef != null;

  // "location_city" field.
  String? _locationCity;
  String get locationCity => _locationCity ?? '';
  bool hasLocationCity() => _locationCity != null;

  // "profile_pic_url" field.
  String? _profilePicUrl;
  String get profilePicUrl => _profilePicUrl ?? '';
  bool hasProfilePicUrl() => _profilePicUrl != null;

  // "level" field.
  int? _level;
  int get level => _level ?? 0;
  bool hasLevel() => _level != null;

  // "badge_name" field.
  String? _badgeName;
  String get badgeName => _badgeName ?? '';
  bool hasBadgeName() => _badgeName != null;

  // "reviews_count" field.
  int? _reviewsCount;
  int get reviewsCount => _reviewsCount ?? 0;
  bool hasReviewsCount() => _reviewsCount != null;

  // "checkins_count" field.
  int? _checkinsCount;
  int get checkinsCount => _checkinsCount ?? 0;
  bool hasCheckinsCount() => _checkinsCount != null;

  // "businesses_supported_count" field.
  int? _businessesSupportedCount;
  int get businessesSupportedCount => _businessesSupportedCount ?? 0;
  bool hasBusinessesSupportedCount() => _businessesSupportedCount != null;

  // "current_tier" field.
  String? _currentTier;
  String get currentTier => _currentTier ?? '';
  bool hasCurrentTier() => _currentTier != null;

  void _initializeFields() {
    _kindexScore = castToType<int>(snapshotData['kindex_score']);
    _displayName = snapshotData['display_name'] as String?;
    _isBusiness = snapshotData['is_business'] as bool?;
    _entityRef = snapshotData['entity_ref'] as String?;
    _locationCity = snapshotData['location_city'] as String?;
    _profilePicUrl = snapshotData['profile_pic_url'] as String?;
    _level = castToType<int>(snapshotData['level']);
    _badgeName = snapshotData['badge_name'] as String?;
    _reviewsCount = castToType<int>(snapshotData['reviews_count']);
    _checkinsCount = castToType<int>(snapshotData['checkins_count']);
    _businessesSupportedCount =
        castToType<int>(snapshotData['businesses_supported_count']);
    _currentTier = snapshotData['current_tier'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('prestige_points');

  static Stream<PrestigePointsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => PrestigePointsRecord.fromSnapshot(s));

  static Future<PrestigePointsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => PrestigePointsRecord.fromSnapshot(s));

  static PrestigePointsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      PrestigePointsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static PrestigePointsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      PrestigePointsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'PrestigePointsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is PrestigePointsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createPrestigePointsRecordData({
  int? kindexScore,
  String? displayName,
  bool? isBusiness,
  String? entityRef,
  String? locationCity,
  String? profilePicUrl,
  int? level,
  String? badgeName,
  int? reviewsCount,
  int? checkinsCount,
  int? businessesSupportedCount,
  String? currentTier,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'kindex_score': kindexScore,
      'display_name': displayName,
      'is_business': isBusiness,
      'entity_ref': entityRef,
      'location_city': locationCity,
      'profile_pic_url': profilePicUrl,
      'level': level,
      'badge_name': badgeName,
      'reviews_count': reviewsCount,
      'checkins_count': checkinsCount,
      'businesses_supported_count': businessesSupportedCount,
      'current_tier': currentTier,
    }.withoutNulls,
  );

  return firestoreData;
}

class PrestigePointsRecordDocumentEquality
    implements Equality<PrestigePointsRecord> {
  const PrestigePointsRecordDocumentEquality();

  @override
  bool equals(PrestigePointsRecord? e1, PrestigePointsRecord? e2) {
    return e1?.kindexScore == e2?.kindexScore &&
        e1?.displayName == e2?.displayName &&
        e1?.isBusiness == e2?.isBusiness &&
        e1?.entityRef == e2?.entityRef &&
        e1?.locationCity == e2?.locationCity &&
        e1?.profilePicUrl == e2?.profilePicUrl &&
        e1?.level == e2?.level &&
        e1?.badgeName == e2?.badgeName &&
        e1?.reviewsCount == e2?.reviewsCount &&
        e1?.checkinsCount == e2?.checkinsCount &&
        e1?.businessesSupportedCount == e2?.businessesSupportedCount &&
        e1?.currentTier == e2?.currentTier;
  }

  @override
  int hash(PrestigePointsRecord? e) => const ListEquality().hash([
        e?.kindexScore,
        e?.displayName,
        e?.isBusiness,
        e?.entityRef,
        e?.locationCity,
        e?.profilePicUrl,
        e?.level,
        e?.badgeName,
        e?.reviewsCount,
        e?.checkinsCount,
        e?.businessesSupportedCount,
        e?.currentTier
      ]);

  @override
  bool isValidKey(Object? o) => o is PrestigePointsRecord;
}
