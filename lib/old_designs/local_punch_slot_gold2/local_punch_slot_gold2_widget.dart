import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'local_punch_slot_gold2_model.dart';
export 'local_punch_slot_gold2_model.dart';

class LocalPunchSlotGold2Widget extends StatefulWidget {
  const LocalPunchSlotGold2Widget({
    super.key,
    this.completed,
  });

  final bool? completed;

  @override
  State<LocalPunchSlotGold2Widget> createState() =>
      _LocalPunchSlotGold2WidgetState();
}

class _LocalPunchSlotGold2WidgetState extends State<LocalPunchSlotGold2Widget> {
  late LocalPunchSlotGold2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LocalPunchSlotGold2Model());
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
        color: widget!.completed == true
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
