import '/components/gold_map_pin_widget.dart';
import '/components/refined_preview_sheet_widget.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'business_preview_bottom_sheet_widget.dart'
    show BusinessPreviewBottomSheetWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class BusinessPreviewBottomSheetModel
    extends FlutterFlowModel<BusinessPreviewBottomSheetWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for GoogleMap widget.
  LatLng? googleMapsCenter;
  final googleMapsController = Completer<GoogleMapController>();
  // Model for GoldMapPin component.
  late GoldMapPinModel goldMapPinModel;
  // Model for RefinedPreviewSheet component.
  late RefinedPreviewSheetModel refinedPreviewSheetModel;

  @override
  void initState(BuildContext context) {
    goldMapPinModel = createModel(context, () => GoldMapPinModel());
    refinedPreviewSheetModel =
        createModel(context, () => RefinedPreviewSheetModel());
  }

  @override
  void dispose() {
    goldMapPinModel.dispose();
    refinedPreviewSheetModel.dispose();
  }
}
