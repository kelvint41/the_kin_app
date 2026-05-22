import '/components/duration_chip_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'new_screen1_widget.dart' show NewScreen1Widget;
import 'package:flutter/material.dart';

class NewScreen1Model extends FlutterFlowModel<NewScreen1Widget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Model for DurationChip component.
  late DurationChipModel durationChipModel1;
  // Model for DurationChip component.
  late DurationChipModel durationChipModel2;
  // Model for DurationChip component.
  late DurationChipModel durationChipModel3;
  // State field(s) for Slider widget.
  double? sliderValue;

  @override
  void initState(BuildContext context) {
    durationChipModel1 = createModel(context, () => DurationChipModel());
    durationChipModel2 = createModel(context, () => DurationChipModel());
    durationChipModel3 = createModel(context, () => DurationChipModel());
  }

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();

    durationChipModel1.dispose();
    durationChipModel2.dispose();
    durationChipModel3.dispose();
  }
}
