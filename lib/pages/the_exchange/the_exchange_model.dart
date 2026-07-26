import '/backend/api_requests/api_calls.dart';
import '/backend/custom_cloud_functions/custom_cloud_function_response_manager.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/old_designs/premium_story/premium_story_widget.dart';
import '/index.dart';
import 'the_exchange_widget.dart' show TheExchangeWidget;
import 'package:flutter/material.dart';

class TheExchangeModel extends FlutterFlowModel<TheExchangeWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Cloud Function - ffPrivateApiCall] action in IconButton widget.
  FfPrivateApiCallCloudFunctionCallResponse? cloudFunctiony0i;
  // Stores action output result for [Backend Call - API (getBusinessDetails)] action in RefinedPost widget.
  ApiCallResponse? apiResult9is;
  // Model for PremiumStory component.
  late PremiumStoryModel premiumStoryModel1;
  // Model for PremiumStory component.
  late PremiumStoryModel premiumStoryModel2;
  // Model for PremiumStory component.
  late PremiumStoryModel premiumStoryModel3;
  // Model for PremiumStory component.
  late PremiumStoryModel premiumStoryModel4;
  // Model for PremiumStory component.
  late PremiumStoryModel premiumStoryModel5;
  bool isDataUploading_uploadDataAuq = false;
  FFUploadedFile uploadedLocalFile_uploadDataAuq =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataAuq = '';

  // State field(s) for postInput widget.
  FocusNode? postInputFocusNode;
  TextEditingController? postInputTextController;
  String? Function(BuildContext, String?)? postInputTextControllerValidator;

  @override
  void initState(BuildContext context) {
    premiumStoryModel1 = createModel(context, () => PremiumStoryModel());
    premiumStoryModel2 = createModel(context, () => PremiumStoryModel());
    premiumStoryModel3 = createModel(context, () => PremiumStoryModel());
    premiumStoryModel4 = createModel(context, () => PremiumStoryModel());
    premiumStoryModel5 = createModel(context, () => PremiumStoryModel());
  }

  @override
  void dispose() {
    premiumStoryModel1.dispose();
    premiumStoryModel2.dispose();
    premiumStoryModel3.dispose();
    premiumStoryModel4.dispose();
    premiumStoryModel5.dispose();
    postInputFocusNode?.dispose();
    postInputTextController?.dispose();
  }
}
