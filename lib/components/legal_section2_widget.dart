import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'legal_section2_model.dart';
export 'legal_section2_model.dart';

class LegalSection2Widget extends StatefulWidget {
  const LegalSection2Widget({
    super.key,
    String? title,
    Color? headerColor,
    String? body,
  })  : this.title = title ?? '2. User Obligations',
        this.headerColor = headerColor ?? const Color(0x00000000),
        this.body = body ??
            'Users must provide accurate information when registering for the directory. Any fraudulent activity or misuse of the platform will lead to immediate account termination without notice.';

  final String title;
  final Color headerColor;
  final String body;

  @override
  State<LegalSection2Widget> createState() => _LegalSection2WidgetState();
}

class _LegalSection2WidgetState extends State<LegalSection2Widget> {
  late LegalSection2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LegalSection2Model());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valueOrDefault<String>(
            widget!.title,
            '2. User Obligations',
          ),
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
                color: widget!.headerColor,
                fontSize: 18.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.bold,
                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                lineHeight: 1.4,
              ),
        ),
        Text(
          valueOrDefault<String>(
            widget!.body,
            'Users must provide accurate information when registering for the directory. Any fraudulent activity or misuse of the platform will lead to immediate account termination without notice.',
          ),
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.plusJakartaSans(
                  fontWeight:
                      FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
                color: Color(0xFFE0E0E0),
                letterSpacing: 0.0,
                fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                lineHeight: 1.6,
              ),
        ),
      ].divide(SizedBox(height: 8.0)),
    );
  }
}
