import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class EntitlementsRecord extends FirestoreRecord {
  EntitlementsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "tier" field.
  String? _tier;
  String get tier => _tier ?? '';
  bool hasTier() => _tier != null;

  // "source" field.
  String? _source;
  String get source => _source ?? '';
  bool hasSource() => _source != null;

  // "granted_reason" field.
  String? _grantedReason;
  String get grantedReason => _grantedReason ?? '';
  bool hasGrantedReason() => _grantedReason != null;

  // "granted_at" field.
  DateTime? _grantedAt;
  DateTime? get grantedAt => _grantedAt;
  bool hasGrantedAt() => _grantedAt != null;

  // "expires_at" field.
  DateTime? _expiresAt;
  DateTime? get expiresAt => _expiresAt;
  bool hasExpiresAt() => _expiresAt != null;

  void _initializeFields() {
    _tier = snapshotData['tier'] as String?;
    _source = snapshotData['source'] as String?;
    _grantedReason = snapshotData['granted_reason'] as String?;
    _grantedAt = snapshotData['granted_at'] as DateTime?;
    _expiresAt = snapshotData['expires_at'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('entitlements');

  static Stream<EntitlementsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => EntitlementsRecord.fromSnapshot(s));

  static Future<EntitlementsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => EntitlementsRecord.fromSnapshot(s));

  static EntitlementsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      EntitlementsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static EntitlementsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      EntitlementsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'EntitlementsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is EntitlementsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createEntitlementsRecordData({
  String? tier,
  String? source,
  String? grantedReason,
  DateTime? grantedAt,
  DateTime? expiresAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'tier': tier,
      'source': source,
      'granted_reason': grantedReason,
      'granted_at': grantedAt,
      'expires_at': expiresAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class EntitlementsRecordDocumentEquality
    implements Equality<EntitlementsRecord> {
  const EntitlementsRecordDocumentEquality();

  @override
  bool equals(EntitlementsRecord? e1, EntitlementsRecord? e2) {
    return e1?.tier == e2?.tier &&
        e1?.source == e2?.source &&
        e1?.grantedReason == e2?.grantedReason &&
        e1?.grantedAt == e2?.grantedAt &&
        e1?.expiresAt == e2?.expiresAt;
  }

  @override
  int hash(EntitlementsRecord? e) => const ListEquality()
      .hash([e?.tier, e?.source, e?.grantedReason, e?.grantedAt, e?.expiresAt]);

  @override
  bool isValidKey(Object? o) => o is EntitlementsRecord;
}
