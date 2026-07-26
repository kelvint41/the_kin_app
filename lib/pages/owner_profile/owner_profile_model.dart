import '/components/action_btn_widget.dart';
import '/components/metric_card4_widget.dart';
import '/components/review_item_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'owner_profile_widget.dart' show OwnerProfileWidget;
import 'package:flutter/material.dart';

class OwnerProfileModel extends FlutterFlowModel<OwnerProfileWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for MetricCard.
  late MetricCard4Model metricCardModel1;
  // Model for MetricCard.
  late MetricCard4Model metricCardModel2;
  // Model for MetricCard.
  late MetricCard4Model metricCardModel3;
  // Model for MetricCard.
  late MetricCard4Model metricCardModel4;
  // Model for ReviewItem.
  late ReviewItemModel reviewItemModel;
  // Model for ActionBtn.
  late ActionBtnModel actionBtnModel1;
  // Model for ActionBtn.
  late ActionBtnModel actionBtnModel2;
  // Model for ActionBtn.
  late ActionBtnModel actionBtnModel3;
  // Model for ActionBtn.
  late ActionBtnModel actionBtnModel4;

  @override
  void initState(BuildContext context) {
    metricCardModel1 = createModel(context, () => MetricCard4Model());
    metricCardModel2 = createModel(context, () => MetricCard4Model());
    metricCardModel3 = createModel(context, () => MetricCard4Model());
    metricCardModel4 = createModel(context, () => MetricCard4Model());
    reviewItemModel = createModel(context, () => ReviewItemModel());
    actionBtnModel1 = createModel(context, () => ActionBtnModel());
    actionBtnModel2 = createModel(context, () => ActionBtnModel());
    actionBtnModel3 = createModel(context, () => ActionBtnModel());
    actionBtnModel4 = createModel(context, () => ActionBtnModel());
  }

  @override
  void dispose() {
    metricCardModel1.dispose();
    metricCardModel2.dispose();
    metricCardModel3.dispose();
    metricCardModel4.dispose();
    reviewItemModel.dispose();
    actionBtnModel1.dispose();
    actionBtnModel2.dispose();
    actionBtnModel3.dispose();
    actionBtnModel4.dispose();
  }
}
