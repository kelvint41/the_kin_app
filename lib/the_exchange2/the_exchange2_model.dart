import '/components/constructive_filter_badge2_widget.dart';
import '/components/google_review_card2dca92d0_a25702c22_widget.dart';
import '/components/local_activity_status2_widget.dart';
import '/components/local_black_owned_badge_widget.dart';
import '/components/moderation_info_note2_widget.dart';
import '/components/post_actions2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'the_exchange2_widget.dart' show TheExchange2Widget;
import 'package:flutter/material.dart';

class TheExchange2Model extends FlutterFlowModel<TheExchange2Widget> {
  ///  State fields for stateful widgets in this page.

  // Model for LocalBlackOwnedBadge component.
  late LocalBlackOwnedBadgeModel localBlackOwnedBadgeModel1;
  // Model for PostActions2 component.
  late PostActions2Model postActions2Model1;
  // Model for GoogleReviewCard2dca92d0A25702c22 component.
  late GoogleReviewCard2dca92d0A25702c22Model
      googleReviewCard2dca92d0A25702c22Model1;
  // Model for GoogleReviewCard2dca92d0A25702c22 component.
  late GoogleReviewCard2dca92d0A25702c22Model
      googleReviewCard2dca92d0A25702c22Model2;
  // Model for GoogleReviewCard2dca92d0A25702c22 component.
  late GoogleReviewCard2dca92d0A25702c22Model
      googleReviewCard2dca92d0A25702c22Model3;
  // Model for LocalBlackOwnedBadge component.
  late LocalBlackOwnedBadgeModel localBlackOwnedBadgeModel2;
  // Model for LocalActivityStatus2 component.
  late LocalActivityStatus2Model localActivityStatus2Model;
  // Model for PostActions2 component.
  late PostActions2Model postActions2Model2;
  // Model for ModerationInfoNote2 component.
  late ModerationInfoNote2Model moderationInfoNote2Model;
  // Model for ConstructiveFilterBadge2 component.
  late ConstructiveFilterBadge2Model constructiveFilterBadge2Model;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {
    localBlackOwnedBadgeModel1 =
        createModel(context, () => LocalBlackOwnedBadgeModel());
    postActions2Model1 = createModel(context, () => PostActions2Model());
    googleReviewCard2dca92d0A25702c22Model1 =
        createModel(context, () => GoogleReviewCard2dca92d0A25702c22Model());
    googleReviewCard2dca92d0A25702c22Model2 =
        createModel(context, () => GoogleReviewCard2dca92d0A25702c22Model());
    googleReviewCard2dca92d0A25702c22Model3 =
        createModel(context, () => GoogleReviewCard2dca92d0A25702c22Model());
    localBlackOwnedBadgeModel2 =
        createModel(context, () => LocalBlackOwnedBadgeModel());
    localActivityStatus2Model =
        createModel(context, () => LocalActivityStatus2Model());
    postActions2Model2 = createModel(context, () => PostActions2Model());
    moderationInfoNote2Model =
        createModel(context, () => ModerationInfoNote2Model());
    constructiveFilterBadge2Model =
        createModel(context, () => ConstructiveFilterBadge2Model());
  }

  @override
  void dispose() {
    localBlackOwnedBadgeModel1.dispose();
    postActions2Model1.dispose();
    googleReviewCard2dca92d0A25702c22Model1.dispose();
    googleReviewCard2dca92d0A25702c22Model2.dispose();
    googleReviewCard2dca92d0A25702c22Model3.dispose();
    localBlackOwnedBadgeModel2.dispose();
    localActivityStatus2Model.dispose();
    postActions2Model2.dispose();
    moderationInfoNote2Model.dispose();
    constructiveFilterBadge2Model.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
