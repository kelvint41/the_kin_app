import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'local_punch_slot_gold_model.dart';
export 'local_punch_slot_gold_model.dart';

class LocalPunchSlotGoldWidget extends StatefulWidget {
  const LocalPunchSlotGoldWidget({
    super.key,
    this.completed,
  });

  final bool? completed;

  @override
  State<LocalPunchSlotGoldWidget> createState() =>
      _LocalPunchSlotGoldWidgetState();
}

class _LocalPunchSlotGoldWidgetState extends State<LocalPunchSlotGoldWidget> {
  late LocalPunchSlotGoldModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LocalPunchSlotGoldModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32.0,
      height: 32.0,
      decoration: BoxDecoration(
        color: widget.completed == true
            ? FlutterFlowTheme.of(context).primary
            : FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(
            FlutterFlowTheme.of(context).designToken.radius.md),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary,
          width: 1.0,
        ),
      ),
      alignment: AlignmentDirectional(0.0, 0.0),
      child: Icon(
        Icons.check_rounded,
        color: FlutterFlowTheme.of(context).primaryBackground,
        size: 18.0,
      ),
    );
  }
}
