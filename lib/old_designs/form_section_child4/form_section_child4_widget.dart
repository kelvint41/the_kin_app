import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'form_section_child4_model.dart';
export 'form_section_child4_model.dart';

class FormSectionChild4Widget extends StatefulWidget {
  const FormSectionChild4Widget({super.key});

  @override
  State<FormSectionChild4Widget> createState() =>
      _FormSectionChild4WidgetState();
}

class _FormSectionChild4WidgetState extends State<FormSectionChild4Widget> {
  late FormSectionChild4Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FormSectionChild4Model());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: Container(
            width: 80.0,
            height: 56.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.0),
              shape: BoxShape.rectangle,
              border: Border.all(
                color: FlutterFlowTheme.of(context).alternate,
                width: 1.0,
              ),
            ),
            child: Container(
              width: 300.0,
              height: 200.0,
              child: FlutterFlowGoogleMap(
                controller: _model.mapGoogleMapsController,
                onCameraIdle: (latLng) => _model.mapGoogleMapsCenter = latLng,
                initialLocation: _model.mapGoogleMapsCenter ??=
                    LatLng(40.7128, -74.006),
                markerColor: GoogleMarkerColor.violet,
                mapType: MapType.normal,
                style: GoogleMapStyle.standard,
                initialZoom: 12.0,
                allowInteraction: true,
                allowZoom: true,
                showZoomControls: false,
                showLocation: false,
                showCompass: false,
                showMapToolbar: false,
                showTraffic: false,
                centerMapOnMarkerTap: true,
                mapTakesGesturePreference: false,
              ),
            ),
          ),
        ),
      ].divide(SizedBox(width: 16.0)),
    );
  }
}
