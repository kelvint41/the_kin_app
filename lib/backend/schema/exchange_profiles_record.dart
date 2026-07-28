import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// A person's presence in the Exchange.
///
/// The collection already existed, holding only `agreed_to_conduct`,
/// `terms_version`, `created_at` and a `display_name` that was empty
/// string on the accounts that had one - so posts rendered with a blank
/// author and there was nothing to open when you tapped one. It was a
/// consent record wearing the name of a profile.
///
/// Written as a hand-authored record rather than left to FlutterFlow
/// codegen because the collection is read by firestore.rules on every
/// exchange_posts create, and the field names have to stay in step with
/// that rule.
///
/// Deliberately keyed by uid (the document id *is* the user's uid), which
/// is what lets the posts rule check a profile with a single get() and no
/// query.
class ExchangeProfilesRecord extends FirestoreRecord {
  ExchangeProfilesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "user_ref" field.
  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  // "display_name" field.
  String? _displayName;
  String get displayName => _displayName ?? '';
  bool hasDisplayName() => _displayName != null;

  // "handle" field.
  //
  // The @name, unique and lowercase. Separate from display_name because
  // display names are not unique and change freely; this is the stable
  // thing to address someone by.
  String? _handle;
  String get handle => _handle ?? '';
  bool hasHandle() => _handle != null;

  // "bio" field.
  String? _bio;
  String get bio => _bio ?? '';
  bool hasBio() => _bio != null;

  // "photo_url" field.
  String? _photoUrl;
  String get photoUrl => _photoUrl ?? '';
  bool hasPhotoUrl() => _photoUrl != null;

  // "business_ref" field.
  //
  // Set only when this person owns a business, so their posts can carry
  // an owner badge. Null for customers - membership of the Exchange is
  // deliberately not conditional on owning anything.
  DocumentReference? _businessRef;
  DocumentReference? get businessRef => _businessRef;
  bool hasBusinessRef() => _businessRef != null;

  // "agreed_to_conduct" field.
  bool? _agreedToConduct;
  bool get agreedToConduct => _agreedToConduct ?? false;
  bool hasAgreedToConduct() => _agreedToConduct != null;

  // "terms_version" field.
  String? _termsVersion;
  String get termsVersion => _termsVersion ?? '';
  bool hasTermsVersion() => _termsVersion != null;

  // "post_count" field.
  int? _postCount;
  int get postCount => _postCount ?? 0;
  bool hasPostCount() => _postCount != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  void _initializeFields() {
    _userRef = snapshotData['user_ref'] as DocumentReference?;
    _displayName = snapshotData['display_name'] as String?;
    _handle = snapshotData['handle'] as String?;
    _bio = snapshotData['bio'] as String?;
    _photoUrl = snapshotData['photo_url'] as String?;
    _businessRef = snapshotData['business_ref'] as DocumentReference?;
    _agreedToConduct = snapshotData['agreed_to_conduct'] as bool?;
    _termsVersion = snapshotData['terms_version'] as String?;
    _postCount = castToType<int>(snapshotData['post_count']);
    _createdAt = snapshotData['created_at'] as DateTime?;
  }

  /// True once there is enough here to show an author on a post.
  ///
  /// A row can exist with consent recorded and nothing else - that is what
  /// every existing row looked like - so "the document exists" is not the
  /// same question as "this person has a profile".
  bool get isComplete => displayName.trim().isNotEmpty;

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('exchange_profiles');

  static Stream<ExchangeProfilesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ExchangeProfilesRecord.fromSnapshot(s));

  static Future<ExchangeProfilesRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => ExchangeProfilesRecord.fromSnapshot(s));

  static ExchangeProfilesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ExchangeProfilesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ExchangeProfilesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ExchangeProfilesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ExchangeProfilesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ExchangeProfilesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createExchangeProfilesRecordData({
  DocumentReference? userRef,
  String? displayName,
  String? handle,
  String? bio,
  String? photoUrl,
  DocumentReference? businessRef,
  bool? agreedToConduct,
  String? termsVersion,
  int? postCount,
  DateTime? createdAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'user_ref': userRef,
      'display_name': displayName,
      'handle': handle,
      'bio': bio,
      'photo_url': photoUrl,
      'business_ref': businessRef,
      'agreed_to_conduct': agreedToConduct,
      'terms_version': termsVersion,
      'post_count': postCount,
      'created_at': createdAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class ExchangeProfilesRecordDocumentEquality
    implements Equality<ExchangeProfilesRecord> {
  const ExchangeProfilesRecordDocumentEquality();

  @override
  bool equals(ExchangeProfilesRecord? e1, ExchangeProfilesRecord? e2) {
    return e1?.userRef == e2?.userRef &&
        e1?.displayName == e2?.displayName &&
        e1?.handle == e2?.handle &&
        e1?.bio == e2?.bio &&
        e1?.photoUrl == e2?.photoUrl &&
        e1?.businessRef == e2?.businessRef &&
        e1?.agreedToConduct == e2?.agreedToConduct &&
        e1?.termsVersion == e2?.termsVersion &&
        e1?.postCount == e2?.postCount &&
        e1?.createdAt == e2?.createdAt;
  }

  @override
  int hash(ExchangeProfilesRecord? e) => const ListEquality().hash([
        e?.userRef,
        e?.displayName,
        e?.handle,
        e?.bio,
        e?.photoUrl,
        e?.businessRef,
        e?.agreedToConduct,
        e?.termsVersion,
        e?.postCount,
        e?.createdAt
      ]);

  @override
  bool isValidKey(Object? o) => o is ExchangeProfilesRecord;
}
