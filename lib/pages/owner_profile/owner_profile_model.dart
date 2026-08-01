import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/metric_card4_widget.dart';
import '/components/review_item_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'owner_profile_widget.dart' show OwnerProfileWidget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class OwnerProfileModel extends FlutterFlowModel<OwnerProfileWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for MetricCard.
  late MetricCard4Model metricCardModel1;
  // Model for MetricCard.
  late MetricCard4Model metricCardModel2;
  // Model for MetricCard.
  late MetricCard4Model metricCardModel3;
  // Model for MetricCard.
  late MetricCard4Model metricCardModel4;
  // Model for ReviewItem.
  late ReviewItemModel reviewItemModel;

  @override
  void initState(BuildContext context) {
    metricCardModel1 = createModel(context, () => MetricCard4Model());
    metricCardModel2 = createModel(context, () => MetricCard4Model());
    metricCardModel3 = createModel(context, () => MetricCard4Model());
    metricCardModel4 = createModel(context, () => MetricCard4Model());
    reviewItemModel = createModel(context, () => ReviewItemModel());
  }

  @override
  void dispose() {
    metricCardModel1.dispose();
    metricCardModel2.dispose();
    metricCardModel3.dispose();
    metricCardModel4.dispose();
    reviewItemModel.dispose();
  }
}
