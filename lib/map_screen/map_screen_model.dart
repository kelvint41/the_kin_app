import '/components/premium_business_pin_widget.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'map_screen_widget.dart' show MapScreenWidget;
import 'package:flutter/material.dart';

class MapScreenModel extends FlutterFlowModel<MapScreenWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for GoogleMap widget.
  LatLng? googleMapsCenter;
  final googleMapsController = Completer<GoogleMapController>();
  // Model for PremiumBusinessPin component.
  late PremiumBusinessPinModel premiumBusinessPinModel1;
  // Model for PremiumBusinessPin component.
  late PremiumBusinessPinModel premiumBusinessPinModel2;
  // Model for PremiumBusinessPin component.
  late PremiumBusinessPinModel premiumBusinessPinModel3;
  // Model for PremiumBusinessPin component.
  late PremiumBusinessPinModel premiumBusinessPinModel4;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {
    premiumBusinessPinModel1 =
        createModel(context, () => PremiumBusinessPinModel());
    premiumBusinessPinModel2 =
        createModel(context, () => PremiumBusinessPinModel());
    premiumBusinessPinModel3 =
        createModel(context, () => PremiumBusinessPinModel());
    premiumBusinessPinModel4 =
        createModel(context, () => PremiumBusinessPinModel());
  }

  @override
  void dispose() {
    premiumBusinessPinModel1.dispose();
    premiumBusinessPinModel2.dispose();
    premiumBusinessPinModel3.dispose();
    premiumBusinessPinModel4.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
