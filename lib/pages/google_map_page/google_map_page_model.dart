import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'google_map_page_widget.dart' show GoogleMapPageWidget;
import 'package:flutter/material.dart';

class GoogleMapPageModel extends FlutterFlowModel<GoogleMapPageWidget> {
  ///  Local state fields for this page.

  String selectedCategory = 'Restaurants';

  ///  State fields for stateful widgets in this page.

  // State field(s) for Map Google Map widget.
  LatLng? mapGoogleMapsCenter;
  final mapGoogleMapsController = Completer<GoogleMapController>();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
