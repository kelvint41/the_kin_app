import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class UsersRecord extends FirestoreRecord {
  UsersRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "email" field.
  String? _email;
  String get email => _email ?? '';
  bool hasEmail() => _email != null;

  // "display_name" field.
  String? _displayName;
  String get displayName => _displayName ?? '';
  bool hasDisplayName() => _displayName != null;

  // "ticker_symbol" field.
  String? _tickerSymbol;
  String get tickerSymbol => _tickerSymbol ?? '';
  bool hasTickerSymbol() => _tickerSymbol != null;

  // "photo_url" field.
  String? _photoUrl;
  String get photoUrl => _photoUrl ?? '';
  bool hasPhotoUrl() => _photoUrl != null;

  // "uid" field.
  String? _uid;
  String get uid => _uid ?? '';
  bool hasUid() => _uid != null;

  // "created_time" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "phone_number" field.
  String? _phoneNumber;
  String get phoneNumber => _phoneNumber ?? '';
  bool hasPhoneNumber() => _phoneNumber != null;

  // "owned_business" field.
  DocumentReference? _ownedBusiness;
  DocumentReference? get ownedBusiness => _ownedBusiness;
  bool hasOwnedBusiness() => _ownedBusiness != null;

  // "subscription_status" field.
  String? _subscriptionStatus;
  String get subscriptionStatus => _subscriptionStatus ?? '';
  bool hasSubscriptionStatus() => _subscriptionStatus != null;

  // "isEliteFounder" field.
  bool? _isEliteFounder;
  bool get isEliteFounder => _isEliteFounder ?? false;
  bool hasIsEliteFounder() => _isEliteFounder != null;

  // "account_created_at" field.
  DateTime? _accountCreatedAt;
  DateTime? get accountCreatedAt => _accountCreatedAt;
  bool hasAccountCreatedAt() => _accountCreatedAt != null;

  // "is_active" field.
  bool? _isActive;
  bool get isActive => _isActive ?? false;
  bool hasIsActive() => _isActive != null;

  // "last_login" field.
  DateTime? _lastLogin;
  DateTime? get lastLogin => _lastLogin;
  bool hasLastLogin() => _lastLogin != null;

  // "ar_tours_completed" field.
  int? _arToursCompleted;
  int get arToursCompleted => _arToursCompleted ?? 0;
  bool hasArToursCompleted() => _arToursCompleted != null;

  // "is_admin" field.
  bool? _isAdmin;
  bool get isAdmin => _isAdmin ?? false;
  bool hasIsAdmin() => _isAdmin != null;

  // "scavenger_points" field. Cumulative points from verified check-ins,
  // scaled by each business's points_multiplier (Standard/Rare/Hidden Gem).
  // Server-authoritative - only recordVerifiedVisit
  // (firebase/custom_cloud_functions/visit_verification.js) increments
  // this, on a genuinely new visit, never on a deduped repeat check-in.
  int? _scavengerPoints;
  int get scavengerPoints => _scavengerPoints ?? 0;
  bool hasScavengerPoints() => _scavengerPoints != null;

  // "kin_quest_terms_accepted_at" field. Set client-side the first time
  // this user taps "I Agree & Start" on the KIN Quest intro/consent
  // screen (kin_quest_widget.dart). Presence alone gates re-showing that
  // screen on future visits - null means "never accepted, or accepted on
  // a version before this field existed", both of which should show it.
  DateTime? _kinQuestTermsAcceptedAt;
  DateTime? get kinQuestTermsAcceptedAt => _kinQuestTermsAcceptedAt;
  bool hasKinQuestTermsAcceptedAt() => _kinQuestTermsAcceptedAt != null;

  void _initializeFields() {
    _email = snapshotData['email'] as String?;
    _displayName = snapshotData['display_name'] as String?;
    _tickerSymbol = snapshotData['ticker_symbol'] as String?;
    _photoUrl = snapshotData['photo_url'] as String?;
    _uid = snapshotData['uid'] as String?;
    _createdTime = snapshotData['created_time'] as DateTime?;
    _phoneNumber = snapshotData['phone_number'] as String?;
    _ownedBusiness = snapshotData['owned_business'] as DocumentReference?;
    _subscriptionStatus = snapshotData['subscription_status'] as String?;
    _isEliteFounder = snapshotData['isEliteFounder'] as bool?;
    _accountCreatedAt = snapshotData['account_created_at'] as DateTime?;
    _isActive = snapshotData['is_active'] as bool?;
    _lastLogin = snapshotData['last_login'] as DateTime?;
    _arToursCompleted = castToType<int>(snapshotData['ar_tours_completed']);
    _isAdmin = snapshotData['is_admin'] as bool?;
    _scavengerPoints = castToType<int>(snapshotData['scavenger_points']);
    _kinQuestTermsAcceptedAt =
        snapshotData['kin_quest_terms_accepted_at'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('users');

  static Stream<UsersRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => UsersRecord.fromSnapshot(s));

  static Future<UsersRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => UsersRecord.fromSnapshot(s));

  static UsersRecord fromSnapshot(DocumentSnapshot snapshot) => UsersRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static UsersRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      UsersRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'UsersRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is UsersRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createUsersRecordData({
  String? email,
  String? displayName,
  String? tickerSymbol,
  String? photoUrl,
  String? uid,
  DateTime? createdTime,
  String? phoneNumber,
  DocumentReference? ownedBusiness,
  String? subscriptionStatus,
  bool? isEliteFounder,
  DateTime? accountCreatedAt,
  bool? isActive,
  DateTime? lastLogin,
  int? arToursCompleted,
  bool? isAdmin,
  int? scavengerPoints,
  DateTime? kinQuestTermsAcceptedAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'email': email,
      'display_name': displayName,
      'ticker_symbol': tickerSymbol,
      'photo_url': photoUrl,
      'uid': uid,
      'created_time': createdTime,
      'phone_number': phoneNumber,
      'owned_business': ownedBusiness,
      'subscription_status': subscriptionStatus,
      'isEliteFounder': isEliteFounder,
      'account_created_at': accountCreatedAt,
      'is_active': isActive,
      'last_login': lastLogin,
      'ar_tours_completed': arToursCompleted,
      'is_admin': isAdmin,
      'scavenger_points': scavengerPoints,
      'kin_quest_terms_accepted_at': kinQuestTermsAcceptedAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class UsersRecordDocumentEquality implements Equality<UsersRecord> {
  const UsersRecordDocumentEquality();

  @override
  bool equals(UsersRecord? e1, UsersRecord? e2) {
    return e1?.email == e2?.email &&
        e1?.displayName == e2?.displayName &&
        e1?.tickerSymbol == e2?.tickerSymbol &&
        e1?.photoUrl == e2?.photoUrl &&
        e1?.uid == e2?.uid &&
        e1?.createdTime == e2?.createdTime &&
        e1?.phoneNumber == e2?.phoneNumber &&
        e1?.ownedBusiness == e2?.ownedBusiness &&
        e1?.subscriptionStatus == e2?.subscriptionStatus &&
        e1?.isEliteFounder == e2?.isEliteFounder &&
        e1?.accountCreatedAt == e2?.accountCreatedAt &&
        e1?.isActive == e2?.isActive &&
        e1?.lastLogin == e2?.lastLogin &&
        e1?.arToursCompleted == e2?.arToursCompleted &&
        e1?.isAdmin == e2?.isAdmin &&
        e1?.scavengerPoints == e2?.scavengerPoints &&
        e1?.kinQuestTermsAcceptedAt == e2?.kinQuestTermsAcceptedAt;
  }

  @override
  int hash(UsersRecord? e) => const ListEquality().hash([
        e?.email,
        e?.displayName,
        e?.tickerSymbol,
        e?.photoUrl,
        e?.uid,
        e?.createdTime,
        e?.phoneNumber,
        e?.ownedBusiness,
        e?.subscriptionStatus,
        e?.isEliteFounder,
        e?.accountCreatedAt,
        e?.isActive,
        e?.lastLogin,
        e?.arToursCompleted,
        e?.isAdmin,
        e?.scavengerPoints,
        e?.kinQuestTermsAcceptedAt
      ]);

  @override
  bool isValidKey(Object? o) => o is UsersRecord;
}
