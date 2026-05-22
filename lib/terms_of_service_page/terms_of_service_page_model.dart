import '/components/policy_section_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'terms_of_service_page_widget.dart' show TermsOfServicePageWidget;
import 'package:flutter/material.dart';

class TermsOfServicePageModel
    extends FlutterFlowModel<TermsOfServicePageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for PolicySection component.
  late PolicySectionModel policySectionModel1;
  // Model for PolicySection component.
  late PolicySectionModel policySectionModel2;
  // Model for PolicySection component.
  late PolicySectionModel policySectionModel3;
  // Model for PolicySection component.
  late PolicySectionModel policySectionModel4;

  @override
  void initState(BuildContext context) {
    policySectionModel1 = createModel(context, () => PolicySectionModel());
    policySectionModel2 = createModel(context, () => PolicySectionModel());
    policySectionModel3 = createModel(context, () => PolicySectionModel());
    policySectionModel4 = createModel(context, () => PolicySectionModel());
  }

  @override
  void dispose() {
    policySectionModel1.dispose();
    policySectionModel2.dispose();
    policySectionModel3.dispose();
    policySectionModel4.dispose();
  }
}
