import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'tracking_step_model.dart';
export 'tracking_step_model.dart';

class TrackingStepWidget extends StatefulWidget {
  const TrackingStepWidget({
    super.key,
    bool? isActive,
    bool? isLast,
    String? title,
    String? subtitle,
  })  : this.isActive = isActive ?? true,
        this.isLast = isLast ?? false,
        this.title = title ?? 'Order Confirmed',
        this.subtitle = subtitle ?? 'Today, 11:15 AM';

  final bool isActive;
  final bool isLast;
  final String title;
  final String subtitle;

  @override
  State<TrackingStepWidget> createState() => _TrackingStepWidgetState();
}

class _TrackingStepWidgetState extends State<TrackingStepWidget> {
  late TrackingStepModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TrackingStepModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 12.0,
              height: 12.0,
              decoration: BoxDecoration(
                color: valueOrDefault<Color>(
                  valueOrDefault<bool>(
                    widget!.isActive,
                    true,
                  )
                      ? FlutterFlowTheme.of(context).primaryText
                      : Color(0xFF333333),
                  FlutterFlowTheme.of(context).primaryText,
                ),
                borderRadius: BorderRadius.circular(9999.0),
                shape: BoxShape.rectangle,
                border: Border.all(
                  color: valueOrDefault<Color>(
                    valueOrDefault<bool>(
                      widget!.isActive,
                      true,
                    )
                        ? FlutterFlowTheme.of(context).primaryText
                        : Color(0xFF333333),
                    FlutterFlowTheme.of(context).primaryText,
                  ),
                  width: 2.0,
                ),
              ),
            ),
            if (valueOrDefault<bool>(
              valueOrDefault<bool>(
                widget!.isLast,
                false,
              )
                  ? false
                  : true,
              false,
            ))
              Container(
                width: 2.0,
                height: 40.0,
                decoration: BoxDecoration(
                  color: valueOrDefault<Color>(
                    valueOrDefault<bool>(
                      widget!.isActive,
                      true,
                    )
                        ? FlutterFlowTheme.of(context).primaryText
                        : Color(0xFF333333),
                    FlutterFlowTheme.of(context).primaryText,
                  ),
                  shape: BoxShape.rectangle,
                ),
              ),
          ],
        ),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                valueOrDefault<String>(
                  widget!.title,
                  'Order Confirmed',
                ),
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                      color: valueOrDefault<Color>(
                        valueOrDefault<bool>(
                          widget!.isActive,
                          true,
                        )
                            ? FlutterFlowTheme.of(context).primaryText
                            : FlutterFlowTheme.of(context).primaryText,
                        FlutterFlowTheme.of(context).primaryText,
                      ),
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.bold,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      lineHeight: 1.4,
                    ),
              ),
              Text(
                valueOrDefault<String>(
                  widget!.subtitle,
                  'Today, 11:15 AM',
                ),
                style: FlutterFlowTheme.of(context).labelSmall.override(
                      font: GoogleFonts.plusJakartaSans(
                        fontWeight:
                            FlutterFlowTheme.of(context).labelSmall.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).labelSmall.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).secondary,
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).labelSmall.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelSmall.fontStyle,
                      lineHeight: 1.4,
                    ),
              ),
            ].divide(SizedBox(height: 4.0)),
          ),
        ),
      ].divide(SizedBox(width: 16.0)),
    );
  }
}
