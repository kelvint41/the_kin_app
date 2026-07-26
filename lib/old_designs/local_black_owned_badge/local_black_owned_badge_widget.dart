import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'local_black_owned_badge_model.dart';
export 'local_black_owned_badge_model.dart';

class LocalBlackOwnedBadgeWidget extends StatefulWidget {
  const LocalBlackOwnedBadgeWidget({super.key});

  @override
  State<LocalBlackOwnedBadgeWidget> createState() =>
      _LocalBlackOwnedBadgeWidgetState();
}

class _LocalBlackOwnedBadgeWidgetState
    extends State<LocalBlackOwnedBadgeWidget> {
  late LocalBlackOwnedBadgeModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LocalBlackOwnedBadgeModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22.0,
      height: 22.0,
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
        color: FlutterFlowTheme.of(context).primary,
        size: 12.0,
      ),
    );
  }
}
