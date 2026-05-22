import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class BusinessesRecord extends FirestoreRecord {
  BusinessesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "is_black_owned" field.
  bool? _isBlackOwned;
  bool get isBlackOwned => _isBlackOwned ?? false;
  bool hasIsBlackOwned() => _isBlackOwned != null;

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  // "category" field.
  String? _category;
  String get category => _category ?? '';
  bool hasCategory() => _category != null;

  // "website" field.
  String? _website;
  String get website => _website ?? '';
  bool hasWebsite() => _website != null;

  // "loyalty_offer" field.
  String? _loyaltyOffer;
  String get loyaltyOffer => _loyaltyOffer ?? '';
  bool hasLoyaltyOffer() => _loyaltyOffer != null;

  // "ticker_symbol" field.
  String? _tickerSymbol;
  String get tickerSymbol => _tickerSymbol ?? '';
  bool hasTickerSymbol() => _tickerSymbol != null;

  // "hero_image" field.
  String? _heroImage;
  String get heroImage => _heroImage ?? '';
  bool hasHeroImage() => _heroImage != null;

  // "business_location" field.
  LatLng? _businessLocation;
  LatLng? get businessLocation => _businessLocation;
  bool hasBusinessLocation() => _businessLocation != null;

  // "address" field.
  String? _address;
  String get address => _address ?? '';
  bool hasAddress() => _address != null;

  // "is_bob_verified" field.
  bool? _isBobVerified;
  bool get isBobVerified => _isBobVerified ?? false;
  bool hasIsBobVerified() => _isBobVerified != null;

  // "is_actively_pulsing" field.
  bool? _isActivelyPulsing;
  bool get isActivelyPulsing => _isActivelyPulsing ?? false;
  bool hasIsActivelyPulsing() => _isActivelyPulsing != null;

  // "tier_level" field.
  String? _tierLevel;
  String get tierLevel => _tierLevel ?? '';
  bool hasTierLevel() => _tierLevel != null;

  // "has_physical_location" field.
  bool? _hasPhysicalLocation;
  bool get hasPhysicalLocation => _hasPhysicalLocation ?? false;
  bool hasHasPhysicalLocation() => _hasPhysicalLocation != null;

  // "kindex_score" field.
  double? _kindexScore;
  double get kindexScore => _kindexScore ?? 0.0;
  bool hasKindexScore() => _kindexScore != null;

  // "owner" field.
  DocumentReference? _owner;
  DocumentReference? get owner => _owner;
  bool hasOwner() => _owner != null;

  // "description" field.
  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  // "phone_number" field.
  String? _phoneNumber;
  String get phoneNumber => _phoneNumber ?? '';
  bool hasPhoneNumber() => _phoneNumber != null;

  // "is_premium" field.
  bool? _isPremium;
  bool get isPremium => _isPremium ?? false;
  bool hasIsPremium() => _isPremium != null;

  // "is_featured" field.
  bool? _isFeatured;
  bool get isFeatured => _isFeatured ?? false;
  bool hasIsFeatured() => _isFeatured != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "city" field.
  String? _city;
  String get city => _city ?? '';
  bool hasCity() => _city != null;

  // "Latitude" field.
  double? _latitude;
  double get latitude => _latitude ?? 0.0;
  bool hasLatitude() => _latitude != null;

  // "Longitude" field.
  double? _longitude;
  double get longitude => _longitude ?? 0.0;
  bool hasLongitude() => _longitude != null;

  // "search_query" field.
  String? _searchQuery;
  String get searchQuery => _searchQuery ?? '';
  bool hasSearchQuery() => _searchQuery != null;

  // "placeID" field.
  String? _placeID;
  String get placeID => _placeID ?? '';
  bool hasPlaceID() => _placeID != null;

  // "Zip_code" field.
  int? _zipCode;
  int get zipCode => _zipCode ?? 0;
  bool hasZipCode() => _zipCode != null;

  // "owner_first_name" field.
  String? _ownerFirstName;
  String get ownerFirstName => _ownerFirstName ?? '';
  bool hasOwnerFirstName() => _ownerFirstName != null;

  // "owner_last_name" field.
  String? _ownerLastName;
  String get ownerLastName => _ownerLastName ?? '';
  bool hasOwnerLastName() => _ownerLastName != null;

  // "business_name" field.
  String? _businessName;
  String get businessName => _businessName ?? '';
  bool hasBusinessName() => _businessName != null;

  // "Phone" field.
  String? _phone;
  String get phone => _phone ?? '';
  bool hasPhone() => _phone != null;

  // "Email" field.
  String? _email;
  String get email => _email ?? '';
  bool hasEmail() => _email != null;

  // "State" field.
  String? _state;
  String get state => _state ?? '';
  bool hasState() => _state != null;

  // "coordinates" field.
  LatLng? _coordinates;
  LatLng? get coordinates => _coordinates;
  bool hasCoordinates() => _coordinates != null;

  // "is_open" field.
  bool? _isOpen;
  bool get isOpen => _isOpen ?? false;
  bool hasIsOpen() => _isOpen != null;

  // "is_veteran" field.
  bool? _isVeteran;
  bool get isVeteran => _isVeteran ?? false;
  bool hasIsVeteran() => _isVeteran != null;

  // "is_ecommerce" field.
  bool? _isEcommerce;
  bool get isEcommerce => _isEcommerce ?? false;
  bool hasIsEcommerce() => _isEcommerce != null;

  // "verified_check_ins" field.
  String? _verifiedCheckIns;
  String get verifiedCheckIns => _verifiedCheckIns ?? '';
  bool hasVerifiedCheckIns() => _verifiedCheckIns != null;

  // "social_share_config" field.
  Map<String, dynamic>? _socialShareConfig;
  Map<String, dynamic> get socialShareConfig => _socialShareConfig ?? const {};
  bool hasSocialShareConfig() => _socialShareConfig != null;

  void _initializeFields() {
    _isBlackOwned = snapshotData['is_black_owned'] as bool?;
    _name = snapshotData['name'] as String?;
    _category = snapshotData['category'] as String?;
    _website = snapshotData['website'] as String?;
    _loyaltyOffer = snapshotData['loyalty_offer'] as String?;
    _tickerSymbol = snapshotData['ticker_symbol'] as String?;
    _heroImage = snapshotData['hero_image'] as String?;
    _businessLocation = snapshotData['business_location'] as LatLng?;
    _address = snapshotData['address'] as String?;
    _isBobVerified = snapshotData['is_bob_verified'] as bool?;
    _isActivelyPulsing = snapshotData['is_actively_pulsing'] as bool?;
    _tierLevel = snapshotData['tier_level'] as String?;
    _hasPhysicalLocation = snapshotData['has_physical_location'] as bool?;
    _kindexScore = castToType<double>(snapshotData['kindex_score']);
    _owner = snapshotData['owner'] as DocumentReference?;
    _description = snapshotData['description'] as String?;
    _phoneNumber = snapshotData['phone_number'] as String?;
    _isPremium = snapshotData['is_premium'] as bool?;
    _isFeatured = snapshotData['is_featured'] as bool?;
    _createdAt = snapshotData['created_at'] as DateTime?;
    _city = snapshotData['city'] as String?;
    _latitude = castToType<double>(snapshotData['Latitude']);
    _longitude = castToType<double>(snapshotData['Longitude']);
    _searchQuery = snapshotData['search_query'] as String?;
    _placeID = snapshotData['placeID'] as String?;
    _zipCode = castToType<int>(snapshotData['Zip_code']);
    _ownerFirstName = snapshotData['owner_first_name'] as String?;
    _ownerLastName = snapshotData['owner_last_name'] as String?;
    _businessName = snapshotData['business_name'] as String?;
    _phone = snapshotData['Phone'] as String?;
    _email = snapshotData['Email'] as String?;
    _state = snapshotData['State'] as String?;
    _coordinates = snapshotData['coordinates'] as LatLng?;
    _isOpen = snapshotData['is_open'] as bool?;
    _isVeteran = snapshotData['is_veteran'] as bool?;
    _isEcommerce = snapshotData['is_ecommerce'] as bool?;
    _verifiedCheckIns = snapshotData['verified_check_ins'] as String?;
    _socialShareConfig =
        castToType<Map<String, dynamic>>(snapshotData['social_share_config']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('businesses');

  static Stream<BusinessesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => BusinessesRecord.fromSnapshot(s));

  static Future<BusinessesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => BusinessesRecord.fromSnapshot(s));

  static BusinessesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      BusinessesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static BusinessesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      BusinessesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'BusinessesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is BusinessesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createBusinessesRecordData({
  bool? isBlackOwned,
  String? name,
  String? category,
  String? website,
  String? loyaltyOffer,
  String? tickerSymbol,
  String? heroImage,
  LatLng? businessLocation,
  String? address,
  bool? isBobVerified,
  bool? isActivelyPulsing,
  String? tierLevel,
  bool? hasPhysicalLocation,
  double? kindexScore,
  DocumentReference? owner,
  String? description,
  String? phoneNumber,
  bool? isPremium,
  bool? isFeatured,
  DateTime? createdAt,
  String? city,
  double? latitude,
  double? longitude,
  String? searchQuery,
  String? placeID,
  int? zipCode,
  String? ownerFirstName,
  String? ownerLastName,
  String? businessName,
  String? phone,
  String? email,
  String? state,
  LatLng? coordinates,
  bool? isOpen,
  bool? isVeteran,
  bool? isEcommerce,
  String? verifiedCheckIns,
  Map<String, dynamic>? socialShareConfig,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'is_black_owned': isBlackOwned,
      'name': name,
      'category': category,
      'website': website,
      'loyalty_offer': loyaltyOffer,
      'ticker_symbol': tickerSymbol,
      'hero_image': heroImage,
      'business_location': businessLocation,
      'address': address,
      'is_bob_verified': isBobVerified,
      'is_actively_pulsing': isActivelyPulsing,
      'tier_level': tierLevel,
      'has_physical_location': hasPhysicalLocation,
      'kindex_score': kindexScore,
      'owner': owner,
      'description': description,
      'phone_number': phoneNumber,
      'is_premium': isPremium,
      'is_featured': isFeatured,
      'created_at': createdAt,
      'city': city,
      'Latitude': latitude,
      'Longitude': longitude,
      'search_query': searchQuery,
      'placeID': placeID,
      'Zip_code': zipCode,
      'owner_first_name': ownerFirstName,
      'owner_last_name': ownerLastName,
      'business_name': businessName,
      'Phone': phone,
      'Email': email,
      'State': state,
      'coordinates': coordinates,
      'is_open': isOpen,
      'is_veteran': isVeteran,
      'is_ecommerce': isEcommerce,
      'verified_check_ins': verifiedCheckIns,
      'social_share_config': socialShareConfig,
    }.withoutNulls,
  );

  return firestoreData;
}

