import '/components/cinematic_reel_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'onboarding_step3_widget.dart' show OnboardingStep3Widget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class OnboardingStep3Model extends FlutterFlowModel<OnboardingStep3Widget> {
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
