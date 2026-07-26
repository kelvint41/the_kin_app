import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'business_profile_owner_widget.dart' show BusinessProfileOwnerWidget;
import 'package:flutter/material.dart';

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
