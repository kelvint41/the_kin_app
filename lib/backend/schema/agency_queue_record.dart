import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AgencyQueueRecord extends FirestoreRecord {
  AgencyQueueRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "project_id" field.
  String? _projectId;
  String get projectId => _projectId ?? '';
  bool hasProjectId() => _projectId != null;

  // "business_name" field.
  String? _businessName;
  String get businessName => _businessName ?? '';
  bool hasBusinessName() => _businessName != null;

  // "project_type" field.
  String? _projectType;
  String get projectType => _projectType ?? '';
  bool hasProjectType() => _projectType != null;

  // "tier_level" field.
  String? _tierLevel;
  String get tierLevel => _tierLevel ?? '';
  bool hasTierLevel() => _tierLevel != null;

  // "current_status" field.
  String? _currentStatus;
  String get currentStatus => _currentStatus ?? '';
  bool hasCurrentStatus() => _currentStatus != null;

  // "current_step" field.
  int? _currentStep;
  int get currentStep => _currentStep ?? 0;
  bool hasCurrentStep() => _currentStep != null;

  // "target_delivery_date" field.
  DateTime? _targetDeliveryDate;
  DateTime? get targetDeliveryDate => _targetDeliveryDate;
  bool hasTargetDeliveryDate() => _targetDeliveryDate != null;

  // "assigned_editor" field.
  String? _assignedEditor;
  String get assignedEditor => _assignedEditor ?? '';
  bool hasAssignedEditor() => _assignedEditor != null;

  void _initializeFields() {
    _projectId = snapshotData['project_id'] as String?;
    _businessName = snapshotData['business_name'] as String?;
    _projectType = snapshotData['project_type'] as String?;
    _tierLevel = snapshotData['tier_level'] as String?;
    _currentStatus = snapshotData['current_status'] as String?;
    _currentStep = castToType<int>(snapshotData['current_step']);
    _targetDeliveryDate = snapshotData['target_delivery_date'] as DateTime?;
    _assignedEditor = snapshotData['assigned_editor'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('agency_queue');

  static Stream<AgencyQueueRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => AgencyQueueRecord.fromSnapshot(s));

  static Future<AgencyQueueRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => AgencyQueueRecord.fromSnapshot(s));

  static AgencyQueueRecord fromSnapshot(DocumentSnapshot snapshot) =>
      AgencyQueueRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static AgencyQueueRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      AgencyQueueRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'AgencyQueueRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is AgencyQueueRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createAgencyQueueRecordData({
  String? projectId,
  String? businessName,
  String? projectType,
  String? tierLevel,
  String? currentStatus,
  int? currentStep,
  DateTime? targetDeliveryDate,
  String? assignedEditor,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'project_id': projectId,
      'business_name': businessName,
      'project_type': projectType,
      'tier_level': tierLevel,
      'current_status': currentStatus,
      'current_step': currentStep,
      'target_delivery_date': targetDeliveryDate,
      'assigned_editor': assignedEditor,
    }.withoutNulls,
  );

  return firestoreData;
}

class AgencyQueueRecordDocumentEquality implements Equality<AgencyQueueRecord> {
  const AgencyQueueRecordDocumentEquality();

  @override
  bool equals(AgencyQueueRecord? e1, AgencyQueueRecord? e2) {
    return e1?.projectId == e2?.projectId &&
        e1?.businessName == e2?.businessName &&
        e1?.projectType == e2?.projectType &&
        e1?.tierLevel == e2?.tierLevel &&
        e1?.currentStatus == e2?.currentStatus &&
        e1?.currentStep == e2?.currentStep &&
        e1?.targetDeliveryDate == e2?.targetDeliveryDate &&
        e1?.assignedEditor == e2?.assignedEditor;
  }

  @override
  int hash(AgencyQueueRecord? e) => const ListEquality().hash([
        e?.projectId,
        e?.businessName,
        e?.projectType,
        e?.tierLevel,
        e?.currentStatus,
        e?.currentStep,
        e?.targetDeliveryDate,
        e?.assignedEditor
      ]);

  @override
  bool isValidKey(Object? o) => o is AgencyQueueRecord;
}
