import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'legal_section3_model.dart';
export 'legal_section3_model.dart';

class LegalSection3Widget extends StatefulWidget {
  const LegalSection3Widget({
    super.key,
    String? title,
    String? body,
  })  : this.title = title ?? 'Terms of Service',
        this.body = body ??
            'By using Kinvest Guidance, you agree to our community standards and financial advisory protocols. We provide guidance based on market data, but final investment decisions remain the responsibility of the user. Misuse of the platform for fraudulent activities will result in immediate termination of access.';

  final String title;
  final String body;

  @override
  State<LegalSection3Widget> createState() => _LegalSection3WidgetState();
}

class _LegalSection3WidgetState extends State<LegalSection3Widget> {
  late LegalSection3Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LegalSection3Model());
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
            widget.title,
            'Terms of Service',
          ),
          style: FlutterFlowTheme.of(context).titleSmall.override(
                font: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                ),
                color: FlutterFlowTheme.of(context).primaryText,
                letterSpacing: 0.0,
                fontWeight: FontWeight.bold,
                fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
              ),
        ),
        Text(
          valueOrDefault<String>(
            widget.body,
            'By using Kinvest Guidance, you agree to our community standards and financial advisory protocols. We provide guidance based on market data, but final investment decisions remain the responsibility of the user. Misuse of the platform for fraudulent activities will result in immediate termination of access.',
          ),
          style: FlutterFlowTheme.of(context).bodySmall.override(
                font: GoogleFonts.playfairDisplay(
                  fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                ),
                color: FlutterFlowTheme.of(context).secondaryText,
                letterSpacing: 0.0,
                fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                lineHeight: 1.5,
              ),
        ),
      ].divide(SizedBox(height: 4.0)),
    );
  }
}
