import '/components/cinematic_reel_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'onboarding_step2_widget.dart' show OnboardingStep2Widget;
import 'package:flutter/material.dart';

class OnboardingStep2Model extends FlutterFlowModel<OnboardingStep2Widget> {
  ///  State fields for stateful widgets in this page.

  // Model for CinematicReel component.
  late CinematicReelModel cinematicReelModel;

  @override
  void initState(BuildContext context) {
    cinematicReelModel = createModel(context, () => CinematicReelModel());
  }

  @override
  void dispose() {
    cinematicReelModel.dispose();
  }
}
