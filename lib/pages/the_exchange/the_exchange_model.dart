import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/old_designs/premium_story/premium_story_widget.dart';
import '/old_designs/refined_post/refined_post_widget.dart';
import 'dart:ui';
import '/index.dart';
import 'the_exchange_widget.dart' show TheExchangeWidget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class TheExchangeModel extends FlutterFlowModel<TheExchangeWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - API (getBusinessDetails)] action in RefinedPost widget.
  ApiCallResponse? apiResult9is;
  // State field(s) for PostText widget.
  FocusNode? postTextFieldFocusNode;
  TextEditingController? postTextController;
  String? Function(BuildContext, String?)? postTextControllerValidator;
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
    postTextFieldFocusNode?.dispose();
    postTextController?.dispose();

    premiumStoryModel1.dispose();
    premiumStoryModel2.dispose();
    premiumStoryModel3.dispose();
    premiumStoryModel4.dispose();
    premiumStoryModel5.dispose();
  }
}
