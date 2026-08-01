import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Server-generated only - see firestore.rules (`allow create: if false`)
/// and firebase/custom_cloud_functions/notifications.js. The client may
/// only flip `is_read`.
class NotificationsRecord extends FirestoreRecord {
  NotificationsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "user_ref" field.
  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  // "type" field.
  String? _type;
  String get type => _type ?? '';
  bool hasType() => _type != null;

  // "title" field.
  String? _title;
  String get title => _title ?? '';
  bool hasTitle() => _title != null;

  // "body" field.
  String? _body;
  String get body => _body ?? '';
  bool hasBody() => _body != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "is_read" field.
  bool? _isRead;
  bool get isRead => _isRead ?? false;
  bool hasIsRead() => _isRead != null;

  // "route_name" field. A FlutterFlow route name (e.g. 'OwnerProfile') to
  // push when this notification is tapped. Null when there's nowhere
  // meaningful to send the user.
  String? _routeName;
  String get routeName => _routeName ?? '';
  bool hasRouteName() => _routeName != null;

  void _initializeFields() {
    _userRef = snapshotData['user_ref'] as DocumentReference?;
    _type = snapshotData['type'] as String?;
    _title = snapshotData['title'] as String?;
    _body = snapshotData['body'] as String?;
    _createdAt = snapshotData['created_at'] as DateTime?;
    _isRead = snapshotData['is_read'] as bool?;
    _routeName = snapshotData['route_name'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('notifications');

  static Stream<NotificationsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => NotificationsRecord.fromSnapshot(s));

  static Future<NotificationsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => NotificationsRecord.fromSnapshot(s));

  static NotificationsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      NotificationsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static NotificationsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      NotificationsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'NotificationsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is NotificationsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createNotificationsRecordData({
  DocumentReference? userRef,
  String? type,
  String? title,
  String? body,
  DateTime? createdAt,
  bool? isRead,
  String? routeName,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'user_ref': userRef,
      'type': type,
      'title': title,
      'body': body,
      'created_at': createdAt,
      'is_read': isRead,
      'route_name': routeName,
    }.withoutNulls,
  );

  return firestoreData;
}

class NotificationsRecordDocumentEquality
    implements Equality<NotificationsRecord> {
  const NotificationsRecordDocumentEquality();

  @override
  bool equals(NotificationsRecord? e1, NotificationsRecord? e2) {
    return e1?.userRef == e2?.userRef &&
        e1?.type == e2?.type &&
        e1?.title == e2?.title &&
        e1?.body == e2?.body &&
        e1?.createdAt == e2?.createdAt &&
        e1?.isRead == e2?.isRead &&
        e1?.routeName == e2?.routeName;
  }

  @override
  int hash(NotificationsRecord? e) => const ListEquality().hash([
        e?.userRef,
        e?.type,
        e?.title,
        e?.body,
        e?.createdAt,
        e?.isRead,
        e?.routeName,
      ]);

  @override
  bool isValidKey(Object? o) => o is NotificationsRecord;
}
