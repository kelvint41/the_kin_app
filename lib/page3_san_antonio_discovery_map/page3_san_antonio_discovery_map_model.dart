import '/backend/backend.dart';
import '/components/floating_search_widget.dart';
import '/components/kin_bottom_nav_widget.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'page3_san_antonio_discovery_map_widget.dart'
    show Page3SanAntonioDiscoveryMapWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';

class Page3SanAntonioDiscoveryMapModel
    extends FlutterFlowModel<Page3SanAntonioDiscoveryMapWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for GoogleMap widget.
  LatLng? googleMapsCenter;
  final googleMapsController = Completer<GoogleMapController>();
  // Model for FloatingSearch component.
  late FloatingSearchModel floatingSearchModel;
  // Model for KinBottomNav component.
  late KinBottomNavModel kinBottomNavModel;
  /// Optional partner/API payload merged on top of Firestore map data.
  List<Map<String, dynamic>> externalFeedPayload = [];

  @override
  void initState(BuildContext context) {
    floatingSearchModel = createModel(context, () => FloatingSearchModel());
    kinBottomNavModel = createModel(context, () => KinBottomNavModel());
  }

  @override
  void dispose() {
    floatingSearchModel.dispose();
    kinBottomNavModel.dispose();
  }
}
