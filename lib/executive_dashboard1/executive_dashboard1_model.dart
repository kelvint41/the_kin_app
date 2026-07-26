import '/components/activity_item2_widget.dart';
import '/components/kpi_card2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'executive_dashboard1_widget.dart' show ExecutiveDashboard1Widget;
import 'package:flutter/material.dart';

class ExecutiveDashboard1Model
    extends FlutterFlowModel<ExecutiveDashboard1Widget> {
  ///  State fields for stateful widgets in this page.

  // Model for KpiCard.
  late KpiCard2Model kpiCardModel1;
  // Model for KpiCard.
  late KpiCard2Model kpiCardModel2;
  // Model for KpiCard.
  late KpiCard2Model kpiCardModel3;
  // Model for KpiCard.
  late KpiCard2Model kpiCardModel4;
  // Model for ActivityItem.
  late ActivityItem2Model activityItemModel1;
  // Model for ActivityItem.
  late ActivityItem2Model activityItemModel2;
  // Model for ActivityItem.
  late ActivityItem2Model activityItemModel3;
  // Model for ActivityItem.
  late ActivityItem2Model activityItemModel4;
  // Model for ActivityItem.
  late ActivityItem2Model activityItemModel5;

  @override
  void initState(BuildContext context) {
    kpiCardModel1 = createModel(context, () => KpiCard2Model());
    kpiCardModel2 = createModel(context, () => KpiCard2Model());
    kpiCardModel3 = createModel(context, () => KpiCard2Model());
    kpiCardModel4 = createModel(context, () => KpiCard2Model());
    activityItemModel1 = createModel(context, () => ActivityItem2Model());
    activityItemModel2 = createModel(context, () => ActivityItem2Model());
    activityItemModel3 = createModel(context, () => ActivityItem2Model());
    activityItemModel4 = createModel(context, () => ActivityItem2Model());
    activityItemModel5 = createModel(context, () => ActivityItem2Model());
  }

  @override
  void dispose() {
    kpiCardModel1.dispose();
    kpiCardModel2.dispose();
    kpiCardModel3.dispose();
    kpiCardModel4.dispose();
    activityItemModel1.dispose();
    activityItemModel2.dispose();
    activityItemModel3.dispose();
    activityItemModel4.dispose();
    activityItemModel5.dispose();
  }
}
