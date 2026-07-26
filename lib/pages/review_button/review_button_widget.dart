import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'review_button_model.dart';
export 'review_button_model.dart';

class ReviewButtonWidget extends StatefulWidget {
  const ReviewButtonWidget({super.key});

  @override
  State<ReviewButtonWidget> createState() => _ReviewButtonWidgetState();
}

class _ReviewButtonWidgetState extends State<ReviewButtonWidget> {
  late ReviewButtonModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ReviewButtonModel());
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
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(
            FlutterFlowTheme.of(context).designToken.radius.sm),
      ),
      child: Align(
        alignment: AlignmentDirectional(0.0, 0.0),
        child: Stack(
          alignment: AlignmentDirectional(0.0, 0.0),
          children: [
            Container(
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                    FlutterFlowTheme.of(context).designToken.spacing.md,
                    FlutterFlowTheme.of(context).designToken.spacing.xs,
                    FlutterFlowTheme.of(context).designToken.spacing.md,
                    FlutterFlowTheme.of(context).designToken.spacing.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: FlutterFlowTheme.of(context).primaryText,
                      size: 16.0,
                    ),
                    Container(
                      width: 0.0,
                      height: 0.0,
                    ),
                  ].divide(SizedBox(width: 8.0)),
                ),
              ),
            ),
            Container(
              width: 0.0,
              height: 0.0,
            ),
            Text(
              'Submit Review',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.plusJakartaSans(
                      fontWeight:
                          FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
                    letterSpacing: 0.0,
                    fontWeight:
                        FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
