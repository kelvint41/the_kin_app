import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/components/duration_chip2_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'mobile_called_power_page_widget.dart' show MobileCalledPowerPageWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class MobileCalledPowerPageModel
    extends FlutterFlowModel<MobileCalledPowerPageWidget> {
  ///  Local state fields for this page.

  // Selected Power Hour duration, in minutes - set from the business's
  // tier-based preset chip by default, or the custom slider.
  int selectedDuration = 30;

  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Model for the single tier-based duration chip.
  late DurationChip2Model durationChipModel1;
  // State field(s) for Slider widget (minutes).
  double? sliderValue;
  bool isDataUploading_uploadedBlastImage = false;
  FFUploadedFile uploadedLocalFile_uploadedBlastImage =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadedBlastImage = '';

  @override
  void initState(BuildContext context) {
    durationChipModel1 = createModel(context, () => DurationChip2Model());
  }

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();

    durationChipModel1.dispose();
  }
}
