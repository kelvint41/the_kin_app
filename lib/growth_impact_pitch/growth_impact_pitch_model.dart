import '/components/impact_growth_card2_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'growth_impact_pitch_widget.dart' show GrowthImpactPitchWidget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class GrowthImpactPitchModel extends FlutterFlowModel<GrowthImpactPitchWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for ImpactGrowthCard2 component.
  late ImpactGrowthCard2Model impactGrowthCard2Model;

  @override
  void initState(BuildContext context) {
    impactGrowthCard2Model =
        createModel(context, () => ImpactGrowthCard2Model());
  }

  @override
  void dispose() {
    impactGrowthCard2Model.dispose();
  }
}
