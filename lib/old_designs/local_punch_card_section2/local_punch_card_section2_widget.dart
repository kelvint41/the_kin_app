import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/old_designs/local_punch_slot_gold2/local_punch_slot_gold2_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'local_punch_card_section2_model.dart';
export 'local_punch_card_section2_model.dart';

class LocalPunchCardSection2Widget extends StatefulWidget {
  const LocalPunchCardSection2Widget({
    super.key,
    this.business_name,
    this.reward_text,
    this.completed,
    this.total,
  });

  final String? business_name;
  final String? reward_text;
  final double? completed;
  final double? total;

  @override
  State<LocalPunchCardSection2Widget> createState() =>
      _LocalPunchCardSection2WidgetState();
}

class _LocalPunchCardSection2WidgetState
    extends State<LocalPunchCardSection2Widget> {
  late LocalPunchCardSection2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LocalPunchCardSection2Model());
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
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      valueOrDefault<String>(
                        widget.business_name,
                        'The Southern Grind',
                      ),
                      style: FlutterFlowTheme.of(context).titleMedium.override(
                            font: GoogleFonts.playfairDisplay(
                              fontWeight: FontWeight.w600,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).primaryText,
                            fontSize: 17.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                            fontStyle: FlutterFlowTheme.of(context)
                                .titleMedium
                                .fontStyle,
                            lineHeight: 1.4,
                          ),
                    ),
                    Text(
                      valueOrDefault<String>(
                        widget.reward_text,
                        '10th Coffee is on the house',
                      ),
                      style: FlutterFlowTheme.of(context).labelSmall.override(
                            font: GoogleFonts.playfairDisplay(
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
                      height:
                          FlutterFlowTheme.of(context).designToken.spacing.xs)),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                        FlutterFlowTheme.of(context).designToken.radius.full),
                    border: Border.all(
                      width: 1.0,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                        FlutterFlowTheme.of(context).designToken.spacing.md,
                        FlutterFlowTheme.of(context).designToken.spacing.xs,
                        FlutterFlowTheme.of(context).designToken.spacing.md,
                        FlutterFlowTheme.of(context).designToken.spacing.xs),
                    child: Text(
                      '${widget.completed?.toString()} / ${widget.total?.toString()}',
                      style: FlutterFlowTheme.of(context).labelMedium.override(
                            font: GoogleFonts.playfairDisplay(
                              fontWeight: FontWeight.w600,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).primary,
                            fontSize: 12.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelMedium
                                .fontStyle,
                            lineHeight: 1.3,
                          ),
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: AlignmentDirectional(0.0, 0.0),
              child: Wrap(
                spacing: FlutterFlowTheme.of(context).designToken.spacing.md,
                runSpacing: FlutterFlowTheme.of(context).designToken.spacing.md,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.start,
                direction: Axis.horizontal,
                runAlignment: WrapAlignment.start,
                verticalDirection: VerticalDirection.down,
                clipBehavior: Clip.none,
                children: [
                  wrapWithModel(
                    model: _model.localPunchSlotGold2Model1,
                    updateCallback: () => safeSetState(() {}),
                    child: LocalPunchSlotGold2Widget(
                      completed: true,
                    ),
                  ),
                  wrapWithModel(
                    model: _model.localPunchSlotGold2Model2,
                    updateCallback: () => safeSetState(() {}),
                    child: LocalPunchSlotGold2Widget(
                      completed: true,
                    ),
                  ),
                  wrapWithModel(
                    model: _model.localPunchSlotGold2Model3,
                    updateCallback: () => safeSetState(() {}),
                    child: LocalPunchSlotGold2Widget(
                      completed: true,
                    ),
                  ),
                  wrapWithModel(
                    model: _model.localPunchSlotGold2Model4,
                    updateCallback: () => safeSetState(() {}),
                    child: LocalPunchSlotGold2Widget(
                      completed: true,
                    ),
                  ),
                  wrapWithModel(
                    model: _model.localPunchSlotGold2Model5,
                    updateCallback: () => safeSetState(() {}),
                    child: LocalPunchSlotGold2Widget(
                      completed: true,
                    ),
                  ),
                  wrapWithModel(
                    model: _model.localPunchSlotGold2Model6,
                    updateCallback: () => safeSetState(() {}),
                    child: LocalPunchSlotGold2Widget(
                      completed: true,
                    ),
                  ),
                  wrapWithModel(
                    model: _model.localPunchSlotGold2Model7,
                    updateCallback: () => safeSetState(() {}),
                    child: LocalPunchSlotGold2Widget(
                      completed: false,
                    ),
                  ),
                  wrapWithModel(
                    model: _model.localPunchSlotGold2Model8,
                    updateCallback: () => safeSetState(() {}),
                    child: LocalPunchSlotGold2Widget(
                      completed: false,
                    ),
                  ),
                  wrapWithModel(
                    model: _model.localPunchSlotGold2Model9,
                    updateCallback: () => safeSetState(() {}),
                    child: LocalPunchSlotGold2Widget(
                      completed: false,
                    ),
                  ),
                  wrapWithModel(
                    model: _model.localPunchSlotGold2Model10,
                    updateCallback: () => safeSetState(() {}),
                    child: LocalPunchSlotGold2Widget(
                      completed: false,
                    ),
                  ),
                ],
              ),
            ),
          ].divide(SizedBox(
              height: FlutterFlowTheme.of(context).designToken.spacing.md)),
        ),
      ),
    );
  }
}
