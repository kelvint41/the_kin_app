import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class OrdersRecord extends FirestoreRecord {
  OrdersRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "delivery_status" field.
  int? _deliveryStatus;
  int get deliveryStatus => _deliveryStatus ?? 0;
  bool hasDeliveryStatus() => _deliveryStatus != null;

  // "business_name" field.
  String? _businessName;
  String get businessName => _businessName ?? '';
  bool hasBusinessName() => _businessName != null;

  // "delivery_address" field.
  String? _deliveryAddress;
  String get deliveryAddress => _deliveryAddress ?? '';
  bool hasDeliveryAddress() => _deliveryAddress != null;

  // "estimated_arrival" field.
  DateTime? _estimatedArrival;
  DateTime? get estimatedArrival => _estimatedArrival;
  bool hasEstimatedArrival() => _estimatedArrival != null;

  // "driver_name" field.
  String? _driverName;
  String get driverName => _driverName ?? '';
  bool hasDriverName() => _driverName != null;

  // "tracking_url" field.
  String? _trackingUrl;
  String get trackingUrl => _trackingUrl ?? '';
  bool hasTrackingUrl() => _trackingUrl != null;

  void _initializeFields() {
    _deliveryStatus = castToType<int>(snapshotData['delivery_status']);
    _businessName = snapshotData['business_name'] as String?;
    _deliveryAddress = snapshotData['delivery_address'] as String?;
    _estimatedArrival = snapshotData['estimated_arrival'] as DateTime?;
    _driverName = snapshotData['driver_name'] as String?;
    _trackingUrl = snapshotData['tracking_url'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('orders');

  static Stream<OrdersRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => OrdersRecord.fromSnapshot(s));

  static Future<OrdersRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => OrdersRecord.fromSnapshot(s));

  static OrdersRecord fromSnapshot(DocumentSnapshot snapshot) => OrdersRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static OrdersRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      OrdersRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'OrdersRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is OrdersRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createOrdersRecordData({
  int? deliveryStatus,
  String? businessName,
  String? deliveryAddress,
  DateTime? estimatedArrival,
  String? driverName,
  String? trackingUrl,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'delivery_status': deliveryStatus,
      'business_name': businessName,
      'delivery_address': deliveryAddress,
      'estimated_arrival': estimatedArrival,
      'driver_name': driverName,
      'tracking_url': trackingUrl,
    }.withoutNulls,
  );

  return firestoreData;
}

class OrdersRecordDocumentEquality implements Equality<OrdersRecord> {
  const OrdersRecordDocumentEquality();

  @override
  bool equals(OrdersRecord? e1, OrdersRecord? e2) {
    return e1?.deliveryStatus == e2?.deliveryStatus &&
        e1?.businessName == e2?.businessName &&
        e1?.deliveryAddress == e2?.deliveryAddress &&
        e1?.estimatedArrival == e2?.estimatedArrival &&
        e1?.driverName == e2?.driverName &&
        e1?.trackingUrl == e2?.trackingUrl;
  }

  @override
  int hash(OrdersRecord? e) => const ListEquality().hash([
        e?.deliveryStatus,
        e?.businessName,
        e?.deliveryAddress,
        e?.estimatedArrival,
        e?.driverName,
        e?.trackingUrl
      ]);

  @override
  bool isValidKey(Object? o) => o is OrdersRecord;
}
