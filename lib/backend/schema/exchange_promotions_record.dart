import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ExchangePromotionsRecord extends FirestoreRecord {
  ExchangePromotionsRecord._(
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

  // "body" field.
  String? _body;
  String get body => _body ?? '';
  bool hasBody() => _body != null;

  // "image_url" field.
  String? _imageUrl;
  String get imageUrl => _imageUrl ?? '';
  bool hasImageUrl() => _imageUrl != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "expires_at" field.
  DateTime? _expiresAt;
  DateTime? get expiresAt => _expiresAt;
  bool hasExpiresAt() => _expiresAt != null;

  void _initializeFields() {
    _businessRef = snapshotData['business_ref'] as DocumentReference?;
    _title = snapshotData['title'] as String?;
    _body = snapshotData['body'] as String?;
    _imageUrl = snapshotData['image_url'] as String?;
    _createdAt = snapshotData['created_at'] as DateTime?;
    _expiresAt = snapshotData['expires_at'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('exchange_promotions');

  static Stream<ExchangePromotionsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ExchangePromotionsRecord.fromSnapshot(s));

  static Future<ExchangePromotionsRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => ExchangePromotionsRecord.fromSnapshot(s));

  static ExchangePromotionsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ExchangePromotionsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ExchangePromotionsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ExchangePromotionsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ExchangePromotionsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ExchangePromotionsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createExchangePromotionsRecordData({
  DocumentReference? businessRef,
  String? title,
  String? body,
  String? imageUrl,
  DateTime? createdAt,
  DateTime? expiresAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'business_ref': businessRef,
      'title': title,
      'body': body,
      'image_url': imageUrl,
      'created_at': createdAt,
      'expires_at': expiresAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class ExchangePromotionsRecordDocumentEquality
    implements Equality<ExchangePromotionsRecord> {
  const ExchangePromotionsRecordDocumentEquality();

  @override
  bool equals(ExchangePromotionsRecord? e1, ExchangePromotionsRecord? e2) {
    return e1?.businessRef == e2?.businessRef &&
        e1?.title == e2?.title &&
        e1?.body == e2?.body &&
        e1?.imageUrl == e2?.imageUrl &&
        e1?.createdAt == e2?.createdAt &&
        e1?.expiresAt == e2?.expiresAt;
  }

  @override
  int hash(ExchangePromotionsRecord? e) => const ListEquality().hash([
        e?.businessRef,
        e?.title,
        e?.body,
        e?.imageUrl,
        e?.createdAt,
        e?.expiresAt
      ]);

  @override
  bool isValidKey(Object? o) => o is ExchangePromotionsRecord;
}
