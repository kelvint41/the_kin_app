import '/components/duration_chip2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'mobile_called_power_page_widget.dart' show MobileCalledPowerPageWidget;
import 'package:flutter/material.dart';

class MobileCalledPowerPageModel
    extends FlutterFlowModel<MobileCalledPowerPageWidget> {
  ///  Local state fields for this page.

  int selectedDuration = 1;

  int? selectedPrice = 39;

  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Model for DurationChip.
  late DurationChip2Model durationChipModel1;
  // Model for DurationChip.
  late DurationChip2Model durationChipModel2;
  // Model for DurationChip.
  late DurationChip2Model durationChipModel3;
  // State field(s) for Slider widget.
  double? sliderValue;
  bool isDataUploading_uploadedBlastImage = false;
  FFUploadedFile uploadedLocalFile_uploadedBlastImage =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadedBlastImage = '';

  @override
  void initState(BuildContext context) {
    durationChipModel1 = createModel(context, () => DurationChip2Model());
    durationChipModel2 = createModel(context, () => DurationChip2Model());
    durationChipModel3 = createModel(context, () => DurationChip2Model());
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
