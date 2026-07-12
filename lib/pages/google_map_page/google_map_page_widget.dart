import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/business_preview_card_widget.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:math' show pi, sin, cos, sqrt, atan2;
import 'dart:ui';
import '/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'google_map_page_model.dart';
export 'google_map_page_model.dart';

/// Create a clean, modern, premium dark-themed Discover / Google Map page
/// called "GoogleMapPage" for The Kin App (Black-owned business directory
/// app).
///
/// Theme: Dark luxurious black background with gold and green accents.
///
/// Layout:
/// - Top: nothing but a floating hamburger menu button (top-left). Tapping
///   it opens a left Drawer holding the category filter options that used
///   to run across the top of the map as a chip row.
/// - Main area: Full Google Map with business markers (use custom
/// KinBusinessMapPinIcon for Black-owned businesses)
/// - Bottom: a compact, collapsible business carousel bound to the same
///   business list driving the map markers (no separate hardcoded cards).
///   Collapsed to a slim peek strip by default on mobile widths so the map
///   stays the primary focus; expandable by tapping the strip.
///
/// Bottom Navigation Bar: provided solely by the app-level persistent nav
/// shell (see components/kin_scaffold.dart, flutter_flow/nav/nav.dart's
/// kinTabShellRoute). This page does NOT set its own bottomNavigationBar.
/// The old standalone /googleMapPage route (still the target of several
/// context.pushNamed/goNamedAuth(GoogleMapPageWidget.routeName, ...) call
/// sites app-wide) now redirects straight to the shell's /map tab, so
/// every path into this page renders inside KinScaffold. The legacy
/// KinBottomNav2Widget this page used to render directly - a second,
/// non-shell-aware bottom bar that caused stacked bars when reached via
/// /map - has been removed from the codebase entirely.
///
/// Backend Query for the business list:
/// - Collection: businesses
/// - Filter: is_black_owned is equal to true (priority)
/// - Order By: is_priority_pinned descending, kindex_score descending,
/// business_location nearest to current user location
///
/// Make all navigation buttons and menu items fully functional with proper
/// Navigate To actions.
/// Ensure the page works for both customers and business owners.
class GoogleMapPageWidget extends StatefulWidget {
  const GoogleMapPageWidget({super.key});

  static String routeName = 'GoogleMapPage';
  static String routePath = '/googleMapPage';

  @override
  State<GoogleMapPageWidget> createState() => _GoogleMapPageWidgetState();
}

class _GoogleMapPageWidgetState extends State<GoogleMapPageWidget> {
  late GoogleMapPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Category filter, chosen from the drawer. `null` means "Near Me" / no
  // filter. This is UI selection state only, same as the original chip
  // row: neither the old chips nor this drawer match the label against the
  // business.category field (real category values are much more granular,
  // e.g. "Hair salon" / "Coffee shop" - see DISCOVERY_BLUEPRINT.md - so a
  // label like "Beauty" would need an explicit keyword-to-category mapping
  // decision before it could filter real data correctly).
  String? _selectedCategoryFilter;

