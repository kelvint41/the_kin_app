import '/flutter_flow/flutter_flow_util.dart';
import '/page_map_home/page_map_home.dart';
import 'package:flutter/material.dart';
import 'page3_san_antonio_discovery_map_model.dart';
export 'page3_san_antonio_discovery_map_model.dart';

class Page3SanAntonioDiscoveryMapWidget extends StatefulWidget {
  const Page3SanAntonioDiscoveryMapWidget({super.key});

  static String routeName = 'Page3SanAntonioDiscoveryMap';
  static String routePath = '/page3SanAntonioDiscoveryMap';

  @override
  State<Page3SanAntonioDiscoveryMapWidget> createState() =>
      _Page3SanAntonioDiscoveryMapWidgetState();
}

class _Page3SanAntonioDiscoveryMapWidgetState
    extends State<Page3SanAntonioDiscoveryMapWidget> {
  late Page3SanAntonioDiscoveryMapModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Page3SanAntonioDiscoveryMapModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      body: PageMapHome(
        floatingSearchModel: _model.floatingSearchModel,
        kinBottomNavModel: _model.kinBottomNavModel,
        googleMapsController: _model.googleMapsController,
        externalFeedPayload: _model.externalFeedPayload,
        googleMapsCenter: _model.googleMapsCenter,
        onGoogleMapsCenterChanged: (latLng) =>
            _model.googleMapsCenter = latLng,
      ),
    );
  }
}
