import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/business_item_widget.dart';
import '/components/kpi_card_widget.dart';
import '/components/signup_item_widget.dart';
import '/flutter_flow/flutter_flow_charts.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import '/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'executive_dashboard_model.dart';
export 'executive_dashboard_model.dart';

/// Build a professional, mobile Executive Analytics Dashboard named
/// "Executive_Dashboard" for a directory app.
///
/// The page structure must avoid primary scroll conflicts by wrapping the
/// body contents into a single outer vertical ListView with Primary set to
/// true, and any nested list structures utilizing shrinkWrap: true with
/// NeverScrollableScrollPhysics.
///
/// The dashboard layout elements should be structured down the page as
/// follows:
/// 1. An AppBar containing the title "Executive Dashboard", a Refresh Button
/// icon, and a DropdownButton styled city selector (defaulting to 'San
/// Antonio' with options for Houston and Atlanta).
/// 2. A KPI Stat Cards Section: A horizontally scrollable row displaying 4
/// distinct micro-containers representing stats for Total Users, Businesses
/// Listed, Black-Owned, and Elite/Pro Subscribers. Each card displays a
/// prominent large integer value and a small descriptive text label.
/// 3. A 7-Day Activity Line Chart Section: A card layout displaying
/// FlutterFlow's native LineChart component mapped to track a series of dates
/// on the X-axis, with distinct colored line streams tracking total page
/// views, profile views, and new user registrations.
/// 4. A Category Breakdown Bar Chart Section: A container layout with an
/// explicit height of 220 pixels containing FlutterFlow's native BarChart
/// component mapping category names on the X-axis against total view count
/// integers on the Y-axis.
/// 5. A Top Businesses Feed Section: A clean vertical title label "Top
/// Explored Businesses" followed by a nested ListView showing a max of 5 list
/// item entries. Each row features a profile image circle avatar, business
/// name text string, category subtitle text, and a right-aligned action count
/// badge showing view totals.
/// 6. A Recent Registrations Feed Section: A final list feed section titled
/// "Recent Signups" mapping a direct firestore query limited to 10 entries
/// displaying user name strings, city fields, and user status type badges.
class ExecutiveDashboardWidget extends StatefulWidget {
  const ExecutiveDashboardWidget({super.key});

  static String routeName = 'Executive_Dashboard';
  static String routePath = '/executiveDashboard';

  @override
  State<ExecutiveDashboardWidget> createState() =>
      _ExecutiveDashboardWidgetState();
}

