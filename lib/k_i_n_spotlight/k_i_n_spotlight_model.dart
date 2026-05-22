import '/components/spotlight_glass_card_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'k_i_n_spotlight_widget.dart' show KINSpotlightWidget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class KINSpotlightModel extends FlutterFlowModel<KINSpotlightWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for SpotlightGlassCard component.
  late SpotlightGlassCardModel spotlightGlassCardModel;

  @override
  void initState(BuildContext context) {
    spotlightGlassCardModel =
        createModel(context, () => SpotlightGlassCardModel());
  }

  @override
  void dispose() {
    spotlightGlassCardModel.dispose();
  }
}
