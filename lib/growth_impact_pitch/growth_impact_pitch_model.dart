import '/components/impact_growth_card2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'growth_impact_pitch_widget.dart' show GrowthImpactPitchWidget;
import 'package:flutter/material.dart';

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
