import '/flutter_flow/flutter_flow_util.dart';
import 'ai_marketing_sheet_widget.dart' show AiMarketingSheetWidget;
import 'package:flutter/material.dart';

class AiMarketingSheetModel extends FlutterFlowModel<AiMarketingSheetWidget> {
  TextEditingController? themeController;
  FocusNode? themeFocusNode;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    themeController?.dispose();
    themeFocusNode?.dispose();
  }
}
