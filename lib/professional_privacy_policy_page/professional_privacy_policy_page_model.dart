import '/components/highlight_box_widget.dart';
import '/components/policy_section_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'professional_privacy_policy_page_widget.dart'
    show ProfessionalPrivacyPolicyPageWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ProfessionalPrivacyPolicyPageModel
    extends FlutterFlowModel<ProfessionalPrivacyPolicyPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for PolicySection.
  late PolicySectionModel policySectionModel1;
  // Model for HighlightBox.
  late HighlightBoxModel highlightBoxModel;
  // Model for PolicySection.
  late PolicySectionModel policySectionModel2;
  // Model for PolicySection.
  late PolicySectionModel policySectionModel3;

  @override
  void initState(BuildContext context) {
    policySectionModel1 = createModel(context, () => PolicySectionModel());
    highlightBoxModel = createModel(context, () => HighlightBoxModel());
    policySectionModel2 = createModel(context, () => PolicySectionModel());
    policySectionModel3 = createModel(context, () => PolicySectionModel());
  }

  @override
  void dispose() {
    policySectionModel1.dispose();
    highlightBoxModel.dispose();
    policySectionModel2.dispose();
    policySectionModel3.dispose();
  }
}
