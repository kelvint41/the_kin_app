import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/legal_header_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:async';
import 'dart:ui';
import '/index.dart';
import 'partner_l_o_i_page_widget.dart' show PartnerLOIPageWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PartnerLOIPageModel extends FlutterFlowModel<PartnerLOIPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for LegalHeader.
  late LegalHeaderModel legalHeaderModel1;
  // Model for LegalHeader.
  late LegalHeaderModel legalHeaderModel2;
  // Model for LegalHeader.
  late LegalHeaderModel legalHeaderModel3;
  // Model for LegalHeader.
  late LegalHeaderModel legalHeaderModel4;
  // State field(s) for Checkbox widget.
  bool? checkboxValue;

  @override
  void initState(BuildContext context) {
    legalHeaderModel1 = createModel(context, () => LegalHeaderModel());
    legalHeaderModel2 = createModel(context, () => LegalHeaderModel());
    legalHeaderModel3 = createModel(context, () => LegalHeaderModel());
    legalHeaderModel4 = createModel(context, () => LegalHeaderModel());
  }

  @override
  void dispose() {
    legalHeaderModel1.dispose();
    legalHeaderModel2.dispose();
    legalHeaderModel3.dispose();
    legalHeaderModel4.dispose();
  }
}
