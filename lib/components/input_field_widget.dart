import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'input_field_model.dart';
export 'input_field_model.dart';

class InputFieldWidget extends StatefulWidget {
  const InputFieldWidget({
    super.key,
    String? label,
    String? hint,
    this.icon,
  })  : this.label = label ?? 'Email Address',
        this.hint = hint ?? 'Enter your email';

  final String label;
  final String hint;
  final Widget? icon;

  @override
  State<InputFieldWidget> createState() => _InputFieldWidgetState();
}

class _InputFieldWidgetState extends State<InputFieldWidget> {
  late InputFieldModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => InputFieldModel());
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          valueOrDefault<String>(
            widget.label,
            'Email Address',
          ),
          style: FlutterFlowTheme.of(context).labelMedium.override(
                font: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                ),
                color: FlutterFlowTheme.of(context).primaryText,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w600,
                fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                lineHeight: 1.4,
              ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFF1A1B1B),
            borderRadius: BorderRadius.circular(12.0),
            shape: BoxShape.rectangle,
            border: Border.all(
              color: Color(0x4D0B4632),
              width: 1.0,
            ),
          ),
          child: Container(
            width: 0.0,
            height: 0.0,
          ),
        ),
      ].divide(SizedBox(height: 4.0)),
    );
  }
}
