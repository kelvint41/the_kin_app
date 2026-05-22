import '/flutter_flow/flutter_flow_util.dart';
import 'biz_directory2_widget.dart' show BizDirectory2Widget;
import 'package:flutter/material.dart';

class BizDirectory2Model extends FlutterFlowModel<BizDirectory2Widget> {
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
