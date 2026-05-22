import '/components/google_review_card_widget.dart';
import '/components/local_sparkline_widget.dart';
import '/components/recovery_opportunity_card_widget.dart';
import '/components/review_button_widget.dart';
import '/flutter_flow/flutter_flow_charts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'business_dashboard2_widget.dart' show BusinessDashboard2Widget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class BusinessDashboard2Model
    extends FlutterFlowModel<BusinessDashboard2Widget> {
  ///  State fields for stateful widgets in this page.

  // Model for LocalSparkline component.
  late LocalSparklineModel localSparklineModel;
  // Model for ReviewButton component.
  late ReviewButtonModel reviewButtonModel;
  // Model for GoogleReviewCard component.
  late GoogleReviewCardModel googleReviewCardModel1;
  // Model for GoogleReviewCard component.
  late GoogleReviewCardModel googleReviewCardModel2;
  // Model for GoogleReviewCard component.
  late GoogleReviewCardModel googleReviewCardModel3;
  // Model for RecoveryOpportunityCard component.
  late RecoveryOpportunityCardModel recoveryOpportunityCardModel;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {
    localSparklineModel = createModel(context, () => LocalSparklineModel());
    reviewButtonModel = createModel(context, () => ReviewButtonModel());
    googleReviewCardModel1 =
        createModel(context, () => GoogleReviewCardModel());
    googleReviewCardModel2 =
        createModel(context, () => GoogleReviewCardModel());
    googleReviewCardModel3 =
        createModel(context, () => GoogleReviewCardModel());
    recoveryOpportunityCardModel =
        createModel(context, () => RecoveryOpportunityCardModel());
  }

  @override
  void dispose() {
    localSparklineModel.dispose();
    reviewButtonModel.dispose();
    googleReviewCardModel1.dispose();
    googleReviewCardModel2.dispose();
    googleReviewCardModel3.dispose();
    recoveryOpportunityCardModel.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
