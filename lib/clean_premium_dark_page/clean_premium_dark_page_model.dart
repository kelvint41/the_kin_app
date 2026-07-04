import '/components/legal_section2_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'clean_premium_dark_page_widget.dart' show CleanPremiumDarkPageWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CleanPremiumDarkPageModel
    extends FlutterFlowModel<CleanPremiumDarkPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for LegalSection.
  late LegalSection2Model legalSectionModel1;
  // Model for LegalSection.
  late LegalSection2Model legalSectionModel2;
  // Model for LegalSection.
  late LegalSection2Model legalSectionModel3;
  // Model for LegalSection.
  late LegalSection2Model legalSectionModel4;

  @override
  void initState(BuildContext context) {
    legalSectionModel1 = createModel(context, () => LegalSection2Model());
    legalSectionModel2 = createModel(context, () => LegalSection2Model());
    legalSectionModel3 = createModel(context, () => LegalSection2Model());
    legalSectionModel4 = createModel(context, () => LegalSection2Model());
  }

  @override
  void dispose() {
    legalSectionModel1.dispose();
    legalSectionModel2.dispose();
    legalSectionModel3.dispose();
    legalSectionModel4.dispose();
  }
}
