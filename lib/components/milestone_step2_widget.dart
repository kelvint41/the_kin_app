import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'milestone_step2_model.dart';
export 'milestone_step2_model.dart';

class MilestoneStep2Widget extends StatefulWidget {
  const MilestoneStep2Widget({
    super.key,
    bool? completed,
    bool? active,
    String? label,
  })  : this.completed = completed ?? true,
        this.active = active ?? false,
        this.label = label ?? 'Strategy';

  final bool completed;
  final bool active;
  final String label;

  @override
  State<MilestoneStep2Widget> createState() => _MilestoneStep2WidgetState();
}

class _MilestoneStep2WidgetState extends State<MilestoneStep2Widget> {
  late MilestoneStep2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MilestoneStep2Model());
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
                  widget!.completed,
                  true,
                )) {
                  return FlutterFlowTheme.of(context).primary;
                } else if (valueOrDefault<bool>(
                  widget!.active,
                  false,
                )) {
                  return FlutterFlowTheme.of(context).primary;
                } else {
                  return Color(0x00000000);
                }
              }(),
              FlutterFlowTheme.of(context).primary,
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
                      widget!.completed,
                      true,
                    )
                        ? true
                        : false,
                    true,
                  ))
                    Icon(
                      Icons.check_circle_rounded,
                      color: valueOrDefault<Color>(
                        () {
                          if (valueOrDefault<bool>(
                            widget!.active,
                            false,
                          )) {
                            return FlutterFlowTheme.of(context).primary;
                          } else if (valueOrDefault<bool>(
                            widget!.completed,
                            true,
                          )) {
                            return FlutterFlowTheme.of(context).primary;
                          } else {
                            return FlutterFlowTheme.of(context).secondaryText;
                          }
                        }(),
                        Color(0x00000000),
                      ),
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
                        widget!.active,
                        false,
                      )
                          ? FlutterFlowTheme.of(context).primaryText
                          : FlutterFlowTheme.of(context).secondaryText,
                      Color(0x00000000),
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
