import '/components/text_field_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'premium_dark_themed_widget.dart' show PremiumDarkThemedWidget;
import 'package:flutter/material.dart';

class PremiumDarkThemedModel extends FlutterFlowModel<PremiumDarkThemedWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for TextField.
  late TextFieldModel textFieldModel;

  @override
  void initState(BuildContext context) {
    textFieldModel = createModel(context, () => TextFieldModel());
  }

  @override
  void dispose() {
    textFieldModel.dispose();
  }
}
