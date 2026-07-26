import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AnalyticsDailyRecord extends FirestoreRecord {
  AnalyticsDailyRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "date" field.
  String? _date;
  String get date => _date ?? '';
  bool hasDate() => _date != null;

  // "city" field.
  String? _city;
  String get city => _city ?? '';
  bool hasCity() => _city != null;

  // "total_sessions" field.
  int? _totalSessions;
  int get totalSessions => _totalSessions ?? 0;
  bool hasTotalSessions() => _totalSessions != null;

  // "total_page_views" field.
  int? _totalPageViews;
  int get totalPageViews => _totalPageViews ?? 0;
  bool hasTotalPageViews() => _totalPageViews != null;

  // "total_profile_views" field.
  int? _totalProfileViews;
  int get totalProfileViews => _totalProfileViews ?? 0;
  bool hasTotalProfileViews() => _totalProfileViews != null;

  // "total_call_taps" field.
  int? _totalCallTaps;
  int get totalCallTaps => _totalCallTaps ?? 0;
  bool hasTotalCallTaps() => _totalCallTaps != null;

  // "total_map_launches" field.
  int? _totalMapLaunches;
  int get totalMapLaunches => _totalMapLaunches ?? 0;
  bool hasTotalMapLaunches() => _totalMapLaunches != null;

  // "new_user_registrations" field.
  int? _newUserRegistrations;
  int get newUserRegistrations => _newUserRegistrations ?? 0;
  bool hasNewUserRegistrations() => _newUserRegistrations != null;

  // "black_owned_profile_views" field.
  int? _blackOwnedProfileViews;
  int get blackOwnedProfileViews => _blackOwnedProfileViews ?? 0;
  bool hasBlackOwnedProfileViews() => _blackOwnedProfileViews != null;

  // "top_businesses" field.
  List<BusinessMetricStruct>? _topBusinesses;
  List<BusinessMetricStruct> get topBusinesses => _topBusinesses ?? const [];
  bool hasTopBusinesses() => _topBusinesses != null;

  // "top_categories" field.
  List<CategoryMetricStruct>? _topCategories;
  List<CategoryMetricStruct> get topCategories => _topCategories ?? const [];
  bool hasTopCategories() => _topCategories != null;

  // "last_updated" field.
  DateTime? _lastUpdated;
  DateTime? get lastUpdated => _lastUpdated;
  bool hasLastUpdated() => _lastUpdated != null;

  void _initializeFields() {
    _date = snapshotData['date'] as String?;
    _city = snapshotData['city'] as String?;
    _totalSessions = castToType<int>(snapshotData['total_sessions']);
    _totalPageViews = castToType<int>(snapshotData['total_page_views']);
    _totalProfileViews = castToType<int>(snapshotData['total_profile_views']);
    _totalCallTaps = castToType<int>(snapshotData['total_call_taps']);
    _totalMapLaunches = castToType<int>(snapshotData['total_map_launches']);
    _newUserRegistrations =
        castToType<int>(snapshotData['new_user_registrations']);
    _blackOwnedProfileViews =
        castToType<int>(snapshotData['black_owned_profile_views']);
    _topBusinesses = getStructList(
      snapshotData['top_businesses'],
      BusinessMetricStruct.fromMap,
    );
    _topCategories = getStructList(
      snapshotData['top_categories'],
      CategoryMetricStruct.fromMap,
    );
    _lastUpdated = snapshotData['last_updated'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('analytics_daily');

  static Stream<AnalyticsDailyRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => AnalyticsDailyRecord.fromSnapshot(s));

  static Future<AnalyticsDailyRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => AnalyticsDailyRecord.fromSnapshot(s));

  static AnalyticsDailyRecord fromSnapshot(DocumentSnapshot snapshot) =>
      AnalyticsDailyRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static AnalyticsDailyRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      AnalyticsDailyRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'AnalyticsDailyRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is AnalyticsDailyRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createAnalyticsDailyRecordData({
  String? date,
  String? city,
  int? totalSessions,
  int? totalPageViews,
  int? totalProfileViews,
  int? totalCallTaps,
  int? totalMapLaunches,
  int? newUserRegistrations,
  int? blackOwnedProfileViews,
  DateTime? lastUpdated,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'date': date,
      'city': city,
      'total_sessions': totalSessions,
      'total_page_views': totalPageViews,
      'total_profile_views': totalProfileViews,
      'total_call_taps': totalCallTaps,
      'total_map_launches': totalMapLaunches,
      'new_user_registrations': newUserRegistrations,
      'black_owned_profile_views': blackOwnedProfileViews,
      'last_updated': lastUpdated,
    }.withoutNulls,
  );

  return firestoreData;
}

class AnalyticsDailyRecordDocumentEquality
    implements Equality<AnalyticsDailyRecord> {
  const AnalyticsDailyRecordDocumentEquality();

  @override
  bool equals(AnalyticsDailyRecord? e1, AnalyticsDailyRecord? e2) {
    const listEquality = ListEquality();
    return e1?.date == e2?.date &&
        e1?.city == e2?.city &&
        e1?.totalSessions == e2?.totalSessions &&
        e1?.totalPageViews == e2?.totalPageViews &&
        e1?.totalProfileViews == e2?.totalProfileViews &&
        e1?.totalCallTaps == e2?.totalCallTaps &&
        e1?.totalMapLaunches == e2?.totalMapLaunches &&
        e1?.newUserRegistrations == e2?.newUserRegistrations &&
        e1?.blackOwnedProfileViews == e2?.blackOwnedProfileViews &&
        listEquality.equals(e1?.topBusinesses, e2?.topBusinesses) &&
        listEquality.equals(e1?.topCategories, e2?.topCategories) &&
        e1?.lastUpdated == e2?.lastUpdated;
  }

  @override
  int hash(AnalyticsDailyRecord? e) => const ListEquality().hash([
        e?.date,
        e?.city,
        e?.totalSessions,
        e?.totalPageViews,
        e?.totalProfileViews,
        e?.totalCallTaps,
        e?.totalMapLaunches,
        e?.newUserRegistrations,
        e?.blackOwnedProfileViews,
        e?.topBusinesses,
        e?.topCategories,
        e?.lastUpdated
      ]);

  @override
  bool isValidKey(Object? o) => o is AnalyticsDailyRecord;
}
