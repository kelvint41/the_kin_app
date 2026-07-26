import '/backend/backend.dart';
import '/components/activity_item2_widget.dart';
import '/components/kpi_card2_widget.dart';
import '/flutter_flow/flutter_flow_charts.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'executive_dashboard1_model.dart';
export 'executive_dashboard1_model.dart';

/// "Create a dark-mode Executive Dashboard page for a business management
/// app.
///
/// The layout should be professional, clean, and data-heavy. Include the
/// following sections:
///
/// KPI Row: A row of 4 prominent summary cards:
///
/// 'Total Sessions' (displaying data from analytics_daily)
///
/// 'New Registrations' (displaying data from analytics_daily)
///
/// 'Active Orders' (displaying data from orders)
///
/// 'Total Visits' (displaying data from uservisits)
///
/// Charts Section: Two side-by-side charts: a line chart for 'Daily Traffic'
/// and a bar chart for 'Business Category Performance'.
///
/// Data Grid: A section titled 'Recent Activity' containing a list view
/// structured to show information from the activity_logs collection.
///
/// Filters: A top bar with a date picker and a location dropdown filter.
///
/// Styling: Use a sleek aesthetic with gold and yellow accents for numerical
/// highlights. Ensure the hierarchy of information is clear for mobile
/// users."
class ExecutiveDashboard1Widget extends StatefulWidget {
  const ExecutiveDashboard1Widget({super.key});

  static String routeName = 'Executive_Dashboard1';
  static String routePath = '/executiveDashboard1';

  @override
  State<ExecutiveDashboard1Widget> createState() =>
      _ExecutiveDashboard1WidgetState();
}

