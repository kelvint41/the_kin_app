import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'local_punch_slot_gold_b15344203ba6999d_model.dart';
export 'local_punch_slot_gold_b15344203ba6999d_model.dart';

class LocalPunchSlotGoldB15344203ba6999dWidget extends StatefulWidget {
  const LocalPunchSlotGoldB15344203ba6999dWidget({
    super.key,
    this.completed,
  });

  final bool? completed;

  @override
  State<LocalPunchSlotGoldB15344203ba6999dWidget> createState() =>
      _LocalPunchSlotGoldB15344203ba6999dWidgetState();
}

class _LocalPunchSlotGoldB15344203ba6999dWidgetState
    extends State<LocalPunchSlotGoldB15344203ba6999dWidget> {
  late LocalPunchSlotGoldB15344203ba6999dModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model =
        createModel(context, () => LocalPunchSlotGoldB15344203ba6999dModel());

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
      width: 44.0,
      height: 44.0,
      decoration: BoxDecoration(
        color: widget.completed == false
            ? Colors.transparent
            : FlutterFlowTheme.of(context).primary,
        borderRadius: BorderRadius.circular(
            FlutterFlowTheme.of(context).designToken.radius.full),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary,
          width: 2.0,
        ),
      ),
      alignment: AlignmentDirectional(0.0, 0.0),
      child: Icon(
        Icons.check_rounded,
        color: FlutterFlowTheme.of(context).primaryBackground,
        size: 20.0,
      ),
    );
  }
}
