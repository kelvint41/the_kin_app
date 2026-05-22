import '/components/step_indicator2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'customer_sign_up_step22_widget.dart' show CustomerSignUpStep22Widget;
import 'package:flutter/material.dart';

class CustomerSignUpStep22Model
    extends FlutterFlowModel<CustomerSignUpStep22Widget> {
  ///  State fields for stateful widgets in this page.

  // Model for StepIndicator2 component.
  late StepIndicator2Model stepIndicator2Model;

  @override
  void initState(BuildContext context) {
    stepIndicator2Model = createModel(context, () => StepIndicator2Model());
  }

  @override
  void dispose() {
    stepIndicator2Model.dispose();
  }
}