class BusinessesRecordDocumentEquality implements Equality<BusinessesRecord> {
  const BusinessesRecordDocumentEquality();

  @override
  bool equals(BusinessesRecord? e1, BusinessesRecord? e2) {
    return e1?.isBlackOwned == e2?.isBlackOwned &&
        e1?.name == e2?.name &&
        e1?.category == e2?.category &&
        e1?.website == e2?.website &&
        e1?.loyaltyOffer == e2?.loyaltyOffer &&
        e1?.tickerSymbol == e2?.tickerSymbol &&
        e1?.heroImage == e2?.heroImage &&
        e1?.businessLocation == e2?.businessLocation &&
        e1?.address == e2?.address &&
        e1?.isBobVerified == e2?.isBobVerified &&
        e1?.isActivelyPulsing == e2?.isActivelyPulsing &&
        e1?.tierLevel == e2?.tierLevel &&
        e1?.hasPhysicalLocation == e2?.hasPhysicalLocation &&
        e1?.kindexScore == e2?.kindexScore &&
        e1?.owner == e2?.owner &&
        e1?.description == e2?.description &&
        e1?.phoneNumber == e2?.phoneNumber &&
        e1?.isPremium == e2?.isPremium &&
        e1?.isFeatured == e2?.isFeatured &&
        e1?.createdAt == e2?.createdAt &&
        e1?.city == e2?.city &&
        e1?.latitude == e2?.latitude &&
        e1?.longitude == e2?.longitude &&
        e1?.searchQuery == e2?.searchQuery &&
        e1?.placeID == e2?.placeID &&
        e1?.zipCode == e2?.zipCode &&
        e1?.ownerFirstName == e2?.ownerFirstName &&
        e1?.ownerLastName == e2?.ownerLastName &&
        e1?.businessName == e2?.businessName &&
        e1?.phone == e2?.phone &&
        e1?.email == e2?.email &&
        e1?.state == e2?.state &&
        e1?.coordinates == e2?.coordinates &&
        e1?.isOpen == e2?.isOpen &&
        e1?.isVeteran == e2?.isVeteran &&
        e1?.isEcommerce == e2?.isEcommerce &&
        e1?.verifiedCheckIns == e2?.verifiedCheckIns &&
        const MapEquality().equals(
          e1?.socialShareConfig,
          e2?.socialShareConfig,
        );
  }

  @override
  int hash(BusinessesRecord? e) => const ListEquality().hash([
        e?.isBlackOwned,
        e?.name,
        e?.category,
        e?.website,
        e?.loyaltyOffer,
        e?.tickerSymbol,
        e?.heroImage,
        e?.businessLocation,
        e?.address,
        e?.isBobVerified,
        e?.isActivelyPulsing,
        e?.tierLevel,
        e?.hasPhysicalLocation,
        e?.kindexScore,
        e?.owner,
        e?.description,
        e?.phoneNumber,
        e?.isPremium,
        e?.isFeatured,
        e?.createdAt,
        e?.city,
        e?.latitude,
        e?.longitude,
        e?.searchQuery,
        e?.placeID,
        e?.zipCode,
        e?.ownerFirstName,
        e?.ownerLastName,
        e?.businessName,
        e?.phone,
        e?.email,
        e?.state,
        e?.coordinates,
        e?.isOpen,
        e?.isVeteran,
        e?.isEcommerce,
        e?.verifiedCheckIns,
        e?.socialShareConfig,
      ]);

  @override
  bool isValidKey(Object? o) => o is BusinessesRecord;
}
