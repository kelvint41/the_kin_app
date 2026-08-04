import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// A "Daily Founder Topic" prompt shown pinned above The Exchange feed.
///
/// activeDate scopes a prompt to a specific calendar day - the banner
/// queries for whichever doc's activeDate falls on today, admin-curated
/// one doc at a time rather than an auto-rotating pool for v1. pinned is a
/// separate, date-independent override: when today has no activeDate
/// match (a gap in the admin's schedule, or none written yet), the banner
/// falls back to the most recent pinned==true doc instead of showing
/// nothing - an evergreen prompt an admin can leave up indefinitely.
class ExchangePromptsRecord extends FirestoreRecord {
  ExchangePromptsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "text" field.
  String? _text;
  String get text => _text ?? '';
  bool hasText() => _text != null;

  // "active_date" field.
  DateTime? _activeDate;
  DateTime? get activeDate => _activeDate;
  bool hasActiveDate() => _activeDate != null;

  // "pinned" field.
  bool? _pinned;
  bool get pinned => _pinned ?? false;
  bool hasPinned() => _pinned != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  void _initializeFields() {
    _text = snapshotData['text'] as String?;
    _activeDate = snapshotData['active_date'] as DateTime?;
    _pinned = snapshotData['pinned'] as bool?;
    _createdAt = snapshotData['created_at'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('exchange_prompts');

  static Stream<ExchangePromptsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ExchangePromptsRecord.fromSnapshot(s));

  static Future<ExchangePromptsRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => ExchangePromptsRecord.fromSnapshot(s));

  static ExchangePromptsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ExchangePromptsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ExchangePromptsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ExchangePromptsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ExchangePromptsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ExchangePromptsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createExchangePromptsRecordData({
  String? text,
  DateTime? activeDate,
  bool? pinned,
  DateTime? createdAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'text': text,
      'active_date': activeDate,
      'pinned': pinned,
      'created_at': createdAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class ExchangePromptsRecordDocumentEquality
    implements Equality<ExchangePromptsRecord> {
  const ExchangePromptsRecordDocumentEquality();

  @override
  bool equals(ExchangePromptsRecord? e1, ExchangePromptsRecord? e2) {
    return e1?.text == e2?.text &&
        e1?.activeDate == e2?.activeDate &&
        e1?.pinned == e2?.pinned &&
        e1?.createdAt == e2?.createdAt;
  }

  @override
  int hash(ExchangePromptsRecord? e) => const ListEquality().hash(
      [e?.text, e?.activeDate, e?.pinned, e?.createdAt]);

  @override
  bool isValidKey(Object? o) => o is ExchangePromptsRecord;
}