class _ExecutiveDashboard1WidgetState extends State<ExecutiveDashboard1Widget> {
  late ExecutiveDashboard1Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ExecutiveDashboard1Model());
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
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                shape: BoxShape.rectangle,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(24.0, 16.0, 24.0, 16.0),
                    child: Container(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Executive Dashboard',
                                style: FlutterFlowTheme.of(context)
                                    .titleLarge
                                    .override(
                                      font: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleLarge
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleLarge
                                          .fontStyle,
                                      lineHeight: 1.4,
                                    ),
                              ),
                              FlutterFlowIconButton(
                                borderRadius: 8.0,
                                buttonSize: 40.0,
                                fillColor: Colors.transparent,
                                icon: Icon(
                                  Icons.settings_suggest_rounded,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  size: 24.0,
                                ),
                                onPressed: () {
                                  print('IconButton pressed ...');
                                },
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                    borderRadius: BorderRadius.circular(14.0),
                                    shape: BoxShape.rectangle,
                                    border: Border.all(
                                      color: FlutterFlowTheme.of(context)
                                          .alternate,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        16.0, 8.0, 16.0, 8.0),
                                    child: Container(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.calendar_today_rounded,
                                            color: Color(0xFFFFD700),
                                            size: 16.0,
                                          ),
                                          Text(
                                            'Oct 1 - Oct 31, 2023',
                                            style: FlutterFlowTheme.of(context)
                                                .labelLarge
                                                .override(
                                                  font: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .labelLarge
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .labelLarge
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryText,
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelLarge
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelLarge
                                                          .fontStyle,
                                                  lineHeight: 1.4,
                                                ),
                                          ),
                                        ].divide(SizedBox(width: 8.0)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .primaryBackground,
                                  borderRadius: BorderRadius.circular(14.0),
                                  shape: BoxShape.rectangle,
                                  border: Border.all(
                                    color:
                                        FlutterFlowTheme.of(context).alternate,
                                    width: 1.0,
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      16.0, 8.0, 16.0, 8.0),
                                  child: Container(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          'All Locations',
                                          style: FlutterFlowTheme.of(context)
                                              .labelLarge
                                              .override(
                                                font:
                                                    GoogleFonts.plusJakartaSans(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelLarge
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelLarge
                                                          .fontStyle,
                                                ),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
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
                                        Icon(
                                          Icons.arrow_drop_down_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          size: 18.0,
                                        ),
                                      ].divide(SizedBox(width: 8.0)),
                                    ),
                                  ),
                                ),
                              ),
                            ].divide(SizedBox(width: 8.0)),
                          ),
                        ].divide(SizedBox(height: 16.0)),
                      ),
                    ),
                  ),
                  Container(
                    height: 1.0,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).alternate,
                      shape: BoxShape.rectangle,
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
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: StreamBuilder<
                                        List<AnalyticsDailyRecord>>(
                                      stream: queryAnalyticsDailyRecord(
                                        queryBuilder: (analyticsDailyRecord) =>
                                            analyticsDailyRecord.orderBy(
                                                'last_updated',
                                                descending: true),
                                        singleRecord: true,
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
                                        List<AnalyticsDailyRecord>
                                            kpiCardAnalyticsDailyRecordList =
                                            snapshot.data!;
                                        // Return an empty Container when the item does not exist.
                                        if (snapshot.data!.isEmpty) {
                                          return Container();
                                        }
                                        final kpiCardAnalyticsDailyRecord =
                                            kpiCardAnalyticsDailyRecordList
                                                    .isNotEmpty
                                                ? kpiCardAnalyticsDailyRecordList
                                                    .first
                                                : null;

                                        return wrapWithModel(
                                          model: _model.kpiCardModel1,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: KpiCard2Widget(
                                            icon: Icon(
                                              Icons.analytics_rounded,
                                              color: Color(0xFFFFD700),
                                              size: 18.0,
                                            ),
                                            value: '24.8k',
                                            label: 'Total Sessions',
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: StreamBuilder<
                                        List<AnalyticsDailyRecord>>(
                                      stream: queryAnalyticsDailyRecord(
                                        queryBuilder: (analyticsDailyRecord) =>
                                            analyticsDailyRecord.orderBy(
                                                'new_user_registrations'),
                                        singleRecord: true,
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
                                        List<AnalyticsDailyRecord>
                                            kpiCardAnalyticsDailyRecordList =
                                            snapshot.data!;
                                        // Return an empty Container when the item does not exist.
                                        if (snapshot.data!.isEmpty) {
                                          return Container();
                                        }
                                        final kpiCardAnalyticsDailyRecord =
                                            kpiCardAnalyticsDailyRecordList
                                                    .isNotEmpty
                                                ? kpiCardAnalyticsDailyRecordList
                                                    .first
                                                : null;

                                        return wrapWithModel(
                                          model: _model.kpiCardModel2,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: KpiCard2Widget(
                                            icon: Icon(
                                              Icons.person_add_rounded,
                                              color: Color(0xFFFFD700),
                                              size: 18.0,
                                            ),
                                            value: kpiCardAnalyticsDailyRecord
                                                ?.newUserRegistrations
                                                .toString(),
                                            label: 'New Reg.',
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ].divide(SizedBox(width: 16.0)),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: FutureBuilder<int>(
                                      future: queryOrdersRecordCount(
                                        queryBuilder: (ordersRecord) =>
                                            ordersRecord.where(
                                          'delivery_status',
                                          isEqualTo: 1,
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
                                          child: KpiCard2Widget(
                                            icon: Icon(
                                              Icons.shopping_cart_rounded,
                                              color: Color(0xFFFFD700),
                                              size: 18.0,
                                            ),
                                            value: kpiCardCount.toString(),
                                            label: 'Active Orders',
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: FutureBuilder<int>(
                                      future: queryUservisitsRecordCount(),
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
                                          child: KpiCard2Widget(
                                            icon: Icon(
                                              Icons.visibility_rounded,
                                              color: Color(0xFFFFD700),
                                              size: 18.0,
                                            ),
                                            value: kpiCardCount.toString(),
                                            label: 'Total Visits',
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ].divide(SizedBox(width: 16.0)),
                              ),
                              Text(
                                'Performance Overview',
                                style: FlutterFlowTheme.of(context)
                                    .titleMedium
                                    .override(
                                      font: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                      lineHeight: 1.4,
                                    ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryBackground,
                                        borderRadius:
                                            BorderRadius.circular(24.0),
                                        shape: BoxShape.rectangle,
                                        border: Border.all(
                                          color: FlutterFlowTheme.of(context)
                                              .alternate,
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Container(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Daily Traffic',
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .labelSmall
                                                        .override(
                                                          font: GoogleFonts
                                                              .plusJakartaSans(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelSmall
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelSmall
                                                                    .fontStyle,
                                                          ),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryText,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontStyle,
                                                          lineHeight: 1.4,
                                                        ),
                                              ),
                                              Container(
                                                height: 120.0,
                                                child: StreamBuilder<
                                                    List<AnalyticsDailyRecord>>(
                                                  stream:
                                                      queryAnalyticsDailyRecord(
                                                    queryBuilder:
                                                        (analyticsDailyRecord) =>
                                                            analyticsDailyRecord
                                                                .orderBy(
                                                                    'date'),
                                                    singleRecord: true,
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
                                                    List<AnalyticsDailyRecord>
                                                        lineChartAnalyticsDailyRecordList =
                                                        snapshot.data!;
                                                    // Return an empty Container when the item does not exist.
                                                    if (snapshot
                                                        .data!.isEmpty) {
                                                      return Container();
                                                    }
                                                    final lineChartAnalyticsDailyRecord =
                                                        lineChartAnalyticsDailyRecordList
                                                                .isNotEmpty
                                                            ? lineChartAnalyticsDailyRecordList
                                                                .first
                                                            : null;

                                                    return Container(
                                                      height: 120.0,
                                                      child:
                                                          FlutterFlowLineChart(
                                                        data: [
                                                          FFLineChartData(
                                                            xData: ([
                                                              0.0,
                                                              1.0,
                                                              2.0,
                                                              3.0,
                                                              4.0,
                                                              5.0,
                                                              6.0
                                                            ]),
                                                            yData: ([
                                                              30.0,
                                                              45.0,
                                                              35.0,
                                                              60.0,
                                                              55.0,
                                                              80.0,
                                                              75.0
                                                            ]),
                                                            settings:
                                                                LineChartBarData(
                                                              color: Color(
                                                                  0xFFFFD700),
                                                              barWidth: 2.0,
                                                              isCurved: true,
                                                              belowBarData:
                                                                  BarAreaData(
                                                                show: true,
                                                                color: Color(
                                                                    0x1AFFD700),
                                                              ),
                                                            ),
                                                          )
                                                        ],
                                                        chartStylingInfo:
                                                            ChartStylingInfo(
                                                          backgroundColor:
                                                              Colors
                                                                  .transparent,
                                                          showBorder: false,
                                                        ),
                                                        axisBounds: AxisBounds(
                                                          minX: 0.0,
                                                          minY: 0.0,
                                                          maxX: 6.0,
                                                          maxY: 96.0,
                                                        ),
                                                        xLabels: ([
                                                          'M',
                                                          'T',
                                                          'W',
                                                          'T',
                                                          'F',
                                                          'S',
                                                          'S'
                                                        ]),
                                                        xAxisLabelInfo:
                                                            AxisLabelInfo(
                                                          showLabels: true,
                                                          labelTextStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodySmall
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .playfairDisplay(
                                                                      fontWeight: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodySmall
                                                                          .fontWeight,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodySmall
                                                                          .fontStyle,
                                                                    ),
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .secondaryText,
                                                                    fontSize:
                                                                        10.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmall
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmall
                                                                        .fontStyle,
                                                                    lineHeight:
                                                                        1.0,
                                                                  ),
                                                          reservedSize: 28.0,
                                                        ),
                                                        yAxisLabelInfo:
                                                            AxisLabelInfo(
                                                          reservedSize: 0.0,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ].divide(SizedBox(height: 8.0)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryBackground,
                                        borderRadius:
                                            BorderRadius.circular(24.0),
                                        shape: BoxShape.rectangle,
                                        border: Border.all(
                                          color: FlutterFlowTheme.of(context)
                                              .alternate,
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Container(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'By Category',
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .labelSmall
                                                        .override(
                                                          font: GoogleFonts
                                                              .plusJakartaSans(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelSmall
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelSmall
                                                                    .fontStyle,
                                                          ),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryText,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontStyle,
                                                          lineHeight: 1.4,
                                                        ),
                                              ),
                                              Container(
                                                height: 120.0,
                                                child: StreamBuilder<
                                                    List<AnalyticsDailyRecord>>(
                                                  stream:
                                                      queryAnalyticsDailyRecord(
                                                    queryBuilder:
                                                        (analyticsDailyRecord) =>
                                                            analyticsDailyRecord
                                                                .orderBy(
                                                                    'last_updated',
                                                                    descending:
                                                                        true),
                                                    singleRecord: true,
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
                                                    List<AnalyticsDailyRecord>
                                                        barChartAnalyticsDailyRecordList =
                                                        snapshot.data!;
                                                    // Return an empty Container when the item does not exist.
                                                    if (snapshot
                                                        .data!.isEmpty) {
                                                      return Container();
                                                    }
                                                    final barChartAnalyticsDailyRecord =
                                                        barChartAnalyticsDailyRecordList
                                                                .isNotEmpty
                                                            ? barChartAnalyticsDailyRecordList
                                                                .first
                                                            : null;

                                                    return Container(
                                                      height: 120.0,
                                                      child:
                                                          FlutterFlowBarChart(
                                                        barData: [
                                                          FFBarChartData(
                                                            yData: barChartAnalyticsDailyRecord!
                                                                .topCategories
                                                                .map((e) =>
                                                                    e.viewCount)
                                                                .toList(),
                                                            color: Color(
                                                                0xFFFFD700),
                                                          )
                                                        ],
                                                        xLabels:
                                                            barChartAnalyticsDailyRecord
                                                                .topCategories
                                                                .map((e) => e
                                                                    .categoryName)
                                                                .toList(),
                                                        barWidth: 20.0,
                                                        barBorderRadius:
                                                            BorderRadius
                                                                .circular(2.0),
                                                        groupSpace: 12.0,
                                                        alignment:
                                                            BarChartAlignment
                                                                .spaceEvenly,
                                                        chartStylingInfo:
                                                            ChartStylingInfo(
                                                          backgroundColor:
                                                              Colors
                                                                  .transparent,
                                                          showBorder: false,
                                                        ),
                                                        axisBounds: AxisBounds(
                                                          minY: 0.0,
                                                          maxX: 3.0,
                                                          maxY: 114.0,
                                                        ),
                                                        xAxisLabelInfo:
                                                            AxisLabelInfo(
                                                          showLabels: true,
                                                          labelTextStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodySmall
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .playfairDisplay(
                                                                      fontWeight: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodySmall
                                                                          .fontWeight,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodySmall
                                                                          .fontStyle,
                                                                    ),
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .secondaryText,
                                                                    fontSize:
                                                                        10.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmall
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmall
                                                                        .fontStyle,
                                                                    lineHeight:
                                                                        1.0,
                                                                  ),
                                                          reservedSize: 20.0,
                                                        ),
                                                        yAxisLabelInfo:
                                                            AxisLabelInfo(
                                                          reservedSize: 0.0,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ].divide(SizedBox(height: 8.0)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ].divide(SizedBox(width: 16.0)),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Recent Activity',
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
                                              color:
                                                  FlutterFlowTheme.of(context)
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
                                        'View logs',
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
                                              color: Color(0xFFFFD700),
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
                                  Container(
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      borderRadius: BorderRadius.circular(24.0),
                                      shape: BoxShape.rectangle,
                                      border: Border.all(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(24.0),
                                      child: Container(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            wrapWithModel(
                                              model: _model.activityItemModel1,
                                              updateCallback: () =>
                                                  safeSetState(() {}),
                                              child: ActivityItem2Widget(
                                                user: 'Alex Rivera',
                                                action:
                                                    'Updated inventory for \'Kin Retail\'',
                                                time: '2m ago',
                                              ),
                                            ),
                                            wrapWithModel(
                                              model: _model.activityItemModel2,
                                              updateCallback: () =>
                                                  safeSetState(() {}),
                                              child: ActivityItem2Widget(
                                                user: 'Sarah Chen',
                                                action:
                                                    'Processed refund #8812',
                                                time: '15m ago',
                                              ),
                                            ),
                                            wrapWithModel(
                                              model: _model.activityItemModel3,
                                              updateCallback: () =>
                                                  safeSetState(() {}),
                                              child: ActivityItem2Widget(
                                                user: 'Marcus Thorne',
                                                action:
                                                    'Generated monthly tax report',
                                                time: '1h ago',
                                              ),
                                            ),
                                            wrapWithModel(
                                              model: _model.activityItemModel4,
                                              updateCallback: () =>
                                                  safeSetState(() {}),
                                              child: ActivityItem2Widget(
                                                user: 'Elena Vance',
                                                action:
                                                    'Authorized new admin user',
                                                time: '3h ago',
                                              ),
                                            ),
                                            wrapWithModel(
                                              model: _model.activityItemModel5,
                                              updateCallback: () =>
                                                  safeSetState(() {}),
                                              child: ActivityItem2Widget(
                                                user: 'Jordan Smith',
                                                action: 'Closed batch #440',
                                                time: '5h ago',
                                              ),
                                            ),
                                          ].divide(SizedBox(height: 0.0)),
                                        ),
                                      ),
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
            ),
          ],
        ),
      ),
    );
  }
}
