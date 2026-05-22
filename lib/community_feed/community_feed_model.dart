import '/components/premium_story_widget.dart';
import '/components/refined_post_widget.dart';
import '/components/kin_bottom_nav_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'community_feed_widget.dart' show CommunityFeedWidget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CommunityFeedModel extends FlutterFlowModel<CommunityFeedWidget> {
  ///  State fields for stateful widgets in this page.

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
  // Model for RefinedPost component.
  late RefinedPostModel refinedPostModel1;
  // Model for RefinedPost component.
  late RefinedPostModel refinedPostModel2;
  // Model for RefinedPost component.
  late RefinedPostModel refinedPostModel3;
  // Model for KinBottomNav component.
  late KinBottomNavModel kinBottomNavModel;

  @override
  void initState(BuildContext context) {
    premiumStoryModel1 = createModel(context, () => PremiumStoryModel());
    premiumStoryModel2 = createModel(context, () => PremiumStoryModel());
    premiumStoryModel3 = createModel(context, () => PremiumStoryModel());
    premiumStoryModel4 = createModel(context, () => PremiumStoryModel());
    premiumStoryModel5 = createModel(context, () => PremiumStoryModel());
    refinedPostModel1 = createModel(context, () => RefinedPostModel());
    refinedPostModel2 = createModel(context, () => RefinedPostModel());
    refinedPostModel3 = createModel(context, () => RefinedPostModel());
    kinBottomNavModel = createModel(context, () => KinBottomNavModel());
  }

  @override
  void dispose() {
    premiumStoryModel1.dispose();
    premiumStoryModel2.dispose();
    premiumStoryModel3.dispose();
    premiumStoryModel4.dispose();
    premiumStoryModel5.dispose();
    refinedPostModel1.dispose();
    refinedPostModel2.dispose();
    refinedPostModel3.dispose();
    kinBottomNavModel.dispose();
  }
}
