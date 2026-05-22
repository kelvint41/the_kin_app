import '/components/cinematic_reel_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'onboarding_step1_widget.dart' show OnboardingStep1Widget;
import 'package:flutter/material.dart';

class OnboardingStep1Model extends FlutterFlowModel<OnboardingStep1Widget> {
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