  // Bottom business carousel: null = use the responsive default (collapsed
  // on mobile widths, expanded on wide/tablet widths); once the user taps
  // the strip, their explicit choice wins from then on.
  bool? _bottomSheetExpandedOverride;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => GoogleMapPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await ActivityLogsRecord.collection
          .doc()
          .set(createActivityLogsRecordData(
            eventType: 'page_view',
            userRef: currentUserReference,
            city: 'San Antonio',
            pageName: 'GoogleMapPage',
            sessionId: FFAppState().sessionId,
            timestamp: getCurrentTimestamp,
          ));
    });
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  // Straight-line (haversine) distance in miles. Replaces the previous
  // "distance" text, which either printed a raw LatLng tuple as a string
  // (a pre-existing bug) or a hardcoded fake value.
  double _milesBetween(LatLng a, LatLng b) {
    const earthRadiusMiles = 3958.8;
    double deg2rad(double deg) => deg * (pi / 180);
    final dLat = deg2rad(b.latitude - a.latitude);
    final dLng = deg2rad(b.longitude - a.longitude);
    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(deg2rad(a.latitude)) *
            cos(deg2rad(b.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(h), sqrt(1 - h));
    return earthRadiusMiles * c;
  }

  Widget _buildFilterTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String? value,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final selected = _selectedCategoryFilter == value;
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? theme.primaryBackground : theme.primaryText,
        size: 22.0,
      ),
      title: Text(
        label,
        style: theme.bodyMedium.override(
          font: GoogleFonts.plusJakartaSans(),
          color: selected ? theme.primaryBackground : theme.primaryText,
          letterSpacing: 0.0,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_rounded, color: theme.primaryBackground, size: 20.0)
          : null,
      tileColor: selected ? theme.tertiary : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      contentPadding: EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 0.0),
      onTap: () {
        safeSetState(() => _selectedCategoryFilter = value);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildFilterDrawer(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Drawer(
      backgroundColor: theme.secondaryBackground,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(20.0, 24.0, 20.0, 12.0),
              child: Text(
                'Filters',
                style: theme.headlineSmall.override(
                  font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  color: theme.primaryText,
                  letterSpacing: 0.0,
                ),
              ),
            ),
            _buildFilterTile(
              context: context,
              icon: Icons.near_me_rounded,
              label: 'Near Me',
              value: null,
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(20.0, 8.0, 20.0, 8.0),
              child: Divider(color: theme.alternate, height: 1.0),
            ),
            _buildFilterTile(
              context: context,
              icon: Icons.restaurant_rounded,
              label: 'Restaurants',
              value: 'Restaurants',
            ),
            _buildFilterTile(
              context: context,
              icon: Icons.content_cut_rounded,
              label: 'Beauty',
              value: 'Beauty',
            ),
            _buildFilterTile(
              context: context,
              icon: Icons.work_rounded,
              label: 'Professional',
              value: 'Professional',
            ),
            _buildFilterTile(
              context: context,
              icon: Icons.self_improvement_rounded,
              label: 'Wellness',
              value: 'Wellness',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHamburgerButton(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: 48.0,
      height: 48.0,
      decoration: BoxDecoration(
        color: Color(0xE6FFFFFF),
        borderRadius: BorderRadius.circular(9999.0),
        shape: BoxShape.rectangle,
        border: Border.all(color: theme.alternate, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8.0,
            offset: Offset(0.0, 2.0),
          ),
        ],
      ),
      alignment: AlignmentDirectional(0.0, 0.0),
      child: FlutterFlowIconButton(
        borderRadius: 8.0,
        buttonSize: 40.0,
        fillColor: Colors.transparent,
        icon: Icon(Icons.menu_rounded, color: theme.primaryText, size: 24.0),
        // Builder ensures the context is a descendant of the inner Scaffold
        // so Scaffold.of() resolves to *this* Scaffold, not KinScaffold's
        // outer shell.
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
    );
  }

  Widget _buildBottomBusinessSheet(
    BuildContext context,
    List<BusinessesRecord> businesses,
  ) {
    final theme = FlutterFlowTheme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final expanded = _bottomSheetExpandedOverride ?? !isMobile;
    final center = _model.mapGoogleMapsCenter ?? LatLng(29.4241, -98.4936);
    final nearby = businesses
        .where((b) => b.businessLocation != null)
        .take(10)
        .toList();

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 12.0),
        child: Container(
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: theme.alternate, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 12.0,
                offset: Offset(0.0, 4.0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(16.0),
                onTap: () => safeSetState(
                  () => _bottomSheetExpandedOverride = !expanded,
                ),
                child: Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(16.0, 10.0, 12.0, 10.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        nearby.isEmpty
                            ? 'No businesses nearby'
                            : 'Black-Owned Near You · ${nearby.length}',
                        style: theme.titleSmall.override(
                          font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold),
                          color: theme.primaryText,
                          letterSpacing: 0.0,
                        ),
                      ),
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_up_rounded,
                        color: theme.secondaryText,
                        size: 24.0,
                      ),
                    ],
                  ),
                ),
              ),
              if (expanded && nearby.isNotEmpty)
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
                  child: SizedBox(
                    height: 132.0,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
                      itemCount: nearby.length,
                      separatorBuilder: (_, __) => SizedBox(width: 12.0),
                      itemBuilder: (context, index) {
                        final business = nearby[index];
                        return GestureDetector(
                          onTap: () => context.pushNamed(
                            BusinessShowcaseWidget.routeName,
                            queryParameters: {
                              'businessRecord': serializeParam(
                                business,
                                ParamType.Document,
                              ),
                            }.withoutNulls,
                            extra: <String, dynamic>{
                              'businessRecord': business,
                            },
                          ),
                          child: BusinessPreviewCardWidget(
                            name: business.businessName.isNotEmpty
                                ? business.businessName
                                : null,
                            isPriority: business.isPriorityPinned,
                            category: business.category.isNotEmpty
                                ? business.category
                                : null,
                            rating: business.reviewScore > 0
                                ? formatNumber(
                                    business.reviewScore,
                                    formatType: FormatType.decimal,
                                    decimalType: DecimalType.periodDecimal,
                                  )
                                : null,
                            distance:
                                '${_milesBetween(center, business.businessLocation!).toStringAsFixed(1)} mi',
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

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
        List<BusinessesRecord> googleMapPageBusinessesRecordList =
            snapshot.data!;

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            resizeToAvoidBottomInset: false,
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            drawer: _buildFilterDrawer(context),
            body: Stack(
              alignment: AlignmentDirectional(-1.0, -1.0),
              children: [
                Container(
                  child: FlutterFlowGoogleMap(
                    controller: _model.mapGoogleMapsController,
                    onCameraIdle: (latLng) =>
                        _model.mapGoogleMapsCenter = latLng,
                    initialLocation: _model.mapGoogleMapsCenter ??=
                        LatLng(29.4241, -98.4936),
                    markers: googleMapPageBusinessesRecordList
                        // Some businesses (e.g. bulk-imported rows with
                        // corrupted source coordinates) have no
                        // business_location - skip them rather than
                        // crashing the whole map on a null pin location.
                        .where((record) => record.businessLocation != null)
                        .map(
                          (marker) => FlutterFlowMarker(
                            marker.reference.path,
                            marker.businessLocation!,
                            () async {
                              print(
                                  'GoogleMapPageWidget: business pin tapped (${marker.businessName})');
                              context.pushNamed(
                                BusinessShowcaseWidget.routeName,
                                queryParameters: {
                                  'businessRecord': serializeParam(
                                    marker,
                                    ParamType.Document,
                                  ),
                                }.withoutNulls,
                                extra: <String, dynamic>{
                                  'businessRecord': marker,
                                },
                              );
                            },
                          ),
                        )
                        .toList(),
                    markerColor: GoogleMarkerColor.violet,
                    mapType: MapType.normal,
                    style: GoogleMapStyle.standard,
                    initialZoom: 14.0,
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
                // Top of the map is clear except for this floating
                // hamburger button - category filters now live in the
                // drawer it opens (_buildFilterDrawer), not a chip row.
                //
                // Builder is required here so `innerCtx` is a descendant of
                // *this* Scaffold. Without it, `Scaffold.of(context)` from
                // the outer StreamBuilder context would resolve to
                // KinScaffold's shell Scaffold instead, silently doing
                // nothing or opening the wrong drawer.
                Align(
                  alignment: AlignmentDirectional(-1.0, -1.0),
                  child: SafeArea(
                    child: Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 0.0, 0.0),
                      child: Builder(
                        builder: (innerCtx) =>
                            _buildHamburgerButton(innerCtx),
                      ),
                    ),
                  ),
                ),
                // Compact, collapsible business carousel - replaces the old
                // wide static "Black-Owned Near You" row (and the stray
                // bronze location/sparkle icon that used to float over the
                // map center, which had no data binding or purpose and has
                // been removed outright).
                Align(
                  alignment: AlignmentDirectional(0.0, 1.0),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 88.0),
                    child: _buildBottomBusinessSheet(
                        context, googleMapPageBusinessesRecordList),
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
