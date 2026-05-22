import '/backend/backend.dart';
import '/components/floating_search_widget.dart';
import '/components/kin_bottom_nav_widget.dart';
import '/components/kin_map_brand_header.dart';
import '/components/kin_map_profile_preview.dart';
import '/data/kin_business_feed.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/models/kin_business_profile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';
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
  String? _selectedProfileId;

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

  List<FlutterFlowMarker> _mapMarkers(List<KinBusinessProfile> profiles) {
    return profiles
        .where((profile) => profile.hasMapLocation)
        .map(
          (profile) => FlutterFlowMarker(
            profile.id,
            profile.location!,
            () async {
              safeSetState(() => _selectedProfileId = profile.id);
            },
          ),
        )
        .toList();
  }

  KinBusinessProfile? _selectedProfile(List<KinBusinessProfile> profiles) {
    if (_selectedProfileId == null) {
      return null;
    }

    for (final profile in profiles) {
      if (profile.id == _selectedProfileId) {
        return profile;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BusinessesRecord>>(
      stream: queryBusinessesRecord(),
      builder: (context, snapshot) {
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

        final businessProfiles = KinBusinessFeed.mergeProfiles(
          firestoreProfiles:
              KinBusinessFeed.profilesFromRecords(snapshot.data!),
          externalPayload: _model.externalFeedPayload,
        );
        final selectedProfile = _selectedProfile(businessProfiles);

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
                    markers: _mapMarkers(businessProfiles),
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
                Align(
                  alignment: AlignmentDirectional(0.0, -1.0),
                  child: PointerInterceptor(
                    intercepting: isWeb,
                    child: KinMapBrandHeader(),
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
                if (selectedProfile != null)
                  Align(
                    alignment: AlignmentDirectional(0.0, 1.0),
                    child: PointerInterceptor(
                      intercepting: isWeb,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 88.0),
                        child: KinMapProfilePreview(
                          profile: selectedProfile,
                          onDismiss: () =>
                              safeSetState(() => _selectedProfileId = null),
                        ),
                      ),
                    ),
                  ),
                Align(
                  alignment: AlignmentDirectional(0.0, 1.0),
                  child: PointerInterceptor(
                    intercepting: isWeb,
                    child: wrapWithModel(
                      model: _model.kinBottomNavModel,
                      updateCallback: () => safeSetState(() {}),
                      child: KinBottomNavWidget(
                        activeTab: KinBottomNavTab.map,
                      ),
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
