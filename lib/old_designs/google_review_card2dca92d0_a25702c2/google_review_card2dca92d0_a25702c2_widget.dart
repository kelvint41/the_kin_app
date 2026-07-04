import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'google_review_card2dca92d0_a25702c2_model.dart';
export 'google_review_card2dca92d0_a25702c2_model.dart';

class GoogleReviewCard2dca92d0A25702c2Widget extends StatefulWidget {
  const GoogleReviewCard2dca92d0A25702c2Widget({
    super.key,
    this.user_name,
    this.review_text,
  });

  final String? user_name;
  final String? review_text;

  @override
  State<GoogleReviewCard2dca92d0A25702c2Widget> createState() =>
      _GoogleReviewCard2dca92d0A25702c2WidgetState();
}

class _GoogleReviewCard2dca92d0A25702c2WidgetState
    extends State<GoogleReviewCard2dca92d0A25702c2Widget> {
  late GoogleReviewCard2dca92d0A25702c2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model =
        createModel(context, () => GoogleReviewCard2dca92d0A25702c2Model());
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
          0.0, 0.0, FlutterFlowTheme.of(context).designToken.spacing.md, 0.0),
      child: Container(
        width: 300.0,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(
              FlutterFlowTheme.of(context).designToken.radius.lg),
          border: Border.all(
            color: Color(0xFF333333),
            width: 1.0,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(
              FlutterFlowTheme.of(context).designToken.spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.g_mobiledata,
                        color: FlutterFlowTheme.of(context).primaryText,
                        size: 16.0,
                      ),
                      Text(
                        'Google Review',
                        style: FlutterFlowTheme.of(context).labelSmall.override(
                              font: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .labelSmall
                                    .fontStyle,
                              ),
                              color: FlutterFlowTheme.of(context).secondaryText,
                              fontSize: 10.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .fontStyle,
                              lineHeight: 1.2,
                            ),
                      ),
                    ].divide(SizedBox(
                        width: FlutterFlowTheme.of(context)
                            .designToken
                            .spacing
                            .xs)),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: FlutterFlowTheme.of(context).primary,
                        size: 14.0,
                      ),
                      Icon(
                        Icons.star_rounded,
                        color: FlutterFlowTheme.of(context).primary,
                        size: 14.0,
                      ),
                      Icon(
                        Icons.star_rounded,
                        color: FlutterFlowTheme.of(context).primary,
                        size: 14.0,
                      ),
                      Icon(
                        Icons.star_rounded,
                        color: FlutterFlowTheme.of(context).primary,
                        size: 14.0,
                      ),
                      Icon(
                        Icons.star_rounded,
                        color: FlutterFlowTheme.of(context).primary,
                        size: 14.0,
                      ),
                    ].divide(SizedBox(width: 2.0)),
                  ),
                ],
              ),
              Text(
                valueOrDefault<String>(
                  widget!.user_name,
                  'James Chen',
                ),
                style: FlutterFlowTheme.of(context).labelLarge.override(
                      font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontStyle:
                            FlutterFlowTheme.of(context).labelLarge.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).primaryText,
                      fontSize: 14.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelLarge.fontStyle,
                      lineHeight: 1.3,
                    ),
              ),
              Text(
                valueOrDefault<String>(
                  widget!.review_text,
                  'Absolutely stunning collection. The personal styling session was top-tier. Highly recommend for luxury finds in SA.',
                ),
                maxLines: 3,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.normal,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).secondaryText,
                      fontSize: 14.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.normal,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      lineHeight: 1.5,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ].divide(SizedBox(
                height: FlutterFlowTheme.of(context).designToken.spacing.sm)),
          ),
        ),
      ),
    );
  }
}
