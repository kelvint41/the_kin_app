import '/flutter_flow/flutter_flow_util.dart';
import '/old_designs/highlight_box/highlight_box_widget.dart';
import '/old_designs/policy_section/policy_section_widget.dart';
import 'privacy_policy_page_widget.dart' show PrivacyPolicyPageWidget;
import 'package:flutter/material.dart';

class PrivacyPolicyPageModel extends FlutterFlowModel<PrivacyPolicyPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for PolicySection.
  late PolicySectionModel policySectionModel1;
  // Model for HighlightBox.
  late HighlightBoxModel highlightBoxModel;
  // Model for PolicySection.
  late PolicySectionModel policySectionModel2;
  // Model for PolicySection.
  late PolicySectionModel policySectionModel3;
  // Model for PolicySection.
  late PolicySectionModel policySectionModel4;

  @override
  void initState(BuildContext context) {
    policySectionModel1 = createModel(context, () => PolicySectionModel());
    highlightBoxModel = createModel(context, () => HighlightBoxModel());
    policySectionModel2 = createModel(context, () => PolicySectionModel());
    policySectionModel3 = createModel(context, () => PolicySectionModel());
    policySectionModel4 = createModel(context, () => PolicySectionModel());
  }

  @override
  void dispose() {
    policySectionModel1.dispose();
    highlightBoxModel.dispose();
    policySectionModel2.dispose();
    policySectionModel3.dispose();
    policySectionModel4.dispose();
  }
}
