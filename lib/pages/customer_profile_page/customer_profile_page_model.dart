import '/components/launch_action_widget.dart';
import '/components/metric_card3_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'customer_profile_page_widget.dart' show CustomerProfilePageWidget;
import 'package:flutter/material.dart';

class CustomerProfilePageModel
    extends FlutterFlowModel<CustomerProfilePageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for LaunchAction.
  late LaunchActionModel launchActionModel1;
  // Model for LaunchAction.
  late LaunchActionModel launchActionModel2;
  // Model for LaunchAction.
  late LaunchActionModel launchActionModel3;
  // Model for MetricCard.
  late MetricCard3Model metricCardModel1;
  // Model for MetricCard.
  late MetricCard3Model metricCardModel2;
  // Model for MetricCard.
  late MetricCard3Model metricCardModel3;

  @override
  void initState(BuildContext context) {
    launchActionModel1 = createModel(context, () => LaunchActionModel());
    launchActionModel2 = createModel(context, () => LaunchActionModel());
    launchActionModel3 = createModel(context, () => LaunchActionModel());
    metricCardModel1 = createModel(context, () => MetricCard3Model());
    metricCardModel2 = createModel(context, () => MetricCard3Model());
    metricCardModel3 = createModel(context, () => MetricCard3Model());
  }

  @override
  void dispose() {
    launchActionModel1.dispose();
    launchActionModel2.dispose();
    launchActionModel3.dispose();
    metricCardModel1.dispose();
    metricCardModel2.dispose();
    metricCardModel3.dispose();
  }
}
