import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/business_preview_card_widget.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
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
/// - Top: Search TextField with placeholder "Search businesses..."
/// - Below search: Horizontal row of filter chips (Near Me, Restaurants,
/// Beauty, Professional, etc.)
/// - Main area: Full Google Map with business markers (use custom
/// KinBusinessMapPinIcon for Black-owned businesses)
/// - Bottom sheet or floating area: ListView of business cards (prioritized
/// for Black-owned)
/// - Top-right corner: Menu IconButton (three dots or hamburger) that opens a
/// Bottom Sheet with navigation options:
///   - The Exchange
///   - My Business / Profile
///   - Community Feed
///   - Power Hour Blast
///
/// Bottom Navigation Bar with 4 items:
///   - Discover (this page, active)
///   - The Exchange
///   - My Business
///   - Profile
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

  /// The hamburger menu's bottom sheet, per this page's own doc comment
  /// (top of this file): The Exchange / My Business / Community Feed /
  /// Power Hour Blast. The Exchange requires a real businessRef (its
  /// constructor force-unwraps it), so it's the only item gated on
  /// actually owning a business - the other three self-guard internally
  /// (OwnerProfileWidget and MobileCalledPowerPageWidget already show
  /// their own "set up your business" empty state; CommunityPrestigeWidget
  /// takes no business context at all).
  void _showMainMenu(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(theme.designToken.radius.lg),
              topRight: Radius.circular(theme.designToken.radius.lg),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  EdgeInsets.symmetric(vertical: theme.designToken.spacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40.0,
                    height: 4.0,
                    margin:
                        EdgeInsets.only(bottom: theme.designToken.spacing.md),
                    decoration: BoxDecoration(
                      color: theme.alternate,
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                  ListTile(
                    leading:
                        Icon(Icons.forum_outlined, color: theme.primaryText),
                    title: Text('The Exchange', style: theme.bodyLarge),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      final businessRef = currentUserDocument?.ownedBusiness;
                      if (businessRef == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Set up your business to access The Exchange.'),
                          ),
                        );
                        return;
                      }
                      context.pushNamed(
                        TheExchangeWidget.routeName,
                        queryParameters: {
                          'businessRef': serializeParam(
                            businessRef,
                            ParamType.DocumentReference,
                          ),
                        }.withoutNulls,
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.storefront_rounded,
                        color: theme.primaryText),
                    title:
                        Text('My Business / Profile', style: theme.bodyLarge),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.pushNamed(OwnerProfileWidget.routeName);
                    },
                  ),
                  ListTile(
                    leading:
                        Icon(Icons.groups_rounded, color: theme.primaryText),
                    title: Text('Community Feed', style: theme.bodyLarge),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.pushNamed(CommunityPrestigeWidget.routeName);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.bolt_rounded, color: theme.primaryText),
                    title: Text('Power Hour Blast', style: theme.bodyLarge),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.pushNamed(MobileCalledPowerPageWidget.routeName);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
                    FlutterFlowTheme.of(context).secondaryText,
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
                Align(
                  alignment: AlignmentDirectional(0.0, -1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          FlutterFlowTheme.of(context).primaryBackground,
                          Color(0x00FCFCFC)
                        ],
                        stops: [0.0, 1.0],
                        begin: AlignmentDirectional(0.0, -1.0),
                        end: AlignmentDirectional(0, 1.0),
                      ),
                      shape: BoxShape.rectangle,
                    ),
                    child: Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                          16.0, 24.0, 16.0, 24.0),
                      child: Container(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 48.0,
                                  height: 48.0,
                                  decoration: BoxDecoration(
                                    color: Color(0xE6FFFFFF),
                                    borderRadius: BorderRadius.circular(9999.0),
                                    shape: BoxShape.rectangle,
                                    border: Border.all(
                                      color: FlutterFlowTheme.of(context)
                                          .alternate,
                                      width: 1.0,
                                    ),
                                  ),
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: FlutterFlowIconButton(
                                    borderRadius: 8.0,
                                    buttonSize: 40.0,
                                    fillColor: Colors.transparent,
                                    icon: Icon(
                                      Icons.menu_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      size: 24.0,
                                    ),
                                    onPressed: () {
                                      _showMainMenu(context);
                                    },
                                  ),
                                ),
                              ].divide(SizedBox(width: 8.0)),
                            ),
                            StreamBuilder<List<BusinessesRecord>>(
                              stream: queryBusinessesRecord(
                                queryBuilder: (businessesRecord) =>
                                    businessesRecord
                                        .orderBy('is_black_owned',
                                            descending: true)
                                        .orderBy('is_priority_pinned',
                                            descending: true)
                                        .orderBy('kindex_score',
                                            descending: true),
                              ),
                              builder: (context, snapshot) {
                                // Customize what your widget looks like when it's loading.
                                if (!snapshot.hasData) {
                                  return Center(
                                    child: SizedBox(
                                      width: 50.0,
                                      height: 50.0,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          FlutterFlowTheme.of(context).secondaryText,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                List<BusinessesRecord> rowBusinessesRecordList =
                                    snapshot.data!;

                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: List.generate(
                                        rowBusinessesRecordList.length,
                                        (rowIndex) {
                                      final rowBusinessesRecord =
                                          rowBusinessesRecordList[rowIndex];
                                      return Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            4.0, 0.0, 0.0, 0.0),
                                        child: Container(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Container(
                                                height: 34.0,
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .tertiary,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                  border: Border.all(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .alternate,
                                                    width: 1.0,
                                                  ),
                                                ),
                                                alignment: AlignmentDirectional(
                                                    0.0, 0.0),
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          12.0, 0.0, 12.0, 0.0),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.check_rounded,
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .primaryBackground,
                                                        size: 16.0,
                                                      ),
                                                      Text(
                                                        'Near Me',
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .plusJakartaSans(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryBackground,
                                                                  fontSize:
                                                                      14.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontStyle,
                                                                  lineHeight:
                                                                      1.4,
                                                                ),
                                                      ),
                                                    ].divide(
                                                        SizedBox(width: 6.0)),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                height: 34.0,
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                  border: Border.all(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .alternate,
                                                    width: 1.0,
                                                  ),
                                                ),
                                                alignment: AlignmentDirectional(
                                                    0.0, 0.0),
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          12.0, 0.0, 12.0, 0.0),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .restaurant_rounded,
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primaryText,
                                                        size: 18.0,
                                                      ),
                                                      Text(
                                                        'Restaurants',
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .plusJakartaSans(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                  fontSize:
                                                                      14.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontStyle,
                                                                  lineHeight:
                                                                      1.4,
                                                                ),
                                                      ),
                                                    ].divide(
                                                        SizedBox(width: 6.0)),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                height: 34.0,
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                  border: Border.all(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .alternate,
                                                    width: 1.0,
                                                  ),
                                                ),
                                                alignment: AlignmentDirectional(
                                                    0.0, 0.0),
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          12.0, 0.0, 12.0, 0.0),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .content_cut_rounded,
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primaryText,
                                                        size: 18.0,
                                                      ),
                                                      Text(
                                                        'Beauty',
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .plusJakartaSans(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                  fontSize:
                                                                      14.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontStyle,
                                                                  lineHeight:
                                                                      1.4,
                                                                ),
                                                      ),
                                                    ].divide(
                                                        SizedBox(width: 6.0)),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                height: 34.0,
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                  border: Border.all(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .alternate,
                                                    width: 1.0,
                                                  ),
                                                ),
                                                alignment: AlignmentDirectional(
                                                    0.0, 0.0),
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          12.0, 0.0, 12.0, 0.0),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.work_rounded,
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primaryText,
                                                        size: 18.0,
                                                      ),
                                                      Text(
                                                        'Professional',
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .plusJakartaSans(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                  fontSize:
                                                                      14.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontStyle,
                                                                  lineHeight:
                                                                      1.4,
                                                                ),
                                                      ),
                                                    ].divide(
                                                        SizedBox(width: 6.0)),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                height: 34.0,
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                  border: Border.all(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .alternate,
                                                    width: 1.0,
                                                  ),
                                                ),
                                                alignment: AlignmentDirectional(
                                                    0.0, 0.0),
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          12.0, 0.0, 12.0, 0.0),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .self_improvement_rounded,
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primaryText,
                                                        size: 18.0,
                                                      ),
                                                      Text(
                                                        'Wellness',
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .plusJakartaSans(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                  fontSize:
                                                                      14.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontStyle,
                                                                  lineHeight:
                                                                      1.4,
                                                                ),
                                                      ),
                                                    ].divide(
                                                        SizedBox(width: 6.0)),
                                                  ),
                                                ),
                                              ),
                                            ].divide(SizedBox(width: 8.0)),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                );
                              },
                            ),
                          ].divide(SizedBox(height: 16.0)),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional(0.1, -0.2),
                  child: Container(
                    width: 40.0,
                    height: 40.0,
                    child: Stack(
                      alignment: AlignmentDirectional(0.0, 0.0),
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: FlutterFlowTheme.of(context).tertiary,
                          size: 40.0,
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 0.0, 6.0),
                          child: Container(
                            child: Container(
                              width: 20.0,
                              height: 20.0,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .primaryBackground,
                                borderRadius: BorderRadius.circular(9999.0),
                                shape: BoxShape.rectangle,
                              ),
                              alignment: AlignmentDirectional(0.0, 0.0),
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: FlutterFlowTheme.of(context).tertiary,
                                size: 12.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional(0.0, 1.0),
                  child: Container(
                    child: Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 100.0),
                      child: Container(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Black-Owned Near You',
                                    style: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .override(
                                          font: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.bold,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleMedium
                                                  .fontStyle,
                                          lineHeight: 1.4,
                                        ),
                                  ),
                                  Text(
                                    'See All',
                                    style: FlutterFlowTheme.of(context)
                                        .labelLarge
                                        .override(
                                          font: GoogleFonts.plusJakartaSans(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelLarge
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelLarge
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .tertiary,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .labelLarge
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelLarge
                                                  .fontStyle,
                                          lineHeight: 1.4,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 16.0, 0.0, 16.0),
                                    child: Container(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // All three cards read from the
                                          // businesses query. Card 1 used to
                                          // take its name/category from
                                          // FFAppState().businessname/.category,
                                          // which nothing in the app ever
                                          // assigns, so it fell through to the
                                          // widget's dummy defaults; cards 2 and
                                          // 3 were hardcoded literals. Each card
                                          // now renders only when a real record
                                          // exists at its index.
                                          //
                                          // `distance` is intentionally omitted:
                                          // it was previously passed the
                                          // business's LatLng, which rendered as
                                          // 'LatLng(lat: .., lng: ..)' and
                                          // overflowed the row. The app has no
                                          // user-location value or distance
                                          // helper, so the field stays hidden
                                          // until there's a real number.
                                          if (googleMapPageBusinessesRecordList
                                              .isNotEmpty)
                                            wrapWithModel(
                                              model: _model
                                                  .businessPreviewCardModel1,
                                              updateCallback: () =>
                                                  safeSetState(() {}),
                                              child: BusinessPreviewCardWidget(
                                                name:
                                                    googleMapPageBusinessesRecordList[
                                                            0]
                                                        .businessName,
                                                isPriority:
                                                    googleMapPageBusinessesRecordList[
                                                            0]
                                                        .isPriorityPinned,
                                                category:
                                                    googleMapPageBusinessesRecordList[
                                                            0]
                                                        .category,
                                                rating: formatNumber(
                                                  googleMapPageBusinessesRecordList[
                                                          0]
                                                      .reviewScore,
                                                  formatType:
                                                      FormatType.decimal,
                                                  decimalType:
                                                      DecimalType.periodDecimal,
                                                ),
                                                imageUrl:
                                                    googleMapPageBusinessesRecordList[
                                                            0]
                                                        .heroImage,
                                              ),
                                            ),
                                          if (googleMapPageBusinessesRecordList
                                                  .length >
                                              1)
                                            wrapWithModel(
                                              model: _model
                                                  .businessPreviewCardModel2,
                                              updateCallback: () =>
                                                  safeSetState(() {}),
                                              child: BusinessPreviewCardWidget(
                                                name:
                                                    googleMapPageBusinessesRecordList[
                                                            1]
                                                        .businessName,
                                                isPriority:
                                                    googleMapPageBusinessesRecordList[
                                                            1]
                                                        .isPriorityPinned,
                                                category:
                                                    googleMapPageBusinessesRecordList[
                                                            1]
                                                        .category,
                                                rating: formatNumber(
                                                  googleMapPageBusinessesRecordList[
                                                          1]
                                                      .reviewScore,
                                                  formatType:
                                                      FormatType.decimal,
                                                  decimalType:
                                                      DecimalType.periodDecimal,
                                                ),
                                                imageUrl:
                                                    googleMapPageBusinessesRecordList[
                                                            1]
                                                        .heroImage,
                                              ),
                                            ),
                                          if (googleMapPageBusinessesRecordList
                                                  .length >
                                              2)
                                            wrapWithModel(
                                              model: _model
                                                  .businessPreviewCardModel3,
                                              updateCallback: () =>
                                                  safeSetState(() {}),
                                              child: BusinessPreviewCardWidget(
                                                name:
                                                    googleMapPageBusinessesRecordList[
                                                            2]
                                                        .businessName,
                                                isPriority:
                                                    googleMapPageBusinessesRecordList[
                                                            2]
                                                        .isPriorityPinned,
                                                category:
                                                    googleMapPageBusinessesRecordList[
                                                            2]
                                                        .category,
                                                rating: formatNumber(
                                                  googleMapPageBusinessesRecordList[
                                                          2]
                                                      .reviewScore,
                                                  formatType:
                                                      FormatType.decimal,
                                                  decimalType:
                                                      DecimalType.periodDecimal,
                                                ),
                                                imageUrl:
                                                    googleMapPageBusinessesRecordList[
                                                            2]
                                                        .heroImage,
                                              ),
                                            ),
                                        ].divide(SizedBox(width: 16.0)),
                                      ),
                                    ),
                                  ),
                                  FlutterFlowIconButton(
                                    borderRadius: 8.0,
                                    buttonSize: 40.0,
                                    fillColor:
                                        FlutterFlowTheme.of(context).primary,
                                    icon: Icon(
                                      Icons.arrow_forward,
                                      color: FlutterFlowTheme.of(context).info,
                                      size: 24.0,
                                    ),
                                    onPressed: () async {
                                      // Previously matched against
                                      // FFAppState().businessname, which is
                                      // never set anywhere in the app - this
                                      // button could never navigate. The
                                      // first result of the same live query
                                      // backing this card row is what the
                                      // first preview card represents, so
                                      // that's the business this "explore"
                                      // arrow should open.
                                      final matchedBusinessRef =
                                          googleMapPageBusinessesRecordList
                                              .elementAtOrNull(0)
                                              ?.reference;
                                      if (matchedBusinessRef == null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'No nearby businesses to explore yet.'),
                                          ),
                                        );
                                        return;
                                      }
                                      context.pushNamed(
                                        TheExchangeWidget.routeName,
                                        queryParameters: {
                                          'businessRef': serializeParam(
                                            matchedBusinessRef,
                                            ParamType.DocumentReference,
                                          ),
                                        }.withoutNulls,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ].divide(SizedBox(height: 16.0)),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional(0.0, 1.0),
                  child: Container(
                    child: Container(
                      width: 0.0,
                      height: 0.0,
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: KinBottomNav2Widget(),
          ),
        );
      },
    );
  }
}
