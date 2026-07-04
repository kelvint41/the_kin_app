import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'form_field_model.dart';
export 'form_field_model.dart';

class FormFieldWidget extends StatefulWidget {
  const FormFieldWidget({
    super.key,
    this.label,
    this.hint,
    this.icon,
  });

  final String? label;
  final String? hint;
  final String? icon;

  @override
  State<FormFieldWidget> createState() => _FormFieldWidgetState();
}

class _FormFieldWidgetState extends State<FormFieldWidget> {
  late FormFieldModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FormFieldModel());

    _model.textController ??= TextEditingController(text: '');
    _model.textFieldFocusNode ??= FocusNode();
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
            widget!.label,
            'Full Name',
          ),
          style: FlutterFlowTheme.of(context).labelLarge.override(
                font: GoogleFonts.plusJakartaSans(
                  fontWeight:
                      FlutterFlowTheme.of(context).labelLarge.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                ),
                color: FlutterFlowTheme.of(context).secondaryText,
                letterSpacing: 0.0,
                fontWeight: FlutterFlowTheme.of(context).labelLarge.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
              ),
        ),
        Container(
          width: MediaQuery.sizeOf(context).width * 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 0.0,
                height: 0.0,
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(
                      FlutterFlowTheme.of(context).designToken.radius.sm),
                  border: Border.all(
                    color: FlutterFlowTheme.of(context).outline,
                    width: 1.0,
                  ),
                ),
                child: Container(
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                        FlutterFlowTheme.of(context).designToken.spacing.sm,
                        FlutterFlowTheme.of(context).designToken.spacing.sm,
                        FlutterFlowTheme.of(context).designToken.spacing.sm,
                        FlutterFlowTheme.of(context).designToken.spacing.sm),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          color: FlutterFlowTheme.of(context).primaryText,
                          size: 16.0,
                        ),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _model.textController,
                            focusNode: _model.textFieldFocusNode,
                            obscureText: false,
                            decoration: InputDecoration(
                              hintText: 'Enter your name',
                              hintStyle: TextStyle(
                                color: FlutterFlowTheme.of(context).hint,
                              ),
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                            ),
                            style: TextStyle(
                              color: FlutterFlowTheme.of(context).primaryText,
                            ),
                            validator: _model.textControllerValidator
                                .asValidator(context),
                          ),
                        ),
                        Container(
                          width: 0.0,
                          height: 0.0,
                        ),
                      ].divide(SizedBox(
                          width: FlutterFlowTheme.of(context)
                              .designToken
                              .spacing
                              .sm)),
                    ),
                  ),
                ),
              ),
              Container(
                width: 0.0,
                height: 0.0,
              ),
            ].divide(SizedBox(height: 6.0)),
          ),
        ),
      ].divide(SizedBox(
          height: FlutterFlowTheme.of(context).designToken.spacing.sm)),
    );
  }
}
