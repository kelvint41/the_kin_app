import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'punch_slot_loyalty_model.dart';
export 'punch_slot_loyalty_model.dart';

class PunchSlotLoyaltyWidget extends StatefulWidget {
  const PunchSlotLoyaltyWidget({
    super.key,
    this.completed,
  });

  final bool? completed;

  @override
  State<PunchSlotLoyaltyWidget> createState() => _PunchSlotLoyaltyWidgetState();
}

class _PunchSlotLoyaltyWidgetState extends State<PunchSlotLoyaltyWidget> {
  late PunchSlotLoyaltyModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PunchSlotLoyaltyModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48.0,
      height: 48.0,
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
        size: 24.0,
      ),
    );
  }
}
