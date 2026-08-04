import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// One coach-mark walkthrough (see WalkthroughService/WalkthroughRunner),
/// document id is the walkthrough's key - e.g. 'general_tour',
/// 'kindex_explainer'. steps is an ordered array of maps
/// {target_id, title, body}: target_id is matched against a GlobalKey the
/// showing screen registers for that on-screen element (necessarily
/// code-side - Firestore can't point at a widget), title/body is the
/// admin-editable copy for that step, in order.
class OnboardingWalkthroughsRecord extends FirestoreRecord {
  OnboardingWalkthroughsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "steps" field.
  List<Map<String, dynamic>>? _steps;
  List<Map<String, dynamic>> get steps => _steps ?? const [];
  bool hasSteps() => _steps != null;

  // "enabled" field. Lets an admin pull a walkthrough without deleting
  // its content - defaults true so a doc with the field never set (e.g.
  // seeded before this existed) still shows.
  bool? _enabled;
  bool get enabled => _enabled ?? true;
  bool hasEnabled() => _enabled != null;

  void _initializeFields() {
    final rawSteps = snapshotData['steps'];
    _steps = rawSteps is List
        ? rawSteps.whereType<Map<String, dynamic>>().toList()
        : null;
    _enabled = snapshotData['enabled'] as bool?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('onboarding_walkthroughs');

  static Stream<OnboardingWalkthroughsRecord> getDocument(
          DocumentReference ref) =>
      ref.snapshots().map((s) => OnboardingWalkthroughsRecord.fromSnapshot(s));

  static Future<OnboardingWalkthroughsRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => OnboardingWalkthroughsRecord.fromSnapshot(s));

  static OnboardingWalkthroughsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      OnboardingWalkthroughsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static OnboardingWalkthroughsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      OnboardingWalkthroughsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'OnboardingWalkthroughsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is OnboardingWalkthroughsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

class OnboardingWalkthroughsRecordDocumentEquality
    implements Equality<OnboardingWalkthroughsRecord> {
  const OnboardingWalkthroughsRecordDocumentEquality();

  @override
  bool equals(
          OnboardingWalkthroughsRecord? e1, OnboardingWalkthroughsRecord? e2) =>
      e1?.enabled == e2?.enabled;

  @override
  int hash(OnboardingWalkthroughsRecord? e) =>
      const ListEquality().hash([e?.enabled]);

  @override
  bool isValidKey(Object? o) => o is OnboardingWalkthroughsRecord;
}
