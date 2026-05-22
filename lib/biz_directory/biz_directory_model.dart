import '/flutter_flow/flutter_flow_util.dart';
import 'biz_directory_widget.dart' show BizDirectoryWidget;
import 'package:flutter/material.dart';

class BizDirectoryModel extends FlutterFlowModel<BizDirectoryWidget> {
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
