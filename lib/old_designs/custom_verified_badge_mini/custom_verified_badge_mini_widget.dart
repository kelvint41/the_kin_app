import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'custom_verified_badge_mini_model.dart';
export 'custom_verified_badge_mini_model.dart';

class CustomVerifiedBadgeMiniWidget extends StatefulWidget {
  const CustomVerifiedBadgeMiniWidget({super.key});

  @override
  State<CustomVerifiedBadgeMiniWidget> createState() =>
      _CustomVerifiedBadgeMiniWidgetState();
}

class _CustomVerifiedBadgeMiniWidgetState
    extends State<CustomVerifiedBadgeMiniWidget> {
  late CustomVerifiedBadgeMiniModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CustomVerifiedBadgeMiniModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24.0,
      height: 24.0,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondary,
        borderRadius: BorderRadius.circular(
            FlutterFlowTheme.of(context).designToken.radius.full),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary,
          width: 1.0,
        ),
      ),
      alignment: AlignmentDirectional(0.0, 0.0),
      child: Icon(
        Icons.check_rounded,
        color: FlutterFlowTheme.of(context).primaryText,
        size: 14.0,
      ),
    );
  }
}
