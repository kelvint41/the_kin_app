import '/backend/backend.dart';
import '/components/floating_search_widget.dart';
import '/components/kin_bottom_nav_widget.dart';
import '/components/kin_map_brand_header.dart';
import '/components/kin_map_profile_preview.dart';
import '/data/kin_business_feed.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/models/kin_business_profile.dart';
import '/utils/kin_map_marker_icons.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

/// Map home screen. Businesses can carry both Black-owned and Veteran-owned
/// flags independently; markers and profile cards render both badges when set.
class PageMapHome extends StatefulWidget {
  const PageMapHome({
    super.key,
    required this.floatingSearchModel,
    required this.kinBottomNavModel,
    required this.googleMapsController,
    required this.externalFeedPayload,
    this.googleMapsCenter,
    this.onGoogleMapsCenterChanged,
  });

  final FloatingSearchModel floatingSearchModel;
  final KinBottomNavModel kinBottomNavModel;
  final Completer<GoogleMapController> googleMapsController;
  final List<Map<String, dynamic>> externalFeedPayload;
  final LatLng? googleMapsCenter;
  final ValueChanged<LatLng>? onGoogleMapsCenterChanged;

  @override
  State<PageMapHome> createState() => _PageMapHomeState();
}

class _PageMapHomeState extends State<PageMapHome> {
  String? _selectedProfileId;
  final Map<String, BitmapDescriptor> _markerIcons = {};

  @override
  void didUpdateWidget(covariant PageMapHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.externalFeedPayload != widget.externalFeedPayload) {
      _markerIcons.clear();
    }
  }

  Future<void> _ensureMarkerIcons(List<KinBusinessProfile> profiles) async {
    final combos = <String>{
      for (final profile in profiles)
        '${profile.isBlackOwned}|${profile.isVeteran}',
    };

    final missingCombos =
        combos.where((combo) => !_markerIcons.containsKey(combo)).toList();
    if (missingCombos.isEmpty) {
      return;
    }

    for (final combo in missingCombos) {
      final parts = combo.split('|');
      final icon = await KinMapMarkerIcons.forOwnership(
        isBlackOwned: parts[0] == 'true',
        isVeteran: parts[1] == 'true',
      );
      if (mounted) {
        setState(() => _markerIcons[combo] = icon);
      }
    }
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
            _markerIcons['${profile.isBlackOwned}|${profile.isVeteran}'],
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
          externalPayload: widget.externalFeedPayload,
        );
        final selectedProfile = _selectedProfile(businessProfiles);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _ensureMarkerIcons(businessProfiles);
        });

        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          body: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                Align(
                  child: FlutterFlowGoogleMap(
                    controller: widget.googleMapsController,
                    onCameraIdle: widget.onGoogleMapsCenterChanged,
                    initialLocation: widget.googleMapsCenter ??
                        const LatLng(29.4241, -98.4936),
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
                    child: const KinMapBrandHeader(),
                  ),
                ),
                PointerInterceptor(
                  intercepting: isWeb,
                  child: wrapWithModel(
                    model: widget.floatingSearchModel,
                    updateCallback: () => safeSetState(() {}),
                    child: const FloatingSearchWidget(),
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
                      model: widget.kinBottomNavModel,
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
