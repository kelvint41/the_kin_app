import '/components/step_indicator_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'customer_sign_up_step2_widget.dart' show CustomerSignUpStep2Widget;
import 'package:flutter/material.dart';

class CustomerSignUpStep2Model
    extends FlutterFlowModel<CustomerSignUpStep2Widget> {
  ///  State fields for stateful widgets in this page.

  // Model for StepIndicator component.
  late StepIndicatorModel stepIndicatorModel;

  @override
  void initState(BuildContext context) {
    stepIndicatorModel = createModel(context, () => StepIndicatorModel());
  }

  @override
  void dispose() {
    stepIndicatorModel.dispose();
  }
}
