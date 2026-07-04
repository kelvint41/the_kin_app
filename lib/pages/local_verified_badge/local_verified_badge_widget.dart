import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'local_verified_badge_model.dart';
export 'local_verified_badge_model.dart';

class LocalVerifiedBadgeWidget extends StatefulWidget {
  const LocalVerifiedBadgeWidget({super.key});

  @override
  State<LocalVerifiedBadgeWidget> createState() =>
      _LocalVerifiedBadgeWidgetState();
}

class _LocalVerifiedBadgeWidgetState extends State<LocalVerifiedBadgeWidget> {
  late LocalVerifiedBadgeModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LocalVerifiedBadgeModel());
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
        borderRadius: BorderRadius.circular(
            FlutterFlowTheme.of(context).designToken.radius.full),
        border: Border.all(
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
            FlutterFlowTheme.of(context).designToken.spacing.sm,
            FlutterFlowTheme.of(context).designToken.spacing.xs,
            FlutterFlowTheme.of(context).designToken.spacing.sm,
            FlutterFlowTheme.of(context).designToken.spacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_rounded,
              color: FlutterFlowTheme.of(context).primary,
              size: 14.0,
            ),
            Text(
              'VERIFIED KIN',
              style: FlutterFlowTheme.of(context).labelSmall.override(
                    font: GoogleFonts.playfairDisplay(
                      fontWeight: FontWeight.w800,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelSmall.fontStyle,
                    ),
                    color: FlutterFlowTheme.of(context).primary,
                    fontSize: 10.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w800,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelSmall.fontStyle,
                    lineHeight: 1.2,
                  ),
            ),
          ].divide(SizedBox(
              width: FlutterFlowTheme.of(context).designToken.spacing.xs)),
        ),
      ),
    );
  }
}
