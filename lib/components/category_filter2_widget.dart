import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'category_filter2_model.dart';
export 'category_filter2_model.dart';

class CategoryFilter2Widget extends StatefulWidget {
  const CategoryFilter2Widget({
    super.key,
    this.selected,
    this.label,
  });

  final bool? selected;
  final String? label;

  @override
  State<CategoryFilter2Widget> createState() => _CategoryFilter2WidgetState();
}

class _CategoryFilter2WidgetState extends State<CategoryFilter2Widget> {
  late CategoryFilter2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CategoryFilter2Model());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
          0.0, 0.0, FlutterFlowTheme.of(context).designToken.spacing.sm, 0.0),
      child: Container(
        decoration: BoxDecoration(
          color: widget!.selected == false
              ? FlutterFlowTheme.of(context).secondaryBackground
              : FlutterFlowTheme.of(context).primary,
          borderRadius: BorderRadius.circular(
              FlutterFlowTheme.of(context).designToken.radius.full),
          border: Border.all(
            color: FlutterFlowTheme.of(context).primary,
            width: 1.0,
          ),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
              FlutterFlowTheme.of(context).designToken.spacing.lg,
              FlutterFlowTheme.of(context).designToken.spacing.md,
              FlutterFlowTheme.of(context).designToken.spacing.lg,
              FlutterFlowTheme.of(context).designToken.spacing.md),
          child: Text(
            valueOrDefault<String>(
              widget!.label,
              'Retail',
            ),
            style: FlutterFlowTheme.of(context).labelLarge.override(
                  font: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.w600,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelLarge.fontStyle,
                  ),
                  color: widget!.selected == false
                      ? FlutterFlowTheme.of(context).secondaryText
                      : FlutterFlowTheme.of(context).primaryBackground,
                  fontSize: 14.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w600,
                  fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                  lineHeight: 1.3,
                ),
          ),
        ),
      ),
    );
  }
}
