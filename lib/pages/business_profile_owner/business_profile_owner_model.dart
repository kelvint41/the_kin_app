import '/backend/backend.dart';
import '/backend/gemini/gemini.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'business_profile_owner_widget.dart' show BusinessProfileOwnerWidget;
import 'package:map_launcher/map_launcher.dart' as $ml;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class BusinessProfileOwnerModel
    extends FlutterFlowModel<BusinessProfileOwnerWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for txtRawNotes widget.
  FocusNode? txtRawNotesFocusNode;
  TextEditingController? txtRawNotesTextController;
  String? Function(BuildContext, String?)? txtRawNotesTextControllerValidator;
  // Stores action output result for [Gemini - Generate Text] action in Button widget.
  String? aiStorefrontBio;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    txtRawNotesFocusNode?.dispose();
    txtRawNotesTextController?.dispose();
  }
}
