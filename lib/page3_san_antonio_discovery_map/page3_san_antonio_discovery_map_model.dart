import '/components/floating_search_widget.dart';
import '/components/kin_bottom_nav_widget.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'page3_san_antonio_discovery_map_widget.dart'
    show Page3SanAntonioDiscoveryMapWidget;
import 'package:flutter/material.dart';

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
