import '/components/black_owned_badge_widget.dart';
import '/components/cat_chip2_widget.dart';
import '/components/floating_search2_widget.dart';
import '/components/kin_bottom_nav2_widget.dart';
import '/components/verified_map_pin_widget.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'page3_san_antonio_discovery_map2_widget.dart'
    show Page3SanAntonioDiscoveryMap2Widget;
import 'package:flutter/material.dart';

class Page3SanAntonioDiscoveryMap2Model
    extends FlutterFlowModel<Page3SanAntonioDiscoveryMap2Widget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for GoogleMap widget.
  LatLng? googleMapsCenter;
  final googleMapsController = Completer<GoogleMapController>();
  // Model for VerifiedMapPin component.
  late VerifiedMapPinModel verifiedMapPinModel1;
  // Model for VerifiedMapPin component.
  late VerifiedMapPinModel verifiedMapPinModel2;
  // Model for VerifiedMapPin component.
  late VerifiedMapPinModel verifiedMapPinModel3;
  // Model for VerifiedMapPin component.
  late VerifiedMapPinModel verifiedMapPinModel4;
  // Model for VerifiedMapPin component.
  late VerifiedMapPinModel verifiedMapPinModel5;
  // Model for VerifiedMapPin component.
  late VerifiedMapPinModel verifiedMapPinModel6;
  // Model for VerifiedMapPin component.
  late VerifiedMapPinModel verifiedMapPinModel7;
  // Model for FloatingSearch2 component.
  late FloatingSearch2Model floatingSearch2Model;
  // Model for CatChip2 component.
  late CatChip2Model catChip2Model1;
  // Model for CatChip2 component.
  late CatChip2Model catChip2Model2;
  // Model for CatChip2 component.
  late CatChip2Model catChip2Model3;
  // Model for CatChip2 component.
  late CatChip2Model catChip2Model4;
  // Model for CatChip2 component.
  late CatChip2Model catChip2Model5;
  // Model for BlackOwnedBadge component.
  late BlackOwnedBadgeModel blackOwnedBadgeModel;
  // Model for KinBottomNav2 component.
  late KinBottomNav2Model kinBottomNav2Model;

  @override
  void initState(BuildContext context) {
    verifiedMapPinModel1 = createModel(context, () => VerifiedMapPinModel());
    verifiedMapPinModel2 = createModel(context, () => VerifiedMapPinModel());
    verifiedMapPinModel3 = createModel(context, () => VerifiedMapPinModel());
    verifiedMapPinModel4 = createModel(context, () => VerifiedMapPinModel());
    verifiedMapPinModel5 = createModel(context, () => VerifiedMapPinModel());
    verifiedMapPinModel6 = createModel(context, () => VerifiedMapPinModel());
    verifiedMapPinModel7 = createModel(context, () => VerifiedMapPinModel());
    floatingSearch2Model = createModel(context, () => FloatingSearch2Model());
    catChip2Model1 = createModel(context, () => CatChip2Model());
    catChip2Model2 = createModel(context, () => CatChip2Model());
    catChip2Model3 = createModel(context, () => CatChip2Model());
    catChip2Model4 = createModel(context, () => CatChip2Model());
    catChip2Model5 = createModel(context, () => CatChip2Model());
    blackOwnedBadgeModel = createModel(context, () => BlackOwnedBadgeModel());
    kinBottomNav2Model = createModel(context, () => KinBottomNav2Model());
  }

  @override
  void dispose() {
    verifiedMapPinModel1.dispose();
    verifiedMapPinModel2.dispose();
    verifiedMapPinModel3.dispose();
    verifiedMapPinModel4.dispose();
    verifiedMapPinModel5.dispose();
    verifiedMapPinModel6.dispose();
    verifiedMapPinModel7.dispose();
    floatingSearch2Model.dispose();
    catChip2Model1.dispose();
    catChip2Model2.dispose();
    catChip2Model3.dispose();
    catChip2Model4.dispose();
    catChip2Model5.dispose();
    blackOwnedBadgeModel.dispose();
    kinBottomNav2Model.dispose();
  }
}
