import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// One row per entity per day - see historyDocId in
/// kindex_scoring_dynamics.js. Read-only from the client: written only by
/// recomputeBusinessKindexScores / recomputeCustomerKindexScores (Admin
/// SDK, bypasses rules), and firestore.rules only grants read, scoped to
/// the business's own owner (entity_type == 'business') or the customer
/// themselves (entity_type == 'customer').
///
/// A single record class for both shapes rather than two, because they
/// share a collection and most fields (score_before/score_after/
/// target_score/capped/decay_applied/inactivity_weeks/recorded_at) - only
/// the "why" fields diverge, and entity_type is what a caller checks to
/// know which half of this record is populated.
class KindexScoreHistoryRecord extends FirestoreRecord {
  KindexScoreHistoryRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "entity_type" field. 'business' or 'customer'.
  String? _entityType;
  String get entityType => _entityType ?? '';
  bool hasEntityType() => _entityType != null;

  // "business_ref" field. Set only when entityType == 'business'.
  DocumentReference? _businessRef;
  DocumentReference? get businessRef => _businessRef;
  bool hasBusinessRef() => _businessRef != null;

  // "user_ref" field. Set only when entityType == 'customer'.
  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  // "score_before" field.
  double? _scoreBefore;
  double get scoreBefore => _scoreBefore ?? 0.0;
  bool hasScoreBefore() => _scoreBefore != null;

  // "score_after" field.
  double? _scoreAfter;
  double get scoreAfter => _scoreAfter ?? 0.0;
  bool hasScoreAfter() => _scoreAfter != null;

  // "target_score" field.
  double? _targetScore;
  double get targetScore => _targetScore ?? 0.0;
  bool hasTargetScore() => _targetScore != null;

  // "capped" field. True when the tier ceiling clipped the day's movement
  // short of target_score.
  bool? _capped;
  bool get capped => _capped ?? false;
  bool hasCapped() => _capped != null;

  // "decay_applied" field. Points lost to inactivity this run, 0 on an
  // active day.
  double? _decayApplied;
  double get decayApplied => _decayApplied ?? 0.0;
  bool hasDecayApplied() => _decayApplied != null;

  // "inactivity_weeks" field.
  int? _inactivityWeeks;
  int get inactivityWeeks => _inactivityWeeks ?? 0;
  bool hasInactivityWeeks() => _inactivityWeeks != null;

  // "qualifying_review_count" field. Business side only.
  int? _qualifyingReviewCount;
  int get qualifyingReviewCount => _qualifyingReviewCount ?? 0;
  bool hasQualifyingReviewCount() => _qualifyingReviewCount != null;

  // "verified_visit_count" field. Business side only.
  int? _verifiedVisitCount;
  int get verifiedVisitCount => _verifiedVisitCount ?? 0;
  bool hasVerifiedVisitCount() => _verifiedVisitCount != null;

  // "active_poster_bonus_applied" field. Business side only.
  bool? _activePosterBonusApplied;
  bool get activePosterBonusApplied => _activePosterBonusApplied ?? false;
  bool hasActivePosterBonusApplied() => _activePosterBonusApplied != null;

  // "active_poster_days" field. Business side only.
  int? _activePosterDays;
  int get activePosterDays => _activePosterDays ?? 0;
  bool hasActivePosterDays() => _activePosterDays != null;

  // "active_poster_bonus_points" field. Business side only.
  double? _activePosterBonusPoints;
  double get activePosterBonusPoints => _activePosterBonusPoints ?? 0.0;
  bool hasActivePosterBonusPoints() => _activePosterBonusPoints != null;

  // "qualifying_event_count" field. Customer side only.
  int? _qualifyingEventCount;
  int get qualifyingEventCount => _qualifyingEventCount ?? 0;
  bool hasQualifyingEventCount() => _qualifyingEventCount != null;

  // "distinct_businesses_engaged" field. Customer side only.
  int? _distinctBusinessesEngaged;
  int get distinctBusinessesEngaged => _distinctBusinessesEngaged ?? 0;
  bool hasDistinctBusinessesEngaged() => _distinctBusinessesEngaged != null;

  // "recorded_at" field.
  DateTime? _recordedAt;
  DateTime? get recordedAt => _recordedAt;
  bool hasRecordedAt() => _recordedAt != null;

