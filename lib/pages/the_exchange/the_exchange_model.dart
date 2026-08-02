import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'the_exchange_widget.dart' show TheExchangeWidget;
import 'package:flutter/material.dart';

class TheExchangeModel extends FlutterFlowModel<TheExchangeWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for PostText widget.
  FocusNode? postTextFieldFocusNode;
  TextEditingController? postTextController;
  String? Function(BuildContext, String?)? postTextControllerValidator;
  // State field(s) for the feed composer bar.
  FocusNode? feedComposerFocusNode;
  TextEditingController? feedComposerController;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    postTextFieldFocusNode?.dispose();
    postTextController?.dispose();
    feedComposerFocusNode?.dispose();
    feedComposerController?.dispose();
  }
}
