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
import '/services/kin_services.dart';
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
  bool _confirmedAdmin = false;

  /// Memoized so the aggregation callable is hit once per visit rather than
  /// on every rebuild of this page.
  Future<ServiceResult<AiMarketingStats>>? _aiStatsFuture;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ExecutiveDashboardModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      final userRef = currentUserReference;
      if (userRef == null) {
        context.goNamed(OnboardingSelectionCardWidget.routeName);
        return;
      }
      _model.userDocument = await UsersRecord.getDocumentOnce(userRef);
      if (_model.userDocument?.isAdmin != true) {
        context.goNamed(OnboardingSelectionCardWidget.routeName);
        return;
      }
      safeSetState(() => _confirmedAdmin = true);
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

    // Don't fire any admin-gated queries until admin status is confirmed -
    // the redirect above runs in a post-frame callback, so without this
    // guard the very first frame would still attempt them.
    if (!_confirmedAdmin) {
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

    final selectedCity = _model.dropdownValue ?? 'San Antonio';

    return StreamBuilder<List<ActivityLogsRecord>>(
      stream: queryActivityLogsRecord(
        queryBuilder: (activityLogsRecord) => activityLogsRecord.where(
          'city',
          isEqualTo: selectedCity,
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
                    FlutterFlowTheme.of(context).secondaryText,
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
                                    FutureBuilder<int>(
                                      // The `users` collection can only ever
                                      // be read one document at a time (rule
                                      // is auth.uid == document), so an
                                      // unscoped count against it is always
                                      // rejected. signup_feed is the
                                      // admin-readable aggregate instead.
                                      future: querySignupFeedRecordCount(),
                                      builder: (context, snapshot) {
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
                                        final kpiCardCount = snapshot.data!;

                                        return wrapWithModel(
                                          model: _model.kpiCardModel1,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: KpiCardWidget(
                                            value: kpiCardCount.toString(),
                                            label: 'Total Users',
                                          ),
                                        );
                                      },
                                    ),
                                    FutureBuilder<int>(
                                      future: queryBusinessesRecordCount(
                                        queryBuilder: (businessesRecord) =>
                                            businessesRecord.where(
                                          'city',
                                          isEqualTo: selectedCity,
                                        ),
                                      ),
                                      builder: (context, snapshot) {
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
                                        final kpiCardCount = snapshot.data!;

                                        return wrapWithModel(
                                          model: _model.kpiCardModel2,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: KpiCardWidget(
                                            value: kpiCardCount.toString(),
                                            label: 'Businesses Listed',
                                          ),
                                        );
                                      },
                                    ),
                                    FutureBuilder<int>(
                                      future: queryBusinessesRecordCount(
                                        queryBuilder: (businessesRecord) =>
                                            businessesRecord
                                                .where(
                                                  'city',
                                                  isEqualTo: selectedCity,
                                                )
                                                .where(
                                                  'is_black_owned',
                                                  isEqualTo: true,
                                                ),
                                      ),
                                      builder: (context, snapshot) {
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
                                        final kpiCardCount = snapshot.data!;

                                        return wrapWithModel(
                                          model: _model.kpiCardModel3,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: KpiCardWidget(
                                            value: kpiCardCount.toString(),
                                            label: 'Black-Owned',
                                          ),
                                        );
                                      },
                                    ),
                                    FutureBuilder<int>(
                                      future: queryBusinessesRecordCount(
                                        queryBuilder: (businessesRecord) =>
                                            businessesRecord
                                                .where(
                                                  'city',
                                                  isEqualTo: selectedCity,
                                                )
                                                .where(
                                                  'is_premium',
                                                  isEqualTo: true,
                                                ),
                                      ),
                                      builder: (context, snapshot) {
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
                                        final kpiCardCount = snapshot.data!;

                                        return wrapWithModel(
                                          model: _model.kpiCardModel4,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: KpiCardWidget(
                                            value: kpiCardCount.toString(),
                                            label: 'Premium Tier',
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
                                        child: Builder(builder: (context) {
                                          final dailyCounts =
                                              List<int>.filled(7, 0);
                                          for (final log
                                              in executiveDashboardActivityLogsRecordList) {
                                            final ts = log.timestamp;
                                            if (ts == null) continue;
                                            dailyCounts[ts.weekday - 1]++;
                                          }
                                          final maxCount = dailyCounts
                                              .reduce((a, b) => a > b ? a : b);

                                          return FlutterFlowLineChart(
                                            data: [
                                              FFLineChartData(
                                                xData: List<double>.generate(
                                                    7, (i) => i.toDouble()),
                                                yData: dailyCounts,
                                                settings: LineChartBarData(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryText,
                                                  barWidth: 3.0,
                                                  isCurved: true,
                                                ),
                                              )
                                            ],
                                            chartStylingInfo: ChartStylingInfo(
                                              backgroundColor:
                                                  Colors.transparent,
                                              showBorder: false,
                                            ),
                                            axisBounds: AxisBounds(
                                              minX: 0.0,
                                              minY: 0.0,
                                              maxX: 6.0,
                                              maxY: (maxCount + 1).toDouble(),
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
                                          );
                                        }),
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
                                        child: StreamBuilder<
                                            List<BusinessesRecord>>(
                                          stream: queryBusinessesRecord(
                                            queryBuilder: (businessesRecord) =>
                                                businessesRecord.where(
                                              'city',
                                              isEqualTo: selectedCity,
                                            ),
                                          ),
                                          builder: (context, snapshot) {
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
                                            final categoryCounts =
                                                <String, int>{};
                                            for (final business
                                                in snapshot.data!) {
                                              final category =
                                                  business.category;
                                              if (category.isEmpty) continue;
                                              categoryCounts[category] =
                                                  (categoryCounts[category] ??
                                                          0) +
                                                      1;
                                            }
                                            final topCategories = categoryCounts
                                                .entries
                                                .toList()
                                              ..sort((a, b) =>
                                                  b.value.compareTo(a.value));
                                            final shownCategories =
                                                topCategories.take(6).toList();
                                            final maxCount =
                                                shownCategories.isEmpty
                                                    ? 1
                                                    : shownCategories
                                                        .map((e) => e.value)
                                                        .reduce((a, b) =>
                                                            a > b ? a : b);

                                            return FlutterFlowBarChart(
                                              barData: [
                                                FFBarChartData(
                                                  yData: shownCategories
                                                      .map((e) => e.value)
                                                      .toList(),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primary,
                                                ),
                                              ],
                                              xLabels: shownCategories
                                                  .map((e) => e.key)
                                                  .toList(),
                                              chartStylingInfo:
                                                  ChartStylingInfo(
                                                backgroundColor:
                                                    Colors.transparent,
                                                showBorder: false,
                                              ),
                                              axisBounds: AxisBounds(
                                                minY: 0.0,
                                                maxY: (maxCount + 1).toDouble(),
                                              ),
                                              xAxisLabelInfo: AxisLabelInfo(
                                                showLabels: true,
                                                labelTextStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodySmall,
                                                reservedSize: 28.0,
                                              ),
                                              yAxisLabelInfo: AxisLabelInfo(
                                                reservedSize: 0.0,
                                              ),
                                            );
                                          },
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
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Subscription Tier Adoption',
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
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        'Community',
                                        'Founding Local',
                                        'Pro Growth',
                                        'Elite Growth',
                                      ]
                                          .map((tier) {
                                            return FutureBuilder<int>(
                                              future:
                                                  queryBusinessesRecordCount(
                                                queryBuilder:
                                                    (businessesRecord) =>
                                                        businessesRecord
                                                            .where(
                                                              'city',
                                                              isEqualTo:
                                                                  selectedCity,
                                                            )
                                                            .where(
                                                              'subscription_tier',
                                                              isEqualTo: tier,
                                                            ),
                                              ),
                                              builder: (context, snapshot) {
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
                                                final tierCount =
                                                    snapshot.data!;

                                                return KpiCardWidget(
                                                  value: tierCount.toString(),
                                                  label: tier,
                                                );
                                              },
                                            );
                                          })
                                          .toList()
                                          .divide(SizedBox(width: 16.0)),
                                    ),
                                  ),
                                ].divide(SizedBox(height: 16.0)),
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
                                      businessesRecord
                                          .where(
                                            'city',
                                            isEqualTo: selectedCity,
                                          )
                                          .orderBy('interaction_count',
                                              descending: true),
                                  limit: 5,
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
                                child: StreamBuilder<List<SignupFeedRecord>>(
                                  stream: querySignupFeedRecord(
                                    queryBuilder: (signupFeedRecord) =>
                                        signupFeedRecord.orderBy('timestamp',
                                            descending: true),
                                    limit: 10,
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
                                    List<SignupFeedRecord>
                                        listViewSignupFeedRecordList =
                                        snapshot.data!;

                                    return ListView.builder(
                                      padding: EdgeInsets.zero,
                                      primary: false,
                                      shrinkWrap: true,
                                      scrollDirection: Axis.vertical,
                                      itemCount:
                                          listViewSignupFeedRecordList.length,
                                      itemBuilder: (context, listViewIndex) {
                                        final listViewSignupFeedRecord =
                                            listViewSignupFeedRecordList[
                                                listViewIndex];
                                        return SignupItemWidget(
                                          key: Key(
                                              'Keyx9e_${listViewIndex}_of_${listViewSignupFeedRecordList.length}'),
                                          user: listViewSignupFeedRecord
                                              .displayName,
                                          city: '—',
                                          status: listViewSignupFeedRecord
                                                  .subscriptionStatus.isEmpty
                                              ? 'Free'
                                              : listViewSignupFeedRecord
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
                          _aiMarketingSection(context),
                          _feedbackSection(context),
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

  /// AI Marketing usage, from `ai_generation_logs` via the
  /// getAiMarketingStats callable.
  ///
  /// The headline figure is deliberately "turned away", not "generated".
  /// Successful generations measure how much the entitled businesses use
  /// what they already pay for; rejections measure owners who wanted this
  /// and could not buy it, which is the number that prices the tier.
  Widget _aiMarketingSection(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    // Memoized here rather than started in initState: the callable rejects
    // non-admins, and admin isn't confirmed until the post-frame check has
    // run. Assigning during build is safe because it's a cache fill, not a
    // setState.
    _aiStatsFuture ??= KinServices.getAiMarketingStats();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'AI Marketing',
          style: theme.titleMedium.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            letterSpacing: 0.0,
            fontWeight: FontWeight.bold,
            lineHeight: 1.4,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: theme.alternate, width: 1.0),
          ),
          padding: EdgeInsets.all(20.0),
          child: FutureBuilder<ServiceResult<AiMarketingStats>>(
            future: _aiStatsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: SizedBox(
                    width: 30.0,
                    height: 30.0,
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(theme.primary),
                    ),
                  ),
                );
              }
              final result = snapshot.data!;
              if (!result.isSuccess) {
                // Named rather than swallowed. The most likely cause is
                // that getAiMarketingStats hasn't been deployed yet, and
                // an empty panel would read as "no usage" - the opposite
                // of the truth.
                return _aiNote(
                  theme,
                  result.error ?? 'Could not load AI marketing stats.',
                );
              }
              final stats = result.data!;

              if (stats.total == 0) {
                return _aiNote(
                  theme,
                  'No AI marketing requests yet. Two businesses are '
                  'entitled (Elite Growth); generating a post from Owner '
                  'Profile → AI Marketing will show up here.',
                );
              }

              final tiersWithRequests = stats.byTier.entries
                  .where((e) => e.value > 0)
                  .toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final engagementRecorded = stats.byEngagement.entries
                  .where((e) => e.value > 0)
                  .toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _aiStat(theme, 'Requests', stats.total),
                      ),
                      Expanded(
                        child: _aiStat(theme, 'Generated', stats.succeeded),
                      ),
                      Expanded(
                        child: _aiStat(
                          theme,
                          'Turned away',
                          stats.turnedAwayUnentitled,
                          highlight: stats.turnedAwayUnentitled > 0,
                        ),
                      ),
                    ],
                  ),
                  if (stats.turnedAwayUnentitled > 0)
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(0, 12, 0, 0),
                      child: Text(
                        '${stats.turnedAwayUnentitled} '
                        '${stats.turnedAwayUnentitled == 1 ? "owner" : "owners"} '
                        'asked for AI marketing on a tier that does not '
                        'include it.',
                        style: theme.bodySmall.override(
                          font: GoogleFonts.plusJakartaSans(),
                          color: theme.secondaryText,
                          letterSpacing: 0.0,
                        ),
                      ),
                    ),
                  if (stats.turnedAwayOverQuota > 0 || stats.errored > 0)
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(0, 8, 0, 0),
                      child: Text(
                        [
                          if (stats.turnedAwayOverQuota > 0)
                            '${stats.turnedAwayOverQuota} hit the monthly cap',
                          if (stats.errored > 0)
                            '${stats.errored} failed',
                        ].join(' · '),
                        style: theme.bodySmall.override(
                          font: GoogleFonts.plusJakartaSans(),
                          color: theme.secondaryText,
                          letterSpacing: 0.0,
                        ),
                      ),
                    ),
                  if (tiersWithRequests.isNotEmpty) ...[
                    _aiSubheading(theme, 'By tier'),
                    for (final entry in tiersWithRequests)
                      _aiRow(theme, entry.key, entry.value),
                  ],
                  _aiSubheading(theme, 'What owners did with it'),
                  if (engagementRecorded.isEmpty)
                    Text(
                      stats.engagementUnavailable
                          ? 'Could not read the engagement counts - the rest '
                              'of this panel is unaffected.'
                          : stats.succeeded == 0
                              ? 'Nothing generated yet, so nothing to act on.'
                              : 'No responses recorded yet.',
                      style: theme.bodySmall.override(
                        font: GoogleFonts.plusJakartaSans(),
                        color: theme.secondaryText,
                        letterSpacing: 0.0,
                      ),
                    )
                  else
                    for (final entry in engagementRecorded)
                      _aiRow(theme, entry.key, entry.value),
                  if (stats.unrecognisedStatus > 0)
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(0, 12, 0, 0),
                      child: Text(
                        '${stats.unrecognisedStatus} request(s) have a status '
                        'this dashboard does not recognise - the breakdown '
                        'above under-reports.',
                        style: theme.bodySmall.override(
                          font: GoogleFonts.plusJakartaSans(),
                          color: theme.error,
                          letterSpacing: 0.0,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ].divide(SizedBox(height: 16.0)),
    );
  }

  Widget _aiStat(FlutterFlowTheme theme, String label, int value,
      {bool highlight = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value.toString(),
          style: theme.displaySmall.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            // accentOnSurface, not `primary`. primary is the dark brand
            // green, which on this card's dark surface renders the one
            // number the panel exists to draw attention to as almost
            // invisible - the same mistake the nav bar's tab colours were
            // fixed for. accentOnSurface is the gold that stays legible as
            // a foreground in both themes.
            color: highlight ? theme.accentOnSurface : theme.primaryText,
            letterSpacing: 0.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.bodySmall.override(
            font: GoogleFonts.plusJakartaSans(),
            color: theme.secondaryText,
            letterSpacing: 0.0,
          ),
        ),
      ],
    );
  }

  Widget _aiSubheading(FlutterFlowTheme theme, String text) => Padding(
        padding: EdgeInsetsDirectional.fromSTEB(0, 20, 0, 8),
        child: Text(
          text,
          style: theme.labelMedium.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            color: theme.secondaryText,
            letterSpacing: 0.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _aiRow(FlutterFlowTheme theme, String label, int value) => Padding(
        padding: EdgeInsetsDirectional.fromSTEB(0, 4, 0, 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.bodyMedium.override(
                font: GoogleFonts.plusJakartaSans(),
                letterSpacing: 0.0,
              ),
            ),
            Text(
              value.toString(),
              style: theme.bodyMedium.override(
                font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                letterSpacing: 0.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  Widget _aiNote(FlutterFlowTheme theme, String text) => Text(
        text,
        style: theme.bodySmall.override(
          font: GoogleFonts.plusJakartaSans(),
          color: theme.secondaryText,
          letterSpacing: 0.0,
        ),
      );

  /// What users have sent in from the app, newest first.
  ///
  /// Bounded to 20 by the query rather than aggregated server-side like
  /// the AI panel: this reads the documents themselves because the text is
  /// the whole point, and unlike ai_generation_logs there is nothing here
  /// the admin reading it shouldn't see. The limit is what keeps it from
  /// growing into the same unbounded read.
  Widget _feedbackSection(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Feedback & Requests',
          style: theme.titleMedium.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            letterSpacing: 0.0,
            fontWeight: FontWeight.bold,
            lineHeight: 1.4,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: theme.alternate, width: 1.0),
          ),
          padding: EdgeInsets.all(20.0),
          child: StreamBuilder<List<BugReportsRecord>>(
            stream: queryBugReportsRecord(
              queryBuilder: (q) => q.orderBy('timestamp', descending: true),
              limit: 20,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: SizedBox(
                    width: 30.0,
                    height: 30.0,
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(theme.primary),
                    ),
                  ),
                );
              }
              final reports = snapshot.data!;
              if (reports.isEmpty) {
                return _aiNote(
                  theme,
                  'Nothing submitted yet. The prompt sits at the bottom of '
                  'the profile page.',
                );
              }

              final counts = <String, int>{};
              for (final r in reports) {
                final type =
                    r.feedbackType.isEmpty ? 'Unspecified' : r.feedbackType;
                counts[type] = (counts[type] ?? 0) + 1;
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    counts.entries
                        .map((e) => '${e.value} ${e.key.toLowerCase()}')
                        .join(' · '),
                    style: theme.bodySmall.override(
                      font: GoogleFonts.plusJakartaSans(),
                      color: theme.secondaryText,
                      letterSpacing: 0.0,
                    ),
                  ),
                  for (final report in reports)
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(0, 16, 0, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            [
                              report.feedbackType.isEmpty
                                  ? 'Unspecified'
                                  : report.feedbackType,
                              if (report.pageWhereItHappened.isNotEmpty)
                                report.pageWhereItHappened,
                              if (report.timestamp != null)
                                dateTimeFormat(
                                    "relative", report.timestamp!),
                            ].join(' · '),
                            style: theme.labelSmall.override(
                              font: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold),
                              color: theme.accentOnSurface,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Padding(
                            padding:
                                EdgeInsetsDirectional.fromSTEB(0, 4, 0, 0),
                            child: Text(
                              report.issueDescription,
                              style: theme.bodyMedium.override(
                                font: GoogleFonts.plusJakartaSans(),
                                letterSpacing: 0.0,
                              ),
                            ),
                          ),
                          if (report.testerName.isNotEmpty)
                            Text(
                              '— ${report.testerName}',
                              style: theme.bodySmall.override(
                                font: GoogleFonts.plusJakartaSans(),
                                color: theme.secondaryText,
                                letterSpacing: 0.0,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ].divide(SizedBox(height: 16.0)),
    );
  }
}