  void _initializeFields() {
    _entityType = snapshotData['entity_type'] as String?;
    _businessRef = snapshotData['business_ref'] as DocumentReference?;
    _userRef = snapshotData['user_ref'] as DocumentReference?;
    _scoreBefore = castToType<double>(snapshotData['score_before']);
    _scoreAfter = castToType<double>(snapshotData['score_after']);
    _targetScore = castToType<double>(snapshotData['target_score']);
    _capped = snapshotData['capped'] as bool?;
    _decayApplied = castToType<double>(snapshotData['decay_applied']);
    _inactivityWeeks = castToType<int>(snapshotData['inactivity_weeks']);
    _qualifyingReviewCount =
        castToType<int>(snapshotData['qualifying_review_count']);
    _verifiedVisitCount =
        castToType<int>(snapshotData['verified_visit_count']);
    _activePosterBonusApplied =
        snapshotData['active_poster_bonus_applied'] as bool?;
    _activePosterDays = castToType<int>(snapshotData['active_poster_days']);
    _activePosterBonusPoints =
        castToType<double>(snapshotData['active_poster_bonus_points']);
    _qualifyingEventCount =
        castToType<int>(snapshotData['qualifying_event_count']);
    _distinctBusinessesEngaged =
        castToType<int>(snapshotData['distinct_businesses_engaged']);
    _recordedAt = snapshotData['recorded_at'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('kindex_score_history');

  static Stream<KindexScoreHistoryRecord> getDocument(
          DocumentReference ref) =>
      ref.snapshots().map((s) => KindexScoreHistoryRecord.fromSnapshot(s));

  static Future<KindexScoreHistoryRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => KindexScoreHistoryRecord.fromSnapshot(s));

  static KindexScoreHistoryRecord fromSnapshot(DocumentSnapshot snapshot) =>
      KindexScoreHistoryRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static KindexScoreHistoryRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      KindexScoreHistoryRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'KindexScoreHistoryRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is KindexScoreHistoryRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

class KindexScoreHistoryRecordDocumentEquality
    implements Equality<KindexScoreHistoryRecord> {
  const KindexScoreHistoryRecordDocumentEquality();

  @override
  bool equals(KindexScoreHistoryRecord? e1, KindexScoreHistoryRecord? e2) {
    return e1?.entityType == e2?.entityType &&
        e1?.businessRef == e2?.businessRef &&
        e1?.userRef == e2?.userRef &&
        e1?.scoreBefore == e2?.scoreBefore &&
        e1?.scoreAfter == e2?.scoreAfter &&
        e1?.targetScore == e2?.targetScore &&
        e1?.capped == e2?.capped &&
        e1?.decayApplied == e2?.decayApplied &&
        e1?.inactivityWeeks == e2?.inactivityWeeks &&
        e1?.qualifyingReviewCount == e2?.qualifyingReviewCount &&
        e1?.verifiedVisitCount == e2?.verifiedVisitCount &&
        e1?.activePosterBonusApplied == e2?.activePosterBonusApplied &&
        e1?.activePosterDays == e2?.activePosterDays &&
        e1?.activePosterBonusPoints == e2?.activePosterBonusPoints &&
        e1?.qualifyingEventCount == e2?.qualifyingEventCount &&
        e1?.distinctBusinessesEngaged == e2?.distinctBusinessesEngaged &&
        e1?.recordedAt == e2?.recordedAt;
  }

  @override
  int hash(KindexScoreHistoryRecord? e) => const ListEquality().hash([
        e?.entityType,
        e?.businessRef,
        e?.userRef,
        e?.scoreBefore,
        e?.scoreAfter,
        e?.targetScore,
        e?.capped,
        e?.decayApplied,
        e?.inactivityWeeks,
        e?.qualifyingReviewCount,
        e?.verifiedVisitCount,
        e?.activePosterBonusApplied,
        e?.activePosterDays,
        e?.activePosterBonusPoints,
        e?.qualifyingEventCount,
        e?.distinctBusinessesEngaged,
        e?.recordedAt,
      ]);

  @override
  bool isValidKey(Object? o) => o is KindexScoreHistoryRecord;
}
