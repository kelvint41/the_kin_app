import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'duration_chip2_model.dart';
export 'duration_chip2_model.dart';

class DurationChip2Widget extends StatefulWidget {
  const DurationChip2Widget({
    super.key,
    String? label,
    bool? active,
  })  : this.label = label ?? '1 Hour',
        this.active = active ?? true;

  final String label;
  final bool active;

  @override
  State<DurationChip2Widget> createState() => _DurationChip2WidgetState();
}

class _DurationChip2WidgetState extends State<DurationChip2Widget> {
  late DurationChip2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DurationChip2Model());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56.0,
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14.0),
        shape: BoxShape.rectangle,
        border: Border.all(
          color: valueOrDefault<Color>(
            valueOrDefault<bool>(
              widget!.active,
              true,
            )
                ? FlutterFlowTheme.of(context).primaryText
                : FlutterFlowTheme.of(context).alternate,
            FlutterFlowTheme.of(context).primaryText,
          ),
          width: 1.0,
        ),
      ),
      alignment: AlignmentDirectional(0.0, 0.0),
      child: Text(
        valueOrDefault<String>(
          widget!.label,
          '1 Hour',
        ),
        style: FlutterFlowTheme.of(context).bodyMedium.override(
              font: GoogleFonts.plusJakartaSans(
                fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
              ),
              color: Colors.white,
              letterSpacing: 0.0,
              fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
              lineHeight: 1.4,
            ),
      ),
    );
  }
}
