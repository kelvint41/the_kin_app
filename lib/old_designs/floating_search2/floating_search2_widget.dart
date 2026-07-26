import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'floating_search2_model.dart';
export 'floating_search2_model.dart';

class FloatingSearch2Widget extends StatefulWidget {
  const FloatingSearch2Widget({super.key});

  @override
  State<FloatingSearch2Widget> createState() => _FloatingSearch2WidgetState();
}

class _FloatingSearch2WidgetState extends State<FloatingSearch2Widget> {
  late FloatingSearch2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FloatingSearch2Model());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.all(FlutterFlowTheme.of(context).designToken.spacing.lg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
            FlutterFlowTheme.of(context).designToken.radius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 12.0,
            sigmaY: 12.0,
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
                FlutterFlowTheme.of(context).designToken.spacing.md,
                FlutterFlowTheme.of(context).designToken.spacing.sm,
                FlutterFlowTheme.of(context).designToken.spacing.md,
                FlutterFlowTheme.of(context).designToken.spacing.sm),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                    FlutterFlowTheme.of(context).designToken.radius.lg),
                border: Border.all(
                  color: FlutterFlowTheme.of(context).divider,
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: FlutterFlowTheme.of(context).primary,
                    size: 22.0,
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Search KIN-DEX businesses...',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.playfairDisplay(
                              fontWeight: FontWeight.normal,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).hint,
                            fontSize: 14.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.normal,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                            lineHeight: 1.5,
                          ),
                    ),
                  ),
                  Container(
                    width: 1.0,
                    height: 24.0,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).divider,
                    ),
                  ),
                  FlutterFlowIconButton(
                    buttonSize: 40.0,
                    icon: Icon(
                      Icons.tune_rounded,
                      color: FlutterFlowTheme.of(context).primary,
                      size: 22.0,
                    ),
                    onPressed: () {
                      print('IconButton pressed ...');
                    },
                  ),
                ].divide(SizedBox(
                    width:
                        FlutterFlowTheme.of(context).designToken.spacing.md)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
