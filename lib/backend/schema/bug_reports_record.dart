import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class BugReportsRecord extends FirestoreRecord {
  BugReportsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "tester_name" field.
  String? _testerName;
  String get testerName => _testerName ?? '';
  bool hasTesterName() => _testerName != null;

  // "issue_description" field.
  String? _issueDescription;
  String get issueDescription => _issueDescription ?? '';
  bool hasIssueDescription() => _issueDescription != null;

  // "page_where_it_happened" field.
  String? _pageWhereItHappened;
  String get pageWhereItHappened => _pageWhereItHappened ?? '';
  bool hasPageWhereItHappened() => _pageWhereItHappened != null;

  // "timestamp" field.
  DateTime? _timestamp;
  DateTime? get timestamp => _timestamp;
  bool hasTimestamp() => _timestamp != null;

  // "feedback_type" field.
  String? _feedbackType;
  String get feedbackType => _feedbackType ?? '';
  bool hasFeedbackType() => _feedbackType != null;

  void _initializeFields() {
    _testerName = snapshotData['tester_name'] as String?;
    _issueDescription = snapshotData['issue_description'] as String?;
    _pageWhereItHappened = snapshotData['page_where_it_happened'] as String?;
    _timestamp = snapshotData['timestamp'] as DateTime?;
    _feedbackType = snapshotData['feedback_type'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('bug_reports');

  static Stream<BugReportsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => BugReportsRecord.fromSnapshot(s));

  static Future<BugReportsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => BugReportsRecord.fromSnapshot(s));

  static BugReportsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      BugReportsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static BugReportsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      BugReportsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'BugReportsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is BugReportsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createBugReportsRecordData({
  String? testerName,
  String? issueDescription,
  String? pageWhereItHappened,
  DateTime? timestamp,
  String? feedbackType,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'tester_name': testerName,
      'issue_description': issueDescription,
      'page_where_it_happened': pageWhereItHappened,
      'timestamp': timestamp,
      'feedback_type': feedbackType,
    }.withoutNulls,
  );

  return firestoreData;
}

class BugReportsRecordDocumentEquality implements Equality<BugReportsRecord> {
  const BugReportsRecordDocumentEquality();

  @override
  bool equals(BugReportsRecord? e1, BugReportsRecord? e2) {
    return e1?.testerName == e2?.testerName &&
        e1?.issueDescription == e2?.issueDescription &&
        e1?.pageWhereItHappened == e2?.pageWhereItHappened &&
        e1?.timestamp == e2?.timestamp &&
        e1?.feedbackType == e2?.feedbackType;
  }

  @override
  int hash(BugReportsRecord? e) => const ListEquality().hash([
        e?.testerName,
        e?.issueDescription,
        e?.pageWhereItHappened,
        e?.timestamp,
        e?.feedbackType
      ]);

  @override
  bool isValidKey(Object? o) => o is BugReportsRecord;
}
