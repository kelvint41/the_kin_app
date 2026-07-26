import '/components/legal_section3_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'legal_compliance_page_widget.dart' show LegalCompliancePageWidget;
import 'package:flutter/material.dart';

class LegalCompliancePageModel
    extends FlutterFlowModel<LegalCompliancePageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for LegalSection.
  late LegalSection3Model legalSectionModel1;
  // Model for LegalSection.
  late LegalSection3Model legalSectionModel2;
  // Model for LegalSection.
  late LegalSection3Model legalSectionModel3;
  // State field(s) for Checkbox widget.
  bool? checkboxValue1;
  // State field(s) for Checkbox widget.
  bool? checkboxValue2;

  @override
  void initState(BuildContext context) {
    legalSectionModel1 = createModel(context, () => LegalSection3Model());
    legalSectionModel2 = createModel(context, () => LegalSection3Model());
    legalSectionModel3 = createModel(context, () => LegalSection3Model());
  }

  @override
  void dispose() {
    legalSectionModel1.dispose();
    legalSectionModel2.dispose();
    legalSectionModel3.dispose();
  }
}
