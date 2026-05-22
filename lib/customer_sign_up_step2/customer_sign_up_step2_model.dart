import '/components/step_indicator_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'customer_sign_up_step2_widget.dart' show CustomerSignUpStep2Widget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_palette/material_palette.dart';
import 'package:provider/provider.dart';

class CustomerSignUpStep2Model
    extends FlutterFlowModel<CustomerSignUpStep2Widget> {
  ///  State fields for stateful widgets in this page.

  // Model for StepIndicator component.
  late StepIndicatorModel stepIndicatorModel;

  @override
  void initState(BuildContext context) {
    stepIndicatorModel = createModel(context, () => StepIndicatorModel());
  }

  @override
  void dispose() {
    stepIndicatorModel.dispose();
  }
}
