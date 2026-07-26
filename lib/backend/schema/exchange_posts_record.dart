import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

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

  // "image_url" field.
  String? _imageUrl;
  String get imageUrl => _imageUrl ?? '';
  bool hasImageUrl() => _imageUrl != null;

  // "comments_count" field.
  int? _commentsCount;
  int get commentsCount => _commentsCount ?? 0;
  bool hasCommentsCount() => _commentsCount != null;

  // "location" field.
  String? _location;
  String get location => _location ?? '';
  bool hasLocation() => _location != null;

  // "user_photo_url" field.
  String? _userPhotoUrl;
  String get userPhotoUrl => _userPhotoUrl ?? '';
  bool hasUserPhotoUrl() => _userPhotoUrl != null;

  // "video_url" field.
  String? _videoUrl;
  String get videoUrl => _videoUrl ?? '';
  bool hasVideoUrl() => _videoUrl != null;

  void _initializeFields() {
    _postId = snapshotData['post_id'] as String?;
    _userRef = snapshotData['user_ref'] as DocumentReference?;
    _postText = snapshotData['post_text'] as String?;
    _postImage = snapshotData['post_image'] as String?;
    _timestamp = snapshotData['timestamp'] as DateTime?;
    _likesCount = castToType<int>(snapshotData['likes_count']);
    _imageUrl = snapshotData['image_url'] as String?;
    _commentsCount = castToType<int>(snapshotData['comments_count']);
    _location = snapshotData['location'] as String?;
    _userPhotoUrl = snapshotData['user_photo_url'] as String?;
    _videoUrl = snapshotData['video_url'] as String?;
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
  String? postText,
  String? postImage,
  DateTime? timestamp,
  int? likesCount,
  String? imageUrl,
  int? commentsCount,
  String? location,
  String? userPhotoUrl,
  String? videoUrl,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'post_id': postId,
      'user_ref': userRef,
      'post_text': postText,
      'post_image': postImage,
      'timestamp': timestamp,
      'likes_count': likesCount,
      'image_url': imageUrl,
      'comments_count': commentsCount,
      'location': location,
      'user_photo_url': userPhotoUrl,
      'video_url': videoUrl,
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
        e1?.postText == e2?.postText &&
        e1?.postImage == e2?.postImage &&
        e1?.timestamp == e2?.timestamp &&
        e1?.likesCount == e2?.likesCount &&
        e1?.imageUrl == e2?.imageUrl &&
        e1?.commentsCount == e2?.commentsCount &&
        e1?.location == e2?.location &&
        e1?.userPhotoUrl == e2?.userPhotoUrl &&
        e1?.videoUrl == e2?.videoUrl;
  }

  @override
  int hash(ExchangePostsRecord? e) => const ListEquality().hash([
        e?.postId,
        e?.userRef,
        e?.postText,
        e?.postImage,
        e?.timestamp,
        e?.likesCount,
        e?.imageUrl,
        e?.commentsCount,
        e?.location,
        e?.userPhotoUrl,
        e?.videoUrl
      ]);

  @override
  bool isValidKey(Object? o) => o is ExchangePostsRecord;
}
