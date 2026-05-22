import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'business_onboarding2_widget.dart' show BusinessOnboarding2Widget;
import 'package:flutter/material.dart';

class BusinessOnboarding2Model
    extends FlutterFlowModel<BusinessOnboarding2Widget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  // State field(s) for Switch widget.
  bool? switchValue;
  // State field(s) for kindexTextField widget.
  FocusNode? kindexTextFieldFocusNode;
  TextEditingController? kindexTextFieldTextController;
  String? Function(BuildContext, String?)?
      kindexTextFieldTextControllerValidator;
  // State field(s) for PlacePicker widget.
  FFPlace placePickerValue = FFPlace();
  // Stores action output result for [Backend Call - Create Document] action in Button widget.
  BusinessesRecord? newBusiness;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController1?.dispose();

    kindexTextFieldFocusNode?.dispose();
    kindexTextFieldTextController?.dispose();
  }
}
