import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Phase 1 (discovery only) showcase item - a product/service a business
/// posts, browsable in the Showcase rail/grid. `interest_count` is
/// server-only (see firestore.rules and showcase_interest.js); everything
/// else is owner-writable via KinServices.createBusinessItem/updateBusinessItem.
/// `price_display` is deliberately free text, not a numeric chargeable
/// amount - there is no checkout yet, and this keeps a future in-app
/// purchase phase additive rather than a schema break.
class BusinessItemsRecord extends FirestoreRecord {
  BusinessItemsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "business_ref" field.
  DocumentReference? _businessRef;
  DocumentReference? get businessRef => _businessRef;
  bool hasBusinessRef() => _businessRef != null;

  // "title" field.
  String? _title;
  String get title => _title ?? '';
  bool hasTitle() => _title != null;

  // "description" field.
  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  // "price_display" field.
  String? _priceDisplay;
  String get priceDisplay => _priceDisplay ?? '';
  bool hasPriceDisplay() => _priceDisplay != null;

  // "photo_url" field.
  String? _photoUrl;
  String get photoUrl => _photoUrl ?? '';
  bool hasPhotoUrl() => _photoUrl != null;

  // "category" field.
  String? _category;
  String get category => _category ?? '';
  bool hasCategory() => _category != null;

  // "is_available" field.
  bool? _isAvailable;
  bool get isAvailable => _isAvailable ?? true;
  bool hasIsAvailable() => _isAvailable != null;

  // "interest_count" field.
  int? _interestCount;
  int get interestCount => _interestCount ?? 0;
  bool hasInterestCount() => _interestCount != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "updated_at" field.
  DateTime? _updatedAt;
  DateTime? get updatedAt => _updatedAt;
  bool hasUpdatedAt() => _updatedAt != null;

  void _initializeFields() {
    _businessRef = snapshotData['business_ref'] as DocumentReference?;
    _title = snapshotData['title'] as String?;
    _description = snapshotData['description'] as String?;
    _priceDisplay = snapshotData['price_display'] as String?;
    _photoUrl = snapshotData['photo_url'] as String?;
    _category = snapshotData['category'] as String?;
    _isAvailable = snapshotData['is_available'] as bool?;
    _interestCount = castToType<int>(snapshotData['interest_count']);
    _createdAt = snapshotData['created_at'] as DateTime?;
    _updatedAt = snapshotData['updated_at'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('business_items');

  static Stream<BusinessItemsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => BusinessItemsRecord.fromSnapshot(s));

  static Future<BusinessItemsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => BusinessItemsRecord.fromSnapshot(s));

  static BusinessItemsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      BusinessItemsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static BusinessItemsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      BusinessItemsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'BusinessItemsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is BusinessItemsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createBusinessItemsRecordData({
  DocumentReference? businessRef,
  String? title,
  String? description,
  String? priceDisplay,
  String? photoUrl,
  String? category,
  bool? isAvailable,
  int? interestCount,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'business_ref': businessRef,
      'title': title,
      'description': description,
      'price_display': priceDisplay,
      'photo_url': photoUrl,
      'category': category,
      'is_available': isAvailable,
      'interest_count': interestCount,
      'created_at': createdAt,
      'updated_at': updatedAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class BusinessItemsRecordDocumentEquality
    implements Equality<BusinessItemsRecord> {
  const BusinessItemsRecordDocumentEquality();

  @override
  bool equals(BusinessItemsRecord? e1, BusinessItemsRecord? e2) {
    return e1?.businessRef == e2?.businessRef &&
        e1?.title == e2?.title &&
        e1?.description == e2?.description &&
        e1?.priceDisplay == e2?.priceDisplay &&
        e1?.photoUrl == e2?.photoUrl &&
        e1?.category == e2?.category &&
        e1?.isAvailable == e2?.isAvailable &&
        e1?.interestCount == e2?.interestCount &&
        e1?.createdAt == e2?.createdAt &&
        e1?.updatedAt == e2?.updatedAt;
  }

  @override
  int hash(BusinessItemsRecord? e) => const ListEquality().hash([
        e?.businessRef,
        e?.title,
        e?.description,
        e?.priceDisplay,
        e?.photoUrl,
        e?.category,
        e?.isAvailable,
        e?.interestCount,
        e?.createdAt,
        e?.updatedAt,
      ]);

  @override
  bool isValidKey(Object? o) => o is BusinessItemsRecord;
}
