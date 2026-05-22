import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'local_activity_status_model.dart';
export 'local_activity_status_model.dart';

class LocalActivityStatusWidget extends StatefulWidget {
  const LocalActivityStatusWidget({
    super.key,
    this.show_alert,
    this.alert_text,
  });

  final bool? show_alert;
  final String? alert_text;

  @override
  State<LocalActivityStatusWidget> createState() =>
      _LocalActivityStatusWidgetState();
}

class _LocalActivityStatusWidgetState extends State<LocalActivityStatusWidget> {
  late LocalActivityStatusModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LocalActivityStatusModel());

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
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
            0.0, 0.0, 0.0, FlutterFlowTheme.of(context).designToken.spacing.sm),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
                FlutterFlowTheme.of(context).designToken.radius.sm),
            border: Border.all(
              width: 1.0,
            ),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(8.0, 4.0, 8.0, 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: FlutterFlowTheme.of(context).error,
                  size: 12.0,
                ),
                Text(
                  valueOrDefault<String>(
                    widget.alert_text,
                    'INACTIVITY DECAY: -5% IMPACT',
                  ),
                  style: FlutterFlowTheme.of(context).labelSmall.override(
                        font: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontStyle:
                              FlutterFlowTheme.of(context).labelSmall.fontStyle,
                        ),
                        color: FlutterFlowTheme.of(context).error,
                        fontSize: 10.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.bold,
                        fontStyle:
                            FlutterFlowTheme.of(context).labelSmall.fontStyle,
                        lineHeight: 1.2,
                      ),
                ),
              ].divide(SizedBox(
                  width: FlutterFlowTheme.of(context).designToken.spacing.xs)),
            ),
          ),
        ),
      ),
    );
  }
}
