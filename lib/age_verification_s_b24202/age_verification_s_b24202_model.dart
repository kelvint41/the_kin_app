import '/flutter_flow/flutter_flow_util.dart';
import 'age_verification_s_b24202_widget.dart'
    show AgeVerificationSB24202Widget;
import 'package:flutter/material.dart';

class AgeVerificationSB24202Model
    extends FlutterFlowModel<AgeVerificationSB24202Widget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