class _ExecutiveDashboardWidgetState extends State<ExecutiveDashboardWidget> {
  late ExecutiveDashboardModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ExecutiveDashboardModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.userDocument =
          await UsersRecord.getDocumentOnce(currentUserReference!);
      if (_model.userDocument?.isAdmin == false) {
        context.goNamed(OnboardingSelectionCardWidget.routeName);
      } else {
        await launchURL(
            'https://calendar.google.com/calendar/render?action=TEMPLATE&text=San+Antonio+Trial+Assessment+Review&details=Reviewing+operational+beta+metrics+and+analytics+for+the+directory+app.');
      }
    });
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return StreamBuilder<List<ActivityLogsRecord>>(
      stream: queryActivityLogsRecord(
        queryBuilder: (activityLogsRecord) => activityLogsRecord.where(
          'city',
          isEqualTo: 'San Antonio',
        ),
      ),
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
        List<ActivityLogsRecord> executiveDashboardActivityLogsRecordList =
            snapshot.data!;

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            appBar: AppBar(
              backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
              automaticallyImplyLeading: false,
              title: Text(
                'Executive Dashboard',
                style: FlutterFlowTheme.of(context).titleLarge.override(
                      font: GoogleFonts.plusJakartaSans(
                        fontWeight:
                            FlutterFlowTheme.of(context).titleLarge.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).titleLarge.fontStyle,
                      ),
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).titleLarge.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).titleLarge.fontStyle,
                      lineHeight: 1.4,
                    ),
              ),
              actions: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FlutterFlowIconButton(
                      borderRadius: 8.0,
                      buttonSize: 40.0,
                      fillColor: Colors.transparent,
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: FlutterFlowTheme.of(context).primaryText,
                        size: 24.0,
                      ),
                      onPressed: () {
                        print('IconButton pressed ...');
                      },
                    ),
                    Expanded(
                      flex: 1,
                      child: FlutterFlowDropDown<String>(
                        controller: _model.dropdownValueController ??=
                            FormFieldController<String>(
                          _model.dropdownValue ??= 'San Antonio',
                        ),
                        options: ['San Antonio', 'Houston', 'Atlanta'],
                        onChanged: (val) =>
                            safeSetState(() => _model.dropdownValue = val),
                        height: 40.0,
                        textStyle: FlutterFlowTheme.of(context)
                            .bodyMedium
                            .override(
                              font: GoogleFonts.plusJakartaSans(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: FlutterFlowTheme.of(context).secondaryText,
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                              lineHeight: 1.4,
                            ),
                        hintText: 'San Antonio',
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: FlutterFlowTheme.of(context).secondaryText,
                          size: 24.0,
                        ),
                        fillColor: Colors.transparent,
                        elevation: 2.0,
                        borderColor: FlutterFlowTheme.of(context).alternate,
                        borderWidth: 1.0,
                        borderRadius: 14.0,
                        margin: EdgeInsetsDirectional.fromSTEB(
                            16.0, 0.0, 16.0, 0.0),
                        hidesUnderline: true,
                        isOverButton: false,
                        isSearchable: false,
                        isMultiSelect: false,
                      ),
                    ),
                  ].divide(SizedBox(width: 8.0)),
                ),
              ],
              centerTitle: false,
              elevation: 0.0,
            ),
            body: SingleChildScrollView(
              primary: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Container(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'System Overview',
                                style: FlutterFlowTheme.of(context)
                                    .titleMedium
                                    .override(
                                      font: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                      lineHeight: 1.4,
                                    ),
                              ),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    wrapWithModel(
                                      model: _model.kpiCardModel1,
                                      updateCallback: () => safeSetState(() {}),
                                      child: KpiCardWidget(
                                        value:
                                            executiveDashboardActivityLogsRecordList
                                                .length
                                                .toString(),
                                        label: 'Total Users',
                                      ),
                                    ),
                                    FutureBuilder<int>(
                                      future: queryBusinessesRecordCount(),
                                      builder: (context, snapshot) {
                                        // Customize what your widget looks like when it's loading.
                                        if (!snapshot.hasData) {
                                          return Center(
                                            child: SizedBox(
                                              width: 50.0,
                                              height: 50.0,
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        int kpiCardCount = snapshot.data!;

                                        return wrapWithModel(
                                          model: _model.kpiCardModel2,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: KpiCardWidget(
                                            value:
                                                executiveDashboardActivityLogsRecordList
                                                    .where((e) =>
                                                        valueOrDefault<bool>(
                                                          e.isBlackOwned,
                                                          false,
                                                        ))
                                                    .toList()
                                                    .length
                                                    .toString(),
                                            label: 'Businesses',
                                          ),
                                        );
                                      },
                                    ),
                                    FutureBuilder<int>(
                                      future: queryBusinessesRecordCount(
                                        queryBuilder: (businessesRecord) =>
                                            businessesRecord.where(
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
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        int kpiCardCount = snapshot.data!;

                                        return wrapWithModel(
                                          model: _model.kpiCardModel3,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: KpiCardWidget(
                                            value: '892',
                                            label: 'Black-Owned',
                                          ),
                                        );
                                      },
                                    ),
                                    FutureBuilder<int>(
                                      future: queryUsersRecordCount(
                                        queryBuilder: (usersRecord) =>
                                            usersRecord.where(
                                          'subscription_status',
                                          isEqualTo: 'Elite',
                                        ),
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
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        int kpiCardCount = snapshot.data!;

                                        return wrapWithModel(
                                          model: _model.kpiCardModel4,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: KpiCardWidget(
                                            value: '345',
                                            label: 'Elite/Pro',
                                          ),
                                        );
                                      },
                                    ),
                                  ].divide(SizedBox(width: 16.0)),
                                ),
                              ),
                            ].divide(SizedBox(height: 16.0)),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              borderRadius: BorderRadius.circular(24.0),
                              shape: BoxShape.rectangle,
                              border: Border.all(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 1.0,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Container(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      '7-Day Activity',
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
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.bold,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                            lineHeight: 1.4,
                                          ),
                                    ),
                                    Container(
                                      height: 200.0,
                                      child: Container(
                                        height: 200.0,
                                        child: FlutterFlowLineChart(
                                          data: [
                                            FFLineChartData(
                                              xData:
                                                  executiveDashboardActivityLogsRecordList
                                                      .map((d) => d.timestamp)
                                                      .toList(),
                                              yData:
                                                  executiveDashboardActivityLogsRecordList
                                                      .map((d) => d.timestamp)
                                                      .toList(),
                                              settings: LineChartBarData(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                                barWidth: 3.0,
                                                isCurved: true,
                                              ),
                                            )
                                          ],
                                          chartStylingInfo: ChartStylingInfo(
                                            backgroundColor: Colors.transparent,
                                            showBorder: false,
                                          ),
                                          axisBounds: AxisBounds(
                                            minX: 0.0,
                                            minY: 0.0,
                                            maxX: 16.0,
                                            maxY: 984.0,
                                          ),
                                          xLabels: ([
                                            'Mon',
                                            'Tue',
                                            'Wed',
                                            'Thu',
                                            'Fri',
                                            'Sat',
                                            'Sun'
                                          ])!,
                                          xAxisLabelInfo: AxisLabelInfo(
                                            showLabels: true,
                                            labelTextStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .override(
                                                      font: GoogleFonts
                                                          .playfairDisplay(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodySmall
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodySmall
                                                                .fontStyle,
                                                      ),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryText,
                                                      fontSize: 10.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontStyle,
                                                      lineHeight: 1.0,
                                                    ),
                                            reservedSize: 28.0,
                                          ),
                                          yAxisLabelInfo: AxisLabelInfo(
                                            reservedSize: 0.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ].divide(SizedBox(height: 16.0)),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              borderRadius: BorderRadius.circular(24.0),
                              shape: BoxShape.rectangle,
                              border: Border.all(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 1.0,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Container(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Category Breakdown',
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
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.bold,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                            lineHeight: 1.4,
                                          ),
                                    ),
                                    Container(
                                      height: 220.0,
                                      child: Container(
                                        height: 220.0,
                                        child: FlutterFlowLineChart(
                                          data: [],
                                          chartStylingInfo: ChartStylingInfo(
                                            backgroundColor: Colors.transparent,
                                            showBorder: false,
                                          ),
                                          axisBounds: AxisBounds(),
                                          xAxisLabelInfo: AxisLabelInfo(),
                                          yAxisLabelInfo: AxisLabelInfo(),
                                        ),
                                      ),
                                    ),
                                  ].divide(SizedBox(height: 16.0)),
                                ),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Top Explored Businesses',
                                style: FlutterFlowTheme.of(context)
                                    .titleMedium
                                    .override(
                                      font: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                      lineHeight: 1.4,
                                    ),
                              ),
                              StreamBuilder<List<BusinessesRecord>>(
                                stream: queryBusinessesRecord(
                                  queryBuilder: (businessesRecord) =>
                                      businessesRecord.orderBy(
                                          'interaction_count',
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
                                            FlutterFlowTheme.of(context)
                                                .primary,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  List<BusinessesRecord>
                                      listViewBusinessesRecordList =
                                      snapshot.data!;

                                  return ListView.separated(
                                    padding: EdgeInsets.zero,
                                    primary: false,
                                    shrinkWrap: true,
                                    scrollDirection: Axis.vertical,
                                    itemCount:
                                        listViewBusinessesRecordList.length,
                                    separatorBuilder: (_, __) =>
                                        SizedBox(height: 8.0),
                                    itemBuilder: (context, listViewIndex) {
                                      final listViewBusinessesRecord =
                                          listViewBusinessesRecordList[
                                              listViewIndex];
                                      return BusinessItemWidget(
                                        key: Key(
                                            'Keyq7h_${listViewIndex}_of_${listViewBusinessesRecordList.length}'),
                                        imgDesc:
                                            'https://dimg.dreamflow.cloud/v1/image/soul%20food%20plate',
                                        name: listViewBusinessesRecord
                                            .businessName,
                                        category:
                                            listViewBusinessesRecord.category,
                                        views: formatNumber(
                                          listViewBusinessesRecord
                                              .interactionCount,
                                          formatType: FormatType.compact,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ].divide(SizedBox(height: 16.0)),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Recent Signups',
                                style: FlutterFlowTheme.of(context)
                                    .titleMedium
                                    .override(
                                      font: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                      lineHeight: 1.4,
                                    ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  borderRadius: BorderRadius.circular(24.0),
                                  shape: BoxShape.rectangle,
                                  border: Border.all(
                                    color:
                                        FlutterFlowTheme.of(context).alternate,
                                    width: 1.0,
                                  ),
                                ),
                                child: StreamBuilder<List<UsersRecord>>(
                                  stream: queryUsersRecord(
                                    queryBuilder: (usersRecord) =>
                                        usersRecord.orderBy('created_time',
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
                                              FlutterFlowTheme.of(context)
                                                  .primary,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    List<UsersRecord> listViewUsersRecordList =
                                        snapshot.data!;

                                    return ListView.builder(
                                      padding: EdgeInsets.zero,
                                      primary: false,
                                      shrinkWrap: true,
                                      scrollDirection: Axis.vertical,
                                      itemCount: listViewUsersRecordList.length,
                                      itemBuilder: (context, listViewIndex) {
                                        final listViewUsersRecord =
                                            listViewUsersRecordList[
                                                listViewIndex];
                                        return SignupItemWidget(
                                          key: Key(
                                              'Keyx9e_${listViewIndex}_of_${listViewUsersRecordList.length}'),
                                          user: listViewUsersRecord.displayName,
                                          city: FFAppState().city,
                                          status: listViewUsersRecord
                                              .subscriptionStatus,
                                          statusColor:
                                              FlutterFlowTheme.of(context)
                                                  .secondary,
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ].divide(SizedBox(height: 16.0)),
                          ),
                        ].divide(SizedBox(height: 24.0)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
