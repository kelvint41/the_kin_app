import '/components/category_filter_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'business_owner_registration_widget.dart'
    show BusinessOwnerRegistrationWidget;
import 'package:flutter/material.dart';

class BusinessOwnerRegistrationModel
    extends FlutterFlowModel<BusinessOwnerRegistrationWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  // Model for CategoryFilter component.
  late CategoryFilterModel categoryFilterModel1;
  // Model for CategoryFilter component.
  late CategoryFilterModel categoryFilterModel2;
  // Model for CategoryFilter component.
  late CategoryFilterModel categoryFilterModel3;
  // Model for CategoryFilter component.
  late CategoryFilterModel categoryFilterModel4;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode3;
  TextEditingController? textController3;
  String? Function(BuildContext, String?)? textController3Validator;
  // State field(s) for Checkbox widget.
  bool? checkboxValue;

  @override
  void initState(BuildContext context) {
    categoryFilterModel1 = createModel(context, () => CategoryFilterModel());
    categoryFilterModel2 = createModel(context, () => CategoryFilterModel());
    categoryFilterModel3 = createModel(context, () => CategoryFilterModel());
    categoryFilterModel4 = createModel(context, () => CategoryFilterModel());
  }

  @override
  void dispose() {
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    categoryFilterModel1.dispose();
    categoryFilterModel2.dispose();
    categoryFilterModel3.dispose();
    categoryFilterModel4.dispose();
    textFieldFocusNode2?.dispose();
    textController2?.dispose();

    textFieldFocusNode3?.dispose();
    textController3?.dispose();
  }
}
