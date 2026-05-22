import '/components/form_section_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'business_input_form_page_widget.dart' show BusinessInputFormPageWidget;
import 'package:flutter/material.dart';

class BusinessInputFormPageModel
    extends FlutterFlowModel<BusinessInputFormPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for FormSection.
  late FormSectionModel formSectionModel1;
  // Model for FormSection.
  late FormSectionModel formSectionModel2;
  // Model for FormSection.
  late FormSectionModel formSectionModel3;
  // Model for FormSection.
  late FormSectionModel formSectionModel4;

  @override
  void initState(BuildContext context) {
    formSectionModel1 = createModel(context, () => FormSectionModel());
    formSectionModel2 = createModel(context, () => FormSectionModel());
    formSectionModel3 = createModel(context, () => FormSectionModel());
    formSectionModel4 = createModel(context, () => FormSectionModel());
  }

  @override
  void dispose() {
    formSectionModel1.dispose();
    formSectionModel2.dispose();
    formSectionModel3.dispose();
    formSectionModel4.dispose();
  }
}
