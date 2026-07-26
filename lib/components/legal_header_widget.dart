import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'legal_header_model.dart';
export 'legal_header_model.dart';

class LegalHeaderWidget extends StatefulWidget {
  const LegalHeaderWidget({
    super.key,
    String? title,
  }) : this.title = title ?? '1. PILOT PHASE OVERVIEW';

  final String title;

  @override
  State<LegalHeaderWidget> createState() => _LegalHeaderWidgetState();
}

class _LegalHeaderWidgetState extends State<LegalHeaderWidget> {
  late LegalHeaderModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LegalHeaderModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              valueOrDefault<String>(
                widget.title,
                '1. PILOT PHASE OVERVIEW',
              ),
              style: FlutterFlowTheme.of(context).titleSmall.override(
                    font: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontStyle:
                          FlutterFlowTheme.of(context).titleSmall.fontStyle,
                    ),
                    color: FlutterFlowTheme.of(context).primary,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.bold,
                    fontStyle:
                        FlutterFlowTheme.of(context).titleSmall.fontStyle,
                  ),
            ),
            Divider(
              height: 16.0,
              thickness: 1.0,
              indent: 0.0,
              endIndent: 0.0,
              color: FlutterFlowTheme.of(context).alternate,
            ),
          ].divide(SizedBox(height: 4.0)),
        ),
      ),
    );
  }
}
