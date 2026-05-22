import '/components/local_punch_slot_gold_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'local_punch_card_section_model.dart';
export 'local_punch_card_section_model.dart';

class LocalPunchCardSectionWidget extends StatefulWidget {
  const LocalPunchCardSectionWidget({
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
  State<LocalPunchCardSectionWidget> createState() =>
      _LocalPunchCardSectionWidgetState();
}

class _LocalPunchCardSectionWidgetState
    extends State<LocalPunchCardSectionWidget> {
  late LocalPunchCardSectionModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LocalPunchCardSectionModel());

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
                            font: GoogleFonts.plusJakartaSans(
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
                    model: _model.localPunchSlotGoldModel1,
                    updateCallback: () => safeSetState(() {}),
                    child: LocalPunchSlotGoldWidget(
                      completed: true,
                    ),
                  ),
                  wrapWithModel(
                    model: _model.localPunchSlotGoldModel2,
                    updateCallback: () => safeSetState(() {}),
                    child: LocalPunchSlotGoldWidget(
                      completed: true,
                    ),
                  ),
                  wrapWithModel(
                    model: _model.localPunchSlotGoldModel3,
                    updateCallback: () => safeSetState(() {}),
                    child: LocalPunchSlotGoldWidget(
                      completed: true,
                    ),
                  ),
                  wrapWithModel(
                    model: _model.localPunchSlotGoldModel4,
                    updateCallback: () => safeSetState(() {}),
                    child: LocalPunchSlotGoldWidget(
                      completed: true,
                    ),
                  ),
                  wrapWithModel(
                    model: _model.localPunchSlotGoldModel5,
                    updateCallback: () => safeSetState(() {}),
                    child: LocalPunchSlotGoldWidget(
                      completed: true,
                    ),
                  ),
                  wrapWithModel(
                    model: _model.localPunchSlotGoldModel6,
                    updateCallback: () => safeSetState(() {}),
                    child: LocalPunchSlotGoldWidget(
                      completed: true,
                    ),
                  ),
                  wrapWithModel(
                    model: _model.localPunchSlotGoldModel7,
                    updateCallback: () => safeSetState(() {}),
                    child: LocalPunchSlotGoldWidget(
                      completed: false,
                    ),
                  ),
                  wrapWithModel(
                    model: _model.localPunchSlotGoldModel8,
                    updateCallback: () => safeSetState(() {}),
                    child: LocalPunchSlotGoldWidget(
                      completed: false,
                    ),
                  ),
                  wrapWithModel(
                    model: _model.localPunchSlotGoldModel9,
                    updateCallback: () => safeSetState(() {}),
                    child: LocalPunchSlotGoldWidget(
                      completed: false,
                    ),
                  ),
                  wrapWithModel(
                    model: _model.localPunchSlotGoldModel10,
                    updateCallback: () => safeSetState(() {}),
                    child: LocalPunchSlotGoldWidget(
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
