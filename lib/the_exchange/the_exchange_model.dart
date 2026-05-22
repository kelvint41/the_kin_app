import '/components/constructive_filter_badge_widget.dart';
import '/components/google_review_card2dca92d0_a25702c2_widget.dart';
import '/components/local_activity_status_widget.dart';
import '/components/moderation_info_note_widget.dart';
import '/components/post_actions_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'the_exchange_widget.dart' show TheExchangeWidget;
import 'package:flutter/material.dart';

class TheExchangeModel extends FlutterFlowModel<TheExchangeWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for PostActions component.
  late PostActionsModel postActionsModel1;
  // Model for GoogleReviewCard2dca92d0A25702c2 component.
  late GoogleReviewCard2dca92d0A25702c2Model
      googleReviewCard2dca92d0A25702c2Model1;
  // Model for GoogleReviewCard2dca92d0A25702c2 component.
  late GoogleReviewCard2dca92d0A25702c2Model
      googleReviewCard2dca92d0A25702c2Model2;
  // Model for GoogleReviewCard2dca92d0A25702c2 component.
  late GoogleReviewCard2dca92d0A25702c2Model
      googleReviewCard2dca92d0A25702c2Model3;
  // Model for LocalActivityStatus component.
  late LocalActivityStatusModel localActivityStatusModel;
  // Model for PostActions component.
  late PostActionsModel postActionsModel2;
  // Model for ModerationInfoNote component.
  late ModerationInfoNoteModel moderationInfoNoteModel;
  // Model for ConstructiveFilterBadge component.
  late ConstructiveFilterBadgeModel constructiveFilterBadgeModel;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {
    postActionsModel1 = createModel(context, () => PostActionsModel());
    googleReviewCard2dca92d0A25702c2Model1 =
        createModel(context, () => GoogleReviewCard2dca92d0A25702c2Model());
    googleReviewCard2dca92d0A25702c2Model2 =
        createModel(context, () => GoogleReviewCard2dca92d0A25702c2Model());
    googleReviewCard2dca92d0A25702c2Model3 =
        createModel(context, () => GoogleReviewCard2dca92d0A25702c2Model());
    localActivityStatusModel =
        createModel(context, () => LocalActivityStatusModel());
    postActionsModel2 = createModel(context, () => PostActionsModel());
    moderationInfoNoteModel =
        createModel(context, () => ModerationInfoNoteModel());
    constructiveFilterBadgeModel =
        createModel(context, () => ConstructiveFilterBadgeModel());
  }

  @override
  void dispose() {
    postActionsModel1.dispose();
    googleReviewCard2dca92d0A25702c2Model1.dispose();
    googleReviewCard2dca92d0A25702c2Model2.dispose();
    googleReviewCard2dca92d0A25702c2Model3.dispose();
    localActivityStatusModel.dispose();
    postActionsModel2.dispose();
    moderationInfoNoteModel.dispose();
    constructiveFilterBadgeModel.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
