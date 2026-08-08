import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ReviewsRecord extends FirestoreRecord {
  ReviewsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "business_ref" field.
  DocumentReference? _businessRef;
  DocumentReference? get businessRef => _businessRef;
  bool hasBusinessRef() => _businessRef != null;

  // "user_ref" field.
  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  // "rating" field.
  double? _rating;
  double get rating => _rating ?? 0.0;
  bool hasRating() => _rating != null;

  // "review_text" field.
  String? _reviewText;
  String get reviewText => _reviewText ?? '';
  bool hasReviewText() => _reviewText != null;

  // "timestamp" field.
  DateTime? _timestamp;
  DateTime? get timestamp => _timestamp;
  bool hasTimestamp() => _timestamp != null;

  // "edit_count" field. Number of times the customer has edited this
  // review; capped in Firestore rules purely as an anti-spam measure.
  int? _editCount;
  int get editCount => _editCount ?? 0;
  bool hasEditCount() => _editCount != null;

  // "photo_url" field. Optional customer photo attached to the review,
  // uploaded to Firebase Storage under the reviewer's own
  // users/{uid}/ path (the one path storage.rules opens for writing).
  // Empty on the overwhelming majority of reviews - this shipped after
  // them, and the attachment is optional regardless.
  String? _photoUrl;
  String get photoUrl => _photoUrl ?? '';
  bool hasPhotoUrl() => _photoUrl != null;

  void _initializeFields() {
    _businessRef = snapshotData['business_ref'] as DocumentReference?;
    _userRef = snapshotData['user_ref'] as DocumentReference?;
    _rating = castToType<double>(snapshotData['rating']);
    _reviewText = snapshotData['review_text'] as String?;
    _timestamp = snapshotData['timestamp'] as DateTime?;
    _editCount = castToType<int>(snapshotData['edit_count']);
    _photoUrl = snapshotData['photo_url'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('reviews');

  static Stream<ReviewsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ReviewsRecord.fromSnapshot(s));

  static Future<ReviewsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ReviewsRecord.fromSnapshot(s));

  static ReviewsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ReviewsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ReviewsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ReviewsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ReviewsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ReviewsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createReviewsRecordData({
  DocumentReference? businessRef,
  DocumentReference? userRef,
  double? rating,
  String? reviewText,
  DateTime? timestamp,
  int? editCount,
  String? photoUrl,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'business_ref': businessRef,
      'user_ref': userRef,
      'rating': rating,
      'review_text': reviewText,
      'timestamp': timestamp,
      'edit_count': editCount,
      'photo_url': photoUrl,
    }.withoutNulls,
  );

  return firestoreData;
}

class ReviewsRecordDocumentEquality implements Equality<ReviewsRecord> {
  const ReviewsRecordDocumentEquality();

  @override
  bool equals(ReviewsRecord? e1, ReviewsRecord? e2) {
    return e1?.businessRef == e2?.businessRef &&
        e1?.userRef == e2?.userRef &&
        e1?.rating == e2?.rating &&
        e1?.reviewText == e2?.reviewText &&
        e1?.timestamp == e2?.timestamp &&
        e1?.editCount == e2?.editCount;
  }

  @override
  int hash(ReviewsRecord? e) => const ListEquality().hash(
      [e?.businessRef, e?.userRef, e?.rating, e?.reviewText, e?.timestamp,
        e?.editCount
      ]);

  @override
  bool isValidKey(Object? o) => o is ReviewsRecord;
}
