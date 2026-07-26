import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'step_indicator3_model.dart';
export 'step_indicator3_model.dart';

class StepIndicator3Widget extends StatefulWidget {
  const StepIndicator3Widget({
    super.key,
    double? currentStep,
  }) : this.currentStep = currentStep ?? 1.0;

  final double currentStep;

  @override
  State<StepIndicator3Widget> createState() => _StepIndicator3WidgetState();
}

class _StepIndicator3WidgetState extends State<StepIndicator3Widget> {
  late StepIndicator3Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => StepIndicator3Model());
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
        Expanded(
          flex: 1,
          child: Container(
            height: 4.0,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primaryText,
              borderRadius: BorderRadius.circular(9999.0),
              shape: BoxShape.rectangle,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            height: 4.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9999.0),
              shape: BoxShape.rectangle,
            ),
          ),
        ),
      ].divide(SizedBox(width: 16.0)),
    );
  }
}
