import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'portfolio_impact_card_model.dart';
export 'portfolio_impact_card_model.dart';

class PortfolioImpactCardWidget extends StatefulWidget {
  const PortfolioImpactCardWidget({super.key});

  @override
  State<PortfolioImpactCardWidget> createState() =>
      _PortfolioImpactCardWidgetState();
}

class _PortfolioImpactCardWidgetState extends State<PortfolioImpactCardWidget> {
  late PortfolioImpactCardModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PortfolioImpactCardModel());
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
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(
            FlutterFlowTheme.of(context).designToken.radius.lg),
        border: Border.all(
          color: FlutterFlowTheme.of(context).divider,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding:
            EdgeInsets.all(FlutterFlowTheme.of(context).designToken.spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Portfolio Impact',
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                        font: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontStyle: FlutterFlowTheme.of(context)
                              .titleMedium
                              .fontStyle,
                        ),
                        color: FlutterFlowTheme.of(context).primaryText,
                        fontSize: 17.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w600,
                        fontStyle:
                            FlutterFlowTheme.of(context).titleMedium.fontStyle,
                        lineHeight: 1.4,
                      ),
                ),
                Text(
                  '70%',
                  style: FlutterFlowTheme.of(context).labelLarge.override(
                        font: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontStyle:
                              FlutterFlowTheme.of(context).labelLarge.fontStyle,
                        ),
                        color: FlutterFlowTheme.of(context).primary,
                        fontSize: 14.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w600,
                        fontStyle:
                            FlutterFlowTheme.of(context).labelLarge.fontStyle,
                        lineHeight: 1.3,
                      ),
                ),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(
                  FlutterFlowTheme.of(context).designToken.radius.full),
              child: Container(
                height: 12.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).divider,
                  borderRadius: BorderRadius.circular(
                      FlutterFlowTheme.of(context).designToken.radius.full),
                ),
                child: Align(
                  alignment: AlignmentDirectional(-1.0, 0.0),
                  child: Container(
                    width: MediaQuery.sizeOf(context).width * 0.7,
                    height: 12.0,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          FlutterFlowTheme.of(context).primary,
                          FlutterFlowTheme.of(context).accent1
                        ],
                        stops: [0.0, 1.0],
                        begin: AlignmentDirectional(-1.0, 0.0),
                        end: AlignmentDirectional(1.0, 0),
                      ),
                      borderRadius: BorderRadius.circular(
                          FlutterFlowTheme.of(context).designToken.radius.full),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_graph_rounded,
                  color: FlutterFlowTheme.of(context).success,
                  size: 16.0,
                ),
                Text(
                  'You\'ve supported 7 local businesses this month',
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        font: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.normal,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodySmall.fontStyle,
                        ),
                        color: FlutterFlowTheme.of(context).secondaryText,
                        fontSize: 12.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.normal,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodySmall.fontStyle,
                        lineHeight: 1.4,
                      ),
                ),
              ].divide(SizedBox(
                  width: FlutterFlowTheme.of(context).designToken.spacing.sm)),
            ),
          ].divide(SizedBox(
              height: FlutterFlowTheme.of(context).designToken.spacing.md)),
        ),
      ),
    );
  }
}
