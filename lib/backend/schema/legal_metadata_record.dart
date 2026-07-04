import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class LegalMetadataRecord extends FirestoreRecord {
  LegalMetadataRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "privacy_polic_updated" field.
  DateTime? _privacyPolicUpdated;
  DateTime? get privacyPolicUpdated => _privacyPolicUpdated;
  bool hasPrivacyPolicUpdated() => _privacyPolicUpdated != null;

  void _initializeFields() {
    _privacyPolicUpdated = snapshotData['privacy_polic_updated'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('legal_metadata');

  static Stream<LegalMetadataRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => LegalMetadataRecord.fromSnapshot(s));

  static Future<LegalMetadataRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => LegalMetadataRecord.fromSnapshot(s));

  static LegalMetadataRecord fromSnapshot(DocumentSnapshot snapshot) =>
      LegalMetadataRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static LegalMetadataRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      LegalMetadataRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'LegalMetadataRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is LegalMetadataRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createLegalMetadataRecordData({
  DateTime? privacyPolicUpdated,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'privacy_polic_updated': privacyPolicUpdated,
    }.withoutNulls,
  );

  return firestoreData;
}

class LegalMetadataRecordDocumentEquality
    implements Equality<LegalMetadataRecord> {
  const LegalMetadataRecordDocumentEquality();

  @override
  bool equals(LegalMetadataRecord? e1, LegalMetadataRecord? e2) {
    return e1?.privacyPolicUpdated == e2?.privacyPolicUpdated;
  }

  @override
  int hash(LegalMetadataRecord? e) =>
      const ListEquality().hash([e?.privacyPolicUpdated]);

  @override
  bool isValidKey(Object? o) => o is LegalMetadataRecord;
}
