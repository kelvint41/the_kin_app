import '/components/legal_section_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'terms_of_service_page_widget.dart' show TermsOfServicePageWidget;
import 'package:flutter/material.dart';

class TermsOfServicePageModel
    extends FlutterFlowModel<TermsOfServicePageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for LegalSection.
  late LegalSectionModel legalSectionModel1;
  // Model for LegalSection.
  late LegalSectionModel legalSectionModel2;
  // Model for LegalSection.
  late LegalSectionModel legalSectionModel3;
  // Model for LegalSection.
  late LegalSectionModel legalSectionModel4;

  @override
  void initState(BuildContext context) {
    legalSectionModel1 = createModel(context, () => LegalSectionModel());
    legalSectionModel2 = createModel(context, () => LegalSectionModel());
    legalSectionModel3 = createModel(context, () => LegalSectionModel());
    legalSectionModel4 = createModel(context, () => LegalSectionModel());
  }

  @override
  void dispose() {
    legalSectionModel1.dispose();
    legalSectionModel2.dispose();
    legalSectionModel3.dispose();
    legalSectionModel4.dispose();
  }
}
