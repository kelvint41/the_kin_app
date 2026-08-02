import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/flutter_flow_place_picker.dart';
import '/flutter_flow/place.dart';
import '/services/kin_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'location_beacon_modal_model.dart';
export 'location_beacon_modal_model.dart';

class LocationBeaconModalWidget extends StatefulWidget {
  const LocationBeaconModalWidget({
    super.key,
    required this.businessRef,
    required this.businessName,
  });

  final DocumentReference? businessRef;
  final String businessName;

  @override
  State<LocationBeaconModalWidget> createState() =>
      _LocationBeaconModalWidgetState();
}

class _LocationBeaconModalWidgetState extends State<LocationBeaconModalWidget> {
  late LocationBeaconModalModel _model;
  FFPlace? _selectedPlace;

  // Google Maps API key (same as other place pickers in the app)
  static const _kGoogleMapsApiKey = 'AIzaSyD1w4m7IaWva5Bxl9fsbsZgILC7R8wf_Go';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LocationBeaconModalModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_model.isSubmitting) return;

    if (_selectedPlace == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your location.')),
      );
      return;
    }

    final location = _selectedPlace!.name.isNotEmpty
        ? _selectedPlace!.name
        : _selectedPlace!.address;

    safeSetState(() => _model.isSubmitting = true);

    final now = DateTime.now();
    final expiresAt = _calculateExpiresAt(now);

    final result = await KinServices.startLocationBeacon(
      businessRef: widget.businessRef!,
      currentLocation: location.trim(),
      expiresAt: expiresAt,
      autoPost: _model.autoPost,
    );

    if (!mounted) return;
    safeSetState(() => _model.isSubmitting = false);

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location beacon activated!')),
    );
  }

  DateTime _calculateExpiresAt(DateTime now) {
    switch (_model.selectedDuration) {
      case 'Until 2 PM':
        final twopm = DateTime(now.year, now.month, now.day, 14, 0);
        return twopm.isAfter(now) ? twopm : twopm.add(const Duration(days: 1));
      case 'Until 5 PM':
        final fivepm = DateTime(now.year, now.month, now.day, 17, 0);
        return fivepm.isAfter(now) ? fivepm : fivepm.add(const Duration(days: 1));
      case 'All day':
        return DateTime(now.year, now.month, now.day + 1, 23, 59);
      default:
        return now.add(const Duration(hours: 4));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🚐 Location Beacon',
                style: FlutterFlowTheme.of(context).titleMedium.override(
                      font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                      ),
                      color: FlutterFlowTheme.of(context).primaryText,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Let customers find you today',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      font: GoogleFonts.plusJakartaSans(),
                      color: FlutterFlowTheme.of(context).secondaryText,
                      letterSpacing: 0.0,
                    ),
              ),
              const SizedBox(height: 24.0),
              Text(
                'Where are you today?',
                style: FlutterFlowTheme.of(context).labelMedium.override(
                      font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                      ),
                      color: FlutterFlowTheme.of(context).primaryText,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8.0),
              FlutterFlowPlacePicker(
                iOSGoogleMapsApiKey: _kGoogleMapsApiKey,
                androidGoogleMapsApiKey: _kGoogleMapsApiKey,
                webGoogleMapsApiKey: _kGoogleMapsApiKey,
                defaultText: _selectedPlace?.name ?? 'Search your location',
                buttonOptions: FFButtonOptions(
                  width: double.infinity,
                  height: 48.0,
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.plusJakartaSans(),
                        color: FlutterFlowTheme.of(context).primaryText,
                        letterSpacing: 0.0,
                      ),
                  elevation: 0.0,
                  borderSide: BorderSide(
                    color: FlutterFlowTheme.of(context).alternate,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                  hoverColor:
                      FlutterFlowTheme.of(context).secondaryBackground,
                  disabledColor: FlutterFlowTheme.of(context).alternate,
                ),
                onSelect: (place) {
                  safeSetState(() => _selectedPlace = place);
                },
              ),
              const SizedBox(height: 20.0),
              Text(
                'How long?',
                style: FlutterFlowTheme.of(context).labelMedium.override(
                      font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                      ),
                      color: FlutterFlowTheme.of(context).primaryText,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8.0),
              DropdownButtonFormField<String>(
                value: _model.selectedDuration,
                items: ['Until 2 PM', 'Until 5 PM', 'All day']
                    .map((e) => DropdownMenuItem<String>(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
                onChanged: (value) {
                  safeSetState(() => _model.selectedDuration = value);
                },
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.plusJakartaSans(),
                      color: FlutterFlowTheme.of(context).primaryText,
                      letterSpacing: 0.0,
                    ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: FlutterFlowTheme.of(context).alternate,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  contentPadding: const EdgeInsetsDirectional.fromSTEB(
                    12.0,
                    12.0,
                    12.0,
                    12.0,
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              SwitchListTile.adaptive(
                value: _model.autoPost,
                onChanged: (v) => safeSetState(() => _model.autoPost = v),
                contentPadding: EdgeInsets.zero,
                activeColor: FlutterFlowTheme.of(context).primary,
                title: Text(
                  'Auto-post to feed',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.plusJakartaSans(),
                        color: FlutterFlowTheme.of(context).primaryText,
                        letterSpacing: 0.0,
                      ),
                ),
              ),
              const SizedBox(height: 24.0),
              SizedBox(
                width: double.infinity,
                child: FFButtonWidget(
                  onPressed:
                      _model.isSubmitting ? null : () => _submit(),
                  text: _model.isSubmitting ? 'Broadcasting...' : 'Broadcast Now',
                  options: FFButtonOptions(
                    height: 48.0,
                    color: FlutterFlowTheme.of(context).primary,
                    textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                          font: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                          ),
                          color: FlutterFlowTheme.of(context).info,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w600,
                        ),
                    elevation: 0.0,
                    borderRadius: BorderRadius.circular(8.0),
                    disabledColor: FlutterFlowTheme.of(context).alternate,
                    disabledTextColor:
                        FlutterFlowTheme.of(context).secondaryText,
                  ),
                ),
              ),
              const SizedBox(height: 12.0),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: FlutterFlowTheme.of(context).titleSmall.override(
                          font: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                          ),
                          color: FlutterFlowTheme.of(context).primaryText,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
