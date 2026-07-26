import '/components/milestone_card_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'single_mobile_named_page_widget.dart' show SingleMobileNamedPageWidget;
import 'package:flutter/material.dart';

class SingleMobileNamedPageModel
    extends FlutterFlowModel<SingleMobileNamedPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for MilestoneCard.
  late MilestoneCardModel milestoneCardModel1;
  // Model for MilestoneCard.
  late MilestoneCardModel milestoneCardModel2;
  // Model for MilestoneCard.
  late MilestoneCardModel milestoneCardModel3;
  // Model for MilestoneCard.
  late MilestoneCardModel milestoneCardModel4;

  @override
  void initState(BuildContext context) {
    milestoneCardModel1 = createModel(context, () => MilestoneCardModel());
    milestoneCardModel2 = createModel(context, () => MilestoneCardModel());
    milestoneCardModel3 = createModel(context, () => MilestoneCardModel());
    milestoneCardModel4 = createModel(context, () => MilestoneCardModel());
  }

  @override
  void dispose() {
    milestoneCardModel1.dispose();
    milestoneCardModel2.dispose();
    milestoneCardModel3.dispose();
    milestoneCardModel4.dispose();
  }
}
