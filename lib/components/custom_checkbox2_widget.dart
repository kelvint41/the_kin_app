import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'custom_checkbox2_model.dart';
export 'custom_checkbox2_model.dart';

class CustomCheckbox2Widget extends StatefulWidget {
  const CustomCheckbox2Widget({
    super.key,
    this.active,
    this.label,
  });

  final bool? active;
  final String? label;

  @override
  State<CustomCheckbox2Widget> createState() => _CustomCheckbox2WidgetState();
}

class _CustomCheckbox2WidgetState extends State<CustomCheckbox2Widget> {
  late CustomCheckbox2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CustomCheckbox2Model());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 22.0,
          height: 22.0,
          decoration: BoxDecoration(
            color: widget!.active == false
                ? Colors.transparent
                : FlutterFlowTheme.of(context).primary,
            borderRadius: BorderRadius.circular(
                FlutterFlowTheme.of(context).designToken.radius.sm),
            border: Border.all(
              color: FlutterFlowTheme.of(context).primary,
              width: 1.5,
            ),
          ),
          alignment: AlignmentDirectional(0.0, 0.0),
          child: Icon(
            Icons.check_rounded,
            color: FlutterFlowTheme.of(context).primaryBackground,
            size: 16.0,
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            valueOrDefault<String>(
              widget!.label,
              'I agree to the Terms of Service and Privacy Policy',
            ),
            maxLines: 2,
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  font: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.normal,
                    fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                  ),
                  color: FlutterFlowTheme.of(context).secondaryText,
                  fontSize: 12.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.normal,
                  fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                  lineHeight: 1.4,
                ),
          ),
        ),
      ].divide(
          SizedBox(width: FlutterFlowTheme.of(context).designToken.spacing.md)),
    );
  }
}
