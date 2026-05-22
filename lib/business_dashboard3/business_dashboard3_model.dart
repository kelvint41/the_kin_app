import '/components/local_sparkline2_widget.dart';
import '/components/recovery_opportunity_card2_widget.dart';
import '/components/review_button2_widget.dart';
import '/components/roi_metric_card_widget.dart';
import '/flutter_flow/flutter_flow_charts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'business_dashboard3_widget.dart' show BusinessDashboard3Widget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class BusinessDashboard3Model
    extends FlutterFlowModel<BusinessDashboard3Widget> {
  ///  State fields for stateful widgets in this page.

  // Model for LocalSparkline2 component.
  late LocalSparkline2Model localSparkline2Model;
  // Model for ReviewButton2 component.
  late ReviewButton2Model reviewButton2Model;
  // Model for RoiMetricCard component.
  late RoiMetricCardModel roiMetricCardModel;
  // Model for RecoveryOpportunityCard2 component.
  late RecoveryOpportunityCard2Model recoveryOpportunityCard2Model;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {
    localSparkline2Model = createModel(context, () => LocalSparkline2Model());
    reviewButton2Model = createModel(context, () => ReviewButton2Model());
    roiMetricCardModel = createModel(context, () => RoiMetricCardModel());
    recoveryOpportunityCard2Model =
        createModel(context, () => RecoveryOpportunityCard2Model());
  }

  @override
  void dispose() {
    localSparkline2Model.dispose();
    reviewButton2Model.dispose();
    roiMetricCardModel.dispose();
    recoveryOpportunityCard2Model.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
