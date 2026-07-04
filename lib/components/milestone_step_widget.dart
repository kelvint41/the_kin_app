import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'milestone_step_model.dart';
export 'milestone_step_model.dart';

class MilestoneStepWidget extends StatefulWidget {
  const MilestoneStepWidget({
    super.key,
    bool? isCompleted,
    bool? isActive,
    String? label,
  })  : this.isCompleted = isCompleted ?? true,
        this.isActive = isActive ?? false,
        this.label = label ?? 'Strategy';

  final bool isCompleted;
  final bool isActive;
  final String label;

  @override
  State<MilestoneStepWidget> createState() => _MilestoneStepWidgetState();
}

class _MilestoneStepWidgetState extends State<MilestoneStepWidget> {
  late MilestoneStepModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MilestoneStepModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 4.0,
          decoration: BoxDecoration(
            color: valueOrDefault<Color>(
              () {
                if (valueOrDefault<bool>(
                  widget!.isCompleted,
                  true,
                )) {
                  return FlutterFlowTheme.of(context).tertiary;
                } else if (valueOrDefault<bool>(
                  widget!.isActive,
                  false,
                )) {
                  return FlutterFlowTheme.of(context).tertiary;
                } else {
                  return Color(0x00000000);
                }
              }(),
              FlutterFlowTheme.of(context).tertiary,
            ),
            borderRadius: BorderRadius.circular(9999.0),
            shape: BoxShape.rectangle,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 14.0,
              height: 14.0,
              child: Stack(
                alignment: AlignmentDirectional(0.0, 0.0),
                children: [
                  if (valueOrDefault<bool>(
                    valueOrDefault<bool>(
                      widget!.isCompleted,
                      true,
                    )
                        ? true
                        : false,
                    true,
                  ))
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14.0,
                    ),
                ],
              ),
            ),
            Text(
              valueOrDefault<String>(
                widget!.label,
                'Strategy',
              ),
              style: FlutterFlowTheme.of(context).labelSmall.override(
                    font: GoogleFonts.plusJakartaSans(
                      fontWeight:
                          FlutterFlowTheme.of(context).labelSmall.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelSmall.fontStyle,
                    ),
                    color: valueOrDefault<Color>(
                      valueOrDefault<bool>(
                        widget!.isActive,
                        false,
                      )
                          ? FlutterFlowTheme.of(context).primaryText
                          : FlutterFlowTheme.of(context).secondaryText,
                      FlutterFlowTheme.of(context).secondaryText,
                    ),
                    letterSpacing: 0.0,
                    fontWeight:
                        FlutterFlowTheme.of(context).labelSmall.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelSmall.fontStyle,
                    lineHeight: 1.4,
                  ),
            ),
          ].divide(SizedBox(width: 4.0)),
        ),
      ].divide(SizedBox(height: 4.0)),
    );
  }
}
