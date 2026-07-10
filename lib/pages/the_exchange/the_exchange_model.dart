import '/flutter_flow/flutter_flow_util.dart';
import '/old_designs/premium_story/premium_story_widget.dart';
import '/index.dart';
import 'the_exchange_widget.dart' show TheExchangeWidget;
import 'package:flutter/material.dart';

class TheExchangeModel extends FlutterFlowModel<TheExchangeWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for PostText widget.
  FocusNode? postTextFieldFocusNode;
  TextEditingController? postTextController;
  String? Function(BuildContext, String?)? postTextControllerValidator;
  // State field(s) for the feed composer bar.
  FocusNode? feedComposerFocusNode;
  TextEditingController? feedComposerController;
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
    feedComposerFocusNode?.dispose();
    feedComposerController?.dispose();

    premiumStoryModel1.dispose();
    premiumStoryModel2.dispose();
    premiumStoryModel3.dispose();
    premiumStoryModel4.dispose();
    premiumStoryModel5.dispose();
  }
}
