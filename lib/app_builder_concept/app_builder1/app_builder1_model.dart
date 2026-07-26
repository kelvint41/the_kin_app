import '/components/milestone_step_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'app_builder1_widget.dart' show AppBuilder1Widget;
import 'package:flutter/material.dart';

class AppBuilder1Model extends FlutterFlowModel<AppBuilder1Widget> {
  ///  State fields for stateful widgets in this page.

  // Model for MilestoneStep.
  late MilestoneStepModel milestoneStepModel1;
  // Model for MilestoneStep.
  late MilestoneStepModel milestoneStepModel2;
  // Model for MilestoneStep.
  late MilestoneStepModel milestoneStepModel3;
  // Model for MilestoneStep.
  late MilestoneStepModel milestoneStepModel4;

  @override
  void initState(BuildContext context) {
    milestoneStepModel1 = createModel(context, () => MilestoneStepModel());
    milestoneStepModel2 = createModel(context, () => MilestoneStepModel());
    milestoneStepModel3 = createModel(context, () => MilestoneStepModel());
    milestoneStepModel4 = createModel(context, () => MilestoneStepModel());
  }

  @override
  void dispose() {
    milestoneStepModel1.dispose();
    milestoneStepModel2.dispose();
    milestoneStepModel3.dispose();
    milestoneStepModel4.dispose();
  }
}
