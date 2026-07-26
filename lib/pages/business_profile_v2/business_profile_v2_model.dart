import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'business_profile_v2_widget.dart' show BusinessProfileV2Widget;
import 'package:flutter/material.dart';

class BusinessProfileV2Model extends FlutterFlowModel<BusinessProfileV2Widget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - API (getBusinessDetails)] action in BusinessProfile_V2 widget.
  ApiCallResponse? apiResultkw5;
  // State field(s) for RatingBar widget.
  double? ratingBarValue;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Stores action output result for [Custom Action - calculateRealTimeKindex] action in Column widget.
  double? updatedKindexResult;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
