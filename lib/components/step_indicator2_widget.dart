import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'step_indicator2_model.dart';
export 'step_indicator2_model.dart';

class StepIndicator2Widget extends StatefulWidget {
  const StepIndicator2Widget({super.key});

  @override
  State<StepIndicator2Widget> createState() => _StepIndicator2WidgetState();
}

class _StepIndicator2WidgetState extends State<StepIndicator2Widget> {
  late StepIndicator2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => StepIndicator2Model());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32.0,
          height: 4.0,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primary,
            borderRadius: BorderRadius.circular(
                FlutterFlowTheme.of(context).designToken.radius.full),
          ),
        ),
        Container(
          width: 32.0,
          height: 4.0,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).divider,
            borderRadius: BorderRadius.circular(
                FlutterFlowTheme.of(context).designToken.radius.full),
          ),
        ),
      ].divide(
          SizedBox(width: FlutterFlowTheme.of(context).designToken.spacing.xs)),
    );
  }
}
