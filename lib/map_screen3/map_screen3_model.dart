import '/flutter_flow/flutter_flow_util.dart';
import 'map_screen3_widget.dart' show MapScreen3Widget;
import 'package:flutter/material.dart';

class MapScreen3Model extends FlutterFlowModel<MapScreen3Widget> {
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
