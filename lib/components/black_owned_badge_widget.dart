import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'black_owned_badge_model.dart';
export 'black_owned_badge_model.dart';

class BlackOwnedBadgeWidget extends StatefulWidget {
  const BlackOwnedBadgeWidget({super.key});

  @override
  State<BlackOwnedBadgeWidget> createState() => _BlackOwnedBadgeWidgetState();
}

class _BlackOwnedBadgeWidgetState extends State<BlackOwnedBadgeWidget> {
  late BlackOwnedBadgeModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BlackOwnedBadgeModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
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
        color: FlutterFlowTheme.of(context).secondary,
        borderRadius: BorderRadius.circular(
            FlutterFlowTheme.of(context).designToken.radius.full),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(8.0, 4.0, 12.0, 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 20.0,
              height: 20.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primary,
                borderRadius: BorderRadius.circular(
                    FlutterFlowTheme.of(context).designToken.radius.full),
              ),
              alignment: AlignmentDirectional(0.0, 0.0),
              child: Icon(
                Icons.check_rounded,
                color: FlutterFlowTheme.of(context).primaryBackground,
                size: 12.0,
              ),
            ),
            Text(
              'Verified Black-Owned Business',
              style: FlutterFlowTheme.of(context).labelSmall.override(
                    font: GoogleFonts.playfairDisplay(
                      fontWeight: FontWeight.bold,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelSmall.fontStyle,
                    ),
                    color: FlutterFlowTheme.of(context).primary,
                    fontSize: 10.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.bold,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelSmall.fontStyle,
                    lineHeight: 1.2,
                  ),
            ),
          ].divide(SizedBox(
              width: FlutterFlowTheme.of(context).designToken.spacing.sm)),
        ),
      ),
    );
  }
}
