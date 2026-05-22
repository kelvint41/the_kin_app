import '/components/custom_checkbox_widget.dart';
import '/components/step_indicator_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'customer_sign_up_step1_widget.dart' show CustomerSignUpStep1Widget;
import 'package:flutter/material.dart';

class CustomerSignUpStep1Model
    extends FlutterFlowModel<CustomerSignUpStep1Widget> {
  ///  State fields for stateful widgets in this page.

  // Model for StepIndicator component.
  late StepIndicatorModel stepIndicatorModel;
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
  // Model for CustomCheckbox component.
  late CustomCheckboxModel customCheckboxModel;

  @override
  void initState(BuildContext context) {
    stepIndicatorModel = createModel(context, () => StepIndicatorModel());
    customCheckboxModel = createModel(context, () => CustomCheckboxModel());
  }

  @override
  void dispose() {
    stepIndicatorModel.dispose();
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    textFieldFocusNode2?.dispose();
    textController2?.dispose();

    textFieldFocusNode3?.dispose();
    textController3?.dispose();

    customCheckboxModel.dispose();
  }
}
