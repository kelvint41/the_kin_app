import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/section_header_widget.dart';
import '/components/step_indicator3_widget.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_place_picker.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/place.dart';
import 'dart:io';
import 'dart:ui';
import '/index.dart';
import 'business_setup_page_widget.dart' show BusinessSetupPageWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class BusinessSetupPageModel extends FlutterFlowModel<BusinessSetupPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for StepIndicator.
  late StepIndicator3Model stepIndicatorModel;
  // Model for SectionHeader.
  late SectionHeaderModel sectionHeaderModel1;
  // State field(s) for Dropdown widget.
  String? dropdownValue;
  FormFieldController<String>? dropdownValueController;
  // Model for SectionHeader.
  late SectionHeaderModel sectionHeaderModel2;
  // State field(s) for PlacePicker widget.
  FFPlace placePickerValue = FFPlace();
  // Selected business type (Choice Chips).
  String businessType = 'Sole Proprietor';
  // Whether this is a Black-owned business (defaults to true per design spec).
  bool isBlackOwned = true;
  // State field(s) for BusinessName widget.
  FocusNode? businessNameFocusNode;
  TextEditingController? businessNameTextController;
  String? Function(BuildContext, String?)? businessNameTextControllerValidator;
  // State field(s) for PhoneNumber widget.
  FocusNode? phoneNumberFocusNode;
  TextEditingController? phoneNumberTextController;
  String? Function(BuildContext, String?)? phoneNumberTextControllerValidator;
  // State field(s) for Email widget.
  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;
  String? Function(BuildContext, String?)? emailTextControllerValidator;
  // State field(s) for Website widget.
  FocusNode? websiteFocusNode;
  TextEditingController? websiteTextController;
  String? Function(BuildContext, String?)? websiteTextControllerValidator;
  // State field(s) for Description widget.
  FocusNode? descriptionFocusNode;
  TextEditingController? descriptionTextController;
  String? Function(BuildContext, String?)? descriptionTextControllerValidator;
  // Stores action output result for [Backend Call - Create Document] action in bu widget.
  BusinessesRecord? newBusinessCreated;

  @override
  void initState(BuildContext context) {
    stepIndicatorModel = createModel(context, () => StepIndicator3Model());
    sectionHeaderModel1 = createModel(context, () => SectionHeaderModel());
    sectionHeaderModel2 = createModel(context, () => SectionHeaderModel());
  }

  @override
  void dispose() {
    stepIndicatorModel.dispose();
    sectionHeaderModel1.dispose();
    sectionHeaderModel2.dispose();
    businessNameFocusNode?.dispose();
    businessNameTextController?.dispose();
    phoneNumberFocusNode?.dispose();
    phoneNumberTextController?.dispose();
    emailFocusNode?.dispose();
    emailTextController?.dispose();
    websiteFocusNode?.dispose();
    websiteTextController?.dispose();
    descriptionFocusNode?.dispose();
    descriptionTextController?.dispose();
  }
}
