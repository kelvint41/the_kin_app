import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'feature_bullet_model.dart';
export 'feature_bullet_model.dart';

class FeatureBulletWidget extends StatefulWidget {
  const FeatureBulletWidget({
    super.key,
    this.label,
  });

  final String? label;

  @override
  State<FeatureBulletWidget> createState() => _FeatureBulletWidgetState();
}

class _FeatureBulletWidgetState extends State<FeatureBulletWidget> {
  late FeatureBulletModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FeatureBulletModel());
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
          0.0, 0.0, 0.0, FlutterFlowTheme.of(context).designToken.spacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: FlutterFlowTheme.of(context).primary,
            size: 16.0,
          ),
          Expanded(
            flex: 1,
            child: Text(
              valueOrDefault<String>(
                widget!.label,
                'Verified Gold Status Badge',
              ),
              maxLines: 2,
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    font: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.normal,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodySmall.fontStyle,
                    ),
                    color: FlutterFlowTheme.of(context).primaryText,
                    fontSize: 12.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.normal,
                    fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                    lineHeight: 1.4,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ].divide(SizedBox(
            width: FlutterFlowTheme.of(context).designToken.spacing.sm)),
      ),
    );
  }
}
