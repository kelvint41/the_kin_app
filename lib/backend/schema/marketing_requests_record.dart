import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class MarketingRequestsRecord extends FirestoreRecord {
  MarketingRequestsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "business_id" field.
  String? _businessId;
  String get businessId => _businessId ?? '';
  bool hasBusinessId() => _businessId != null;

  // "campaign_title" field.
  String? _campaignTitle;
  String get campaignTitle => _campaignTitle ?? '';
  bool hasCampaignTitle() => _campaignTitle != null;

  // "offer_details" field.
  String? _offerDetails;
  String get offerDetails => _offerDetails ?? '';
  bool hasOfferDetails() => _offerDetails != null;

  // "uploaded_image" field.
  String? _uploadedImage;
  String get uploadedImage => _uploadedImage ?? '';
  bool hasUploadedImage() => _uploadedImage != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  void _initializeFields() {
    _businessId = snapshotData['business_id'] as String?;
    _campaignTitle = snapshotData['campaign_title'] as String?;
    _offerDetails = snapshotData['offer_details'] as String?;
    _uploadedImage = snapshotData['uploaded_image'] as String?;
    _status = snapshotData['status'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('marketing_requests');

  static Stream<MarketingRequestsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => MarketingRequestsRecord.fromSnapshot(s));

  static Future<MarketingRequestsRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => MarketingRequestsRecord.fromSnapshot(s));

  static MarketingRequestsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      MarketingRequestsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static MarketingRequestsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      MarketingRequestsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'MarketingRequestsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is MarketingRequestsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createMarketingRequestsRecordData({
  String? businessId,
  String? campaignTitle,
  String? offerDetails,
  String? uploadedImage,
  String? status,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'business_id': businessId,
      'campaign_title': campaignTitle,
      'offer_details': offerDetails,
      'uploaded_image': uploadedImage,
      'status': status,
    }.withoutNulls,
  );

  return firestoreData;
}

class MarketingRequestsRecordDocumentEquality
    implements Equality<MarketingRequestsRecord> {
  const MarketingRequestsRecordDocumentEquality();

  @override
  bool equals(MarketingRequestsRecord? e1, MarketingRequestsRecord? e2) {
    return e1?.businessId == e2?.businessId &&
        e1?.campaignTitle == e2?.campaignTitle &&
        e1?.offerDetails == e2?.offerDetails &&
        e1?.uploadedImage == e2?.uploadedImage &&
        e1?.status == e2?.status;
  }

  @override
  int hash(MarketingRequestsRecord? e) => const ListEquality().hash([
        e?.businessId,
        e?.campaignTitle,
        e?.offerDetails,
        e?.uploadedImage,
        e?.status
      ]);

  @override
  bool isValidKey(Object? o) => o is MarketingRequestsRecord;
}
