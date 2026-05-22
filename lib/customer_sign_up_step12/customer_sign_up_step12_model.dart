import '/components/custom_checkbox2_widget.dart';
import '/components/step_indicator2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'customer_sign_up_step12_widget.dart' show CustomerSignUpStep12Widget;
import 'package:flutter/material.dart';

class CustomerSignUpStep12Model
    extends FlutterFlowModel<CustomerSignUpStep12Widget> {
  ///  State fields for stateful widgets in this page.

  // Model for StepIndicator2 component.
  late StepIndicator2Model stepIndicator2Model;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode3;
  TextEditingController? textController3;
  String? Function(BuildContext, String?)? textController3Validator;
  // Model for CustomCheckbox2 component.
  late CustomCheckbox2Model customCheckbox2Model;

  @override
  void initState(BuildContext context) {
    stepIndicator2Model = createModel(context, () => StepIndicator2Model());
    customCheckbox2Model = createModel(context, () => CustomCheckbox2Model());
  }

  @override
  void dispose() {
    stepIndicator2Model.dispose();
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    textFieldFocusNode2?.dispose();
    textController2?.dispose();

    textFieldFocusNode3?.dispose();
    textController3?.dispose();

    customCheckbox2Model.dispose();
  }
}
