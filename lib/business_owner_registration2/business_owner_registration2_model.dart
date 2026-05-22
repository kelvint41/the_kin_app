import '/components/category_filter2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'business_owner_registration2_widget.dart'
    show BusinessOwnerRegistration2Widget;
import 'package:flutter/material.dart';

class BusinessOwnerRegistration2Model
    extends FlutterFlowModel<BusinessOwnerRegistration2Widget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  // Model for CategoryFilter2 component.
  late CategoryFilter2Model categoryFilter2Model1;
  // Model for CategoryFilter2 component.
  late CategoryFilter2Model categoryFilter2Model2;
  // Model for CategoryFilter2 component.
  late CategoryFilter2Model categoryFilter2Model3;
  // Model for CategoryFilter2 component.
  late CategoryFilter2Model categoryFilter2Model4;
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
    categoryFilter2Model1 = createModel(context, () => CategoryFilter2Model());
    categoryFilter2Model2 = createModel(context, () => CategoryFilter2Model());
    categoryFilter2Model3 = createModel(context, () => CategoryFilter2Model());
    categoryFilter2Model4 = createModel(context, () => CategoryFilter2Model());
  }

  @override
  void dispose() {
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    categoryFilter2Model1.dispose();
    categoryFilter2Model2.dispose();
    categoryFilter2Model3.dispose();
    categoryFilter2Model4.dispose();
    textFieldFocusNode2?.dispose();
    textController2?.dispose();

    textFieldFocusNode3?.dispose();
    textController3?.dispose();
  }
}
