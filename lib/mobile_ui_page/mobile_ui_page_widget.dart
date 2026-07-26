import '/backend/backend.dart';
import '/components/business_card5_widget.dart';
import '/components/category_chip2_widget.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mobile_ui_page_model.dart';
export 'mobile_ui_page_model.dart';

/// Create a mobile UI component for a dark-mode business directory feed and
/// map overlay.
///
/// - Theme: Deep charcoal background (#121212), dark green containers, and
/// gold/amber (#FFB300) text accents.
/// - Layout Requirements:
///   1. A horizontal scrollable choice chip or filter chip row with
/// categories ("Near Me", "Restaurants", "Beauty", "Professional",
/// "Wellness").
///   2. A vertical card list below the chips displaying business preview
/// cards.
///   3. Each card must include elements for an image, business name, star
/// rating, and an "Open Now" status badge.
///   4. Ensure standard mobile padding, clean rounded borders, and a modern
/// app aesthetic that overlays or sits neatly on a map view.
class MobileUiPageWidget extends StatefulWidget {
  const MobileUiPageWidget({super.key});

  static String routeName = 'MobileUiPage';
  static String routePath = '/mobileUiPage';

  @override
  State<MobileUiPageWidget> createState() => _MobileUiPageWidgetState();
}

class _MobileUiPageWidgetState extends State<MobileUiPageWidget> {
  late MobileUiPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MobileUiPageModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        resizeToAvoidBottomInset: false,
        backgroundColor: Color(0xFF121212),
        body: Stack(
          alignment: AlignmentDirectional(-1.0, -1.0),
          children: [
            Container(
              child: FlutterFlowGoogleMap(
                controller: _model.mapGoogleMapsController,
                onCameraIdle: (latLng) => _model.mapGoogleMapsCenter = latLng,
                initialLocation: _model.mapGoogleMapsCenter ??=
                    LatLng(29.4241, -98.4936),
                markerColor: GoogleMarkerColor.red,
                mapType: MapType.normal,
                style: GoogleMapStyle.standard,
                initialZoom: 14.0,
                allowInteraction: true,
                allowZoom: true,
                showZoomControls: false,
                showLocation: true,
                showCompass: false,
                showMapToolbar: false,
                showTraffic: false,
                centerMapOnMarkerTap: true,
                mapTakesGesturePreference: false,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF121212), Color(0x00121212)],
                      stops: [0.0, 1.0],
                      begin: AlignmentDirectional(0.0, -1.0),
                      end: AlignmentDirectional(0, 1.0),
                    ),
                    shape: BoxShape.rectangle,
                  ),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(16.0, 24.0, 16.0, 16.0),
                    child: Container(
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          FlutterFlowIconButton(
                            borderRadius: 24.0,
                            buttonSize: 40.0,
                            fillColor: Color(0xFF1B3320),
                            icon: Icon(
                              Icons.tune_rounded,
                              color: Color(0xFFFFB300),
                              size: 24.0,
                            ),
                            onPressed: () {
                              print('IconButton pressed ...');
                            },
                          ),
                        ].divide(SizedBox(width: 16.0)),
                      ),
                    ),
                  ),
                ),
                Container(
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                    child: Container(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 0.0),
                              child: Container(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    wrapWithModel(
                                      model: _model.categoryChipModel1,
                                      updateCallback: () => safeSetState(() {}),
                                      child: CategoryChip2Widget(
                                        label: 'Near Me',
                                        selected: true,
                                      ),
                                    ),
                                    InkWell(
                                      splashColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        _model.selectedCategory = 'Restaurants';
                                        safeSetState(() {});
                                      },
                                      child: wrapWithModel(
                                        model: _model.categoryChipModel2,
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                        child: CategoryChip2Widget(
                                          label: 'Restaurants',
                                          selected: false,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      splashColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        _model.selectedCategory = 'Beauty';
                                        safeSetState(() {});
                                      },
                                      child: wrapWithModel(
                                        model: _model.categoryChipModel3,
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                        child: CategoryChip2Widget(
                                          label: 'Beauty',
                                          selected: false,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      splashColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        _model.selectedCategory =
                                            'Professional';
                                        safeSetState(() {});
                                      },
                                      child: wrapWithModel(
                                        model: _model.categoryChipModel4,
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                        child: CategoryChip2Widget(
                                          label: 'Professional',
                                          selected: false,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      splashColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        _model.selectedCategory = 'Wellness';
                                        safeSetState(() {});
                                      },
                                      child: wrapWithModel(
                                        model: _model.categoryChipModel5,
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                        child: CategoryChip2Widget(
                                          label: 'Wellness',
                                          selected: false,
                                        ),
                                      ),
                                    ),
                                  ].divide(SizedBox(width: 8.0)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Spacer(),
                Container(
                  height: 420.0,
                  decoration: BoxDecoration(
                    color: Color(0xFF121212),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24.0),
                      topRight: Radius.circular(24.0),
                    ),
                    shape: BoxShape.rectangle,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 1.0,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.rectangle,
                        ),
                      ),
                      Container(
                        height: 419.0,
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 16.0, 0.0, 16.0),
                              child: Container(
                                alignment: AlignmentDirectional(0.0, 0.0),
                                child: Container(
                                  width: 40.0,
                                  height: 4.0,
                                  decoration: BoxDecoration(
                                    color:
                                        FlutterFlowTheme.of(context).alternate,
                                    borderRadius: BorderRadius.circular(9999.0),
                                    shape: BoxShape.rectangle,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 0.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Featured Near You',
                                    style: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .override(
                                          font: GoogleFonts.plusJakartaSans(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFFFFB300),
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .titleMedium
                                                  .fontWeight,
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
                                              .secondaryText,
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
                            Expanded(
                              flex: 1,
                              child: Container(
                                child: SingleChildScrollView(
                                  primary: false,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            24.0, 0.0, 24.0, 0.0),
                                        child: Container(
                                          child: StreamBuilder<
                                              List<BusinessesRecord>>(
                                            stream: queryBusinessesRecord(
                                              queryBuilder:
                                                  (businessesRecord) =>
                                                      businessesRecord
                                                          .where(
                                                            'category',
                                                            isEqualTo: _model
                                                                        .selectedCategory ==
                                                                    'Near Me'
                                                                ? ''
                                                                : _model
                                                                    .selectedCategory,
                                                          )
                                                          .where(
                                                            'is_black_owned',
                                                            isEqualTo: true,
                                                          ),
                                            ),
                                            builder: (context, snapshot) {
                                              // Customize what your widget looks like when it's loading.
                                              if (!snapshot.hasData) {
                                                return Center(
                                                  child: SizedBox(
                                                    width: 50.0,
                                                    height: 50.0,
                                                    child:
                                                        CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                              Color>(
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primary,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }
                                              List<BusinessesRecord>
                                                  columnBusinessesRecordList =
                                                  snapshot.data!;

                                              return Column(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: List.generate(
                                                    columnBusinessesRecordList
                                                        .length, (columnIndex) {
                                                  final columnBusinessesRecord =
                                                      columnBusinessesRecordList[
                                                          columnIndex];
                                                  return BusinessCard5Widget(
                                                    key: Key(
                                                        'Keyffh_${columnIndex}_of_${columnBusinessesRecordList.length}'),
                                                    imgDesc:
                                                        'https://dimg.dreamflow.cloud/v1/image/cozy%20afrocentric%20bookstore%20cafe%20interior',
                                                    rating: '4.9',
                                                    name: 'Nile Cafe & Books',
                                                    distance: '0.8 mi',
                                                    category:
                                                        'Cafe • Cultural Hub',
                                                  );
                                                }).divide(
                                                    SizedBox(height: 16.0)),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF121212),
                    shape: BoxShape.rectangle,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 1.0,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).alternate,
                          shape: BoxShape.rectangle,
                        ),
                      ),
                      Container(
                        width: 0.0,
                        height: 0.0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
