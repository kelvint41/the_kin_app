import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'cat_chip2_model.dart';
export 'cat_chip2_model.dart';

class CatChip2Widget extends StatefulWidget {
  const CatChip2Widget({
    super.key,
    this.selected,
    this.label,
  });

  final bool? selected;
  final String? label;

  @override
  State<CatChip2Widget> createState() => _CatChip2WidgetState();
}

class _CatChip2WidgetState extends State<CatChip2Widget> {
  late CatChip2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CatChip2Model());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'Coffee',
          ),
          style: FlutterFlowTheme.of(context).labelLarge.override(
                font: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.w600,
                  fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                ),
                color: widget!.selected == false
                    ? FlutterFlowTheme.of(context).primaryText
                    : FlutterFlowTheme.of(context).primaryBackground,
                fontSize: 14.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w600,
                fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                lineHeight: 1.3,
              ),
        ),
      ),
    );
  }
}
