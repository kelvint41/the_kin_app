import '/components/spotlight_glass_card_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'k_i_n_spotlight_widget.dart' show KINSpotlightWidget;
import 'package:flutter/material.dart';

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
