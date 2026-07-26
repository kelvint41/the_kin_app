import '/flutter_flow/flutter_flow_util.dart';
import 'exchange_widget.dart' show ExchangeWidget;
import 'package:flutter/material.dart';

class ExchangeModel extends FlutterFlowModel<ExchangeWidget> {
  ///  State fields for stateful widgets in this component.

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
