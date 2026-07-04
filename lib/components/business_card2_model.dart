import '/components/rating_bar_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'business_card2_widget.dart' show BusinessCard2Widget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class BusinessCard2Model extends FlutterFlowModel<BusinessCard2Widget> {
  ///  State fields for stateful widgets in this component.

  // Model for RatingBar.
  late RatingBarModel ratingBarModel;

  @override
  void initState(BuildContext context) {
    ratingBarModel = createModel(context, () => RatingBarModel());
  }

  @override
  void dispose() {
    ratingBarModel.dispose();
  }
}
