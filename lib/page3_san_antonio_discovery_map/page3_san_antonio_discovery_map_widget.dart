import '/backend/backend.dart';
import '/components/floating_search_widget.dart';
import '/components/kin_bottom_nav_widget.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
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
    return StreamBuilder<List<BusinessesRecord>>(
      stream: queryBusinessesRecord(),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).primary,
                  ),
                ),
              ),
            ),
          );
        }
        List<BusinessesRecord> page3SanAntonioDiscoveryMapBusinessesRecordList =
            snapshot.data!;

        return Scaffold(
          key: scaffoldKey,
          resizeToAvoidBottomInset: false,
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          body: Container(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                Align(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: FlutterFlowGoogleMap(
                    controller: _model.googleMapsController,
                    onCameraIdle: (latLng) => _model.googleMapsCenter = latLng,
                    initialLocation: _model.googleMapsCenter ??=
                        LatLng(29.4241, -98.4936),
                    markers: page3SanAntonioDiscoveryMapBusinessesRecordList
                        .map(
                          (marker) => FlutterFlowMarker(
                            marker.reference.path,
                            marker.businessLocation!,
                          ),
                        )
                        .toList(),
                    markerColor: GoogleMarkerColor.violet,
                    mapType: MapType.normal,
                    style: GoogleMapStyle.retro,
                    initialZoom: 13.0,
                    allowInteraction: true,
                    allowZoom: true,
                    showZoomControls: true,
                    showLocation: true,
                    showCompass: false,
                    showMapToolbar: false,
                    showTraffic: false,
                    centerMapOnMarkerTap: true,
                    mapTakesGesturePreference: false,
                  ),
                ),
                PointerInterceptor(
                  intercepting: isWeb,
                  child: wrapWithModel(
                    model: _model.floatingSearchModel,
                    updateCallback: () => safeSetState(() {}),
                    child: FloatingSearchWidget(),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional(0.0, 1.0),
                  child: PointerInterceptor(
                    intercepting: isWeb,
                    child: wrapWithModel(
                      model: _model.kinBottomNavModel,
                      updateCallback: () => safeSetState(() {}),
                      child: KinBottomNavWidget(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
