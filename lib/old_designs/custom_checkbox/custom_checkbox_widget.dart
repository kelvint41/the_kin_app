import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'custom_checkbox_model.dart';
export 'custom_checkbox_model.dart';

class CustomCheckboxWidget extends StatefulWidget {
  const CustomCheckboxWidget({
    super.key,
    this.active,
    this.label,
  });

  final bool? active;
  final String? label;

  @override
  State<CustomCheckboxWidget> createState() => _CustomCheckboxWidgetState();
}

class _CustomCheckboxWidgetState extends State<CustomCheckboxWidget> {
  late CustomCheckboxModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CustomCheckboxModel());
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
            color: widget.active == false
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
              widget.label,
              'I agree to the Terms of Service and Privacy Policy',
            ),
            maxLines: 2,
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  font: GoogleFonts.plusJakartaSans(
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
