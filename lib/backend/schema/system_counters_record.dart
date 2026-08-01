import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

// One doc per calendar year, id = year as string (e.g. "2026"). Tracks
// nationwide reward caps that must hold across every generateMysteryReward
// invocation, not just per-business state.
class SystemCountersRecord extends FirestoreRecord {
  SystemCountersRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "elite_growth_rewards_granted" field.
  int? _eliteGrowthRewardsGranted;
  int get eliteGrowthRewardsGranted => _eliteGrowthRewardsGranted ?? 0;
  bool hasEliteGrowthRewardsGranted() => _eliteGrowthRewardsGranted != null;

  void _initializeFields() {
    _eliteGrowthRewardsGranted =
        castToType<int>(snapshotData['elite_growth_rewards_granted']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('system_counters');

  static Stream<SystemCountersRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => SystemCountersRecord.fromSnapshot(s));

  static Future<SystemCountersRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => SystemCountersRecord.fromSnapshot(s));

  static SystemCountersRecord fromSnapshot(DocumentSnapshot snapshot) =>
      SystemCountersRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static SystemCountersRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      SystemCountersRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'SystemCountersRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is SystemCountersRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createSystemCountersRecordData({
  int? eliteGrowthRewardsGranted,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'elite_growth_rewards_granted': eliteGrowthRewardsGranted,
    }.withoutNulls,
  );

  return firestoreData;
}

class SystemCountersRecordDocumentEquality
    implements Equality<SystemCountersRecord> {
  const SystemCountersRecordDocumentEquality();

  @override
  bool equals(SystemCountersRecord? e1, SystemCountersRecord? e2) {
    return e1?.eliteGrowthRewardsGranted == e2?.eliteGrowthRewardsGranted;
  }

  @override
  int hash(SystemCountersRecord? e) =>
      const ListEquality().hash([e?.eliteGrowthRewardsGranted]);

  @override
  bool isValidKey(Object? o) => o is SystemCountersRecord;
}
