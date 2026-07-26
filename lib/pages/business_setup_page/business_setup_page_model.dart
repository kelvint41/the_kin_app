import '/components/section_header_widget.dart';
import '/components/step_indicator3_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'business_setup_page_widget.dart' show BusinessSetupPageWidget;
import 'package:flutter/material.dart';

class BusinessSetupPageModel extends FlutterFlowModel<BusinessSetupPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for StepIndicator.
  late StepIndicator3Model stepIndicatorModel;
  // Model for SectionHeader.
  late SectionHeaderModel sectionHeaderModel1;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;
  // State field(s) for TextFiel widget.
  FocusNode? textFielFocusNode;
  TextEditingController? textFielTextController;
  String? Function(BuildContext, String?)? textFielTextControllerValidator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode3;
  TextEditingController? textController4;
  late bool passwordVisibility;
  String? Function(BuildContext, String?)? textController4Validator;
  // State field(s) for SwitchBlackOwned widget.
  bool? switchBlackOwnedValue;
  // State field(s) for SwitchEcommerce widget.
  bool? switchEcommerceValue;
  // State field(s) for SwitchVeteranOwned widget.
  bool? switchVeteranOwnedValue;
  // State field(s) for Dropdown widget.
  String? dropdownValue;
  FormFieldController<String>? dropdownValueController;
  // Model for SectionHeader.
  late SectionHeaderModel sectionHeaderModel2;
  // State field(s) for PlacePicker widget.
  FFPlace placePickerValue = FFPlace();
  bool isDataUploading_uploadedBusinessImage = false;
  FFUploadedFile uploadedLocalFile_uploadedBusinessImage =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadedBusinessImage = '';

  @override
  void initState(BuildContext context) {
    stepIndicatorModel = createModel(context, () => StepIndicator3Model());
    sectionHeaderModel1 = createModel(context, () => SectionHeaderModel());
    passwordVisibility = false;
    sectionHeaderModel2 = createModel(context, () => SectionHeaderModel());
  }

  @override
  void dispose() {
    stepIndicatorModel.dispose();
    sectionHeaderModel1.dispose();
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    textFieldFocusNode2?.dispose();
    textController2?.dispose();

    textFielFocusNode?.dispose();
    textFielTextController?.dispose();

    textFieldFocusNode3?.dispose();
    textController4?.dispose();

    sectionHeaderModel2.dispose();
  }
}
