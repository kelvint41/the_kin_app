import '/flutter_flow/flutter_flow_util.dart';
import 'ai_marketing_sheet_widget.dart' show AiMarketingSheetWidget;
import 'package:flutter/material.dart';

class AiMarketingSheetModel extends FlutterFlowModel<AiMarketingSheetWidget> {
  TextEditingController? themeController;
  FocusNode? themeFocusNode;

  // The generated caption, editable in place. Seeded from each generation
  // and compared against the original on Use This, so an owner's edits are
  // captured instead of happening off-platform after a clipboard copy.
  TextEditingController? captionController;
  FocusNode? captionFocusNode;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    themeController?.dispose();
    themeFocusNode?.dispose();
    captionController?.dispose();
    captionFocusNode?.dispose();
  }
}
