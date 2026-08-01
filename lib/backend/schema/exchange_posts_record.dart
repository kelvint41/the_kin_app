import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ExchangePostsRecord extends FirestoreRecord {
  ExchangePostsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "post_id" field.
  String? _postId;
  String get postId => _postId ?? '';
  bool hasPostId() => _postId != null;

  // "user_ref" field.
  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  // "business_ref" field.
  DocumentReference? _businessRef;
  DocumentReference? get businessRef => _businessRef;
  bool hasBusinessRef() => _businessRef != null;

  // "post_text" field.
  String? _postText;
  String get postText => _postText ?? '';
  bool hasPostText() => _postText != null;

  // "post_image" field.
  String? _postImage;
  String get postImage => _postImage ?? '';
  bool hasPostImage() => _postImage != null;

  // "timestamp" field.
  DateTime? _timestamp;
  DateTime? get timestamp => _timestamp;
  bool hasTimestamp() => _timestamp != null;

  // "likes_count" field.
  int? _likesCount;
  int get likesCount => _likesCount ?? 0;
  bool hasLikesCount() => _likesCount != null;

  // "is_edited" field. Set true the first time the author edits post_text
  // after posting - lets the feed show an "(edited)" marker.
  bool? _isEdited;
  bool get isEdited => _isEdited ?? false;
  bool hasIsEdited() => _isEdited != null;

  // "edited_at" field.
  DateTime? _editedAt;
  DateTime? get editedAt => _editedAt;
  bool hasEditedAt() => _editedAt != null;

  void _initializeFields() {
    _postId = snapshotData['post_id'] as String?;
    _userRef = snapshotData['user_ref'] as DocumentReference?;
    _businessRef = snapshotData['business_ref'] as DocumentReference?;
    _postText = snapshotData['post_text'] as String?;
    _postImage = snapshotData['post_image'] as String?;
    _timestamp = snapshotData['timestamp'] as DateTime?;
    _likesCount = castToType<int>(snapshotData['likes_count']);
    _isEdited = snapshotData['is_edited'] as bool?;
    _editedAt = snapshotData['edited_at'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('exchange_posts');

  static Stream<ExchangePostsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ExchangePostsRecord.fromSnapshot(s));

  static Future<ExchangePostsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ExchangePostsRecord.fromSnapshot(s));

  static ExchangePostsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ExchangePostsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ExchangePostsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ExchangePostsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ExchangePostsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ExchangePostsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createExchangePostsRecordData({
  String? postId,
  DocumentReference? userRef,
  DocumentReference? businessRef,
  String? postText,
  String? postImage,
  DateTime? timestamp,
  int? likesCount,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'post_id': postId,
      'user_ref': userRef,
      'business_ref': businessRef,
      'post_text': postText,
      'post_image': postImage,
      'timestamp': timestamp,
      'likes_count': likesCount,
    }.withoutNulls,
  );

  return firestoreData;
}

class ExchangePostsRecordDocumentEquality
    implements Equality<ExchangePostsRecord> {
  const ExchangePostsRecordDocumentEquality();

  @override
  bool equals(ExchangePostsRecord? e1, ExchangePostsRecord? e2) {
    return e1?.postId == e2?.postId &&
        e1?.userRef == e2?.userRef &&
        e1?.businessRef == e2?.businessRef &&
        e1?.postText == e2?.postText &&
        e1?.postImage == e2?.postImage &&
        e1?.timestamp == e2?.timestamp &&
        e1?.likesCount == e2?.likesCount;
  }

  @override
  int hash(ExchangePostsRecord? e) => const ListEquality().hash([
        e?.postId,
        e?.userRef,
        e?.businessRef,
        e?.postText,
        e?.postImage,
        e?.timestamp,
        e?.likesCount
      ]);

  @override
  bool isValidKey(Object? o) => o is ExchangePostsRecord;
}
