import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/old_designs/punch_slot_loyalty/punch_slot_loyalty_widget.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'local_punch_card_model.dart';
export 'local_punch_card_model.dart';

class LocalPunchCardWidget extends StatefulWidget {
  const LocalPunchCardWidget({
    super.key,
    this.business_name,
    this.completed,
    this.total,
    this.reward_text,
  });

  final String? business_name;
  final double? completed;
  final double? total;
  final String? reward_text;

  @override
  State<LocalPunchCardWidget> createState() => _LocalPunchCardWidgetState();
}

class _LocalPunchCardWidgetState extends State<LocalPunchCardWidget> {
  late LocalPunchCardModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LocalPunchCardModel());
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
                    widget!.business_name,
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
                        fontStyle:
                            FlutterFlowTheme.of(context).titleMedium.fontStyle,
                        lineHeight: 1.4,
                      ),
                ),
                Text(
                  'Digital Punch Card',
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        font: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.normal,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodySmall.fontStyle,
                        ),
                        color: FlutterFlowTheme.of(context).secondaryText,
                        fontSize: 12.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.normal,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodySmall.fontStyle,
                        lineHeight: 1.4,
                      ),
                ),
              ].divide(SizedBox(
                  height: FlutterFlowTheme.of(context).designToken.spacing.xs)),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                    FlutterFlowTheme.of(context).designToken.radius.md),
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                    FlutterFlowTheme.of(context).designToken.spacing.sm,
                    FlutterFlowTheme.of(context).designToken.spacing.xs,
                    FlutterFlowTheme.of(context).designToken.spacing.sm,
                    FlutterFlowTheme.of(context).designToken.spacing.xs),
                child: Text(
                  '${widget!.completed?.toString()} / ${widget!.total?.toString()}',
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                        font: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontStyle: FlutterFlowTheme.of(context)
                              .titleMedium
                              .fontStyle,
                        ),
                        color: FlutterFlowTheme.of(context).primary,
                        fontSize: 17.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w800,
                        fontStyle:
                            FlutterFlowTheme.of(context).titleMedium.fontStyle,
                        lineHeight: 1.4,
                      ),
                ),
              ),
            ),
          ],
        ),
        Container(
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
            padding: EdgeInsets.all(
                FlutterFlowTheme.of(context).designToken.spacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        wrapWithModel(
                          model: _model.punchSlotLoyaltyModel1,
                          updateCallback: () => safeSetState(() {}),
                          child: PunchSlotLoyaltyWidget(
                            completed: true,
                          ),
                        ),
                        wrapWithModel(
                          model: _model.punchSlotLoyaltyModel2,
                          updateCallback: () => safeSetState(() {}),
                          child: PunchSlotLoyaltyWidget(
                            completed: true,
                          ),
                        ),
                        wrapWithModel(
                          model: _model.punchSlotLoyaltyModel3,
                          updateCallback: () => safeSetState(() {}),
                          child: PunchSlotLoyaltyWidget(
                            completed: true,
                          ),
                        ),
                        wrapWithModel(
                          model: _model.punchSlotLoyaltyModel4,
                          updateCallback: () => safeSetState(() {}),
                          child: PunchSlotLoyaltyWidget(
                            completed: true,
                          ),
                        ),
                        wrapWithModel(
                          model: _model.punchSlotLoyaltyModel5,
                          updateCallback: () => safeSetState(() {}),
                          child: PunchSlotLoyaltyWidget(
                            completed: true,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        wrapWithModel(
                          model: _model.punchSlotLoyaltyModel6,
                          updateCallback: () => safeSetState(() {}),
                          child: PunchSlotLoyaltyWidget(
                            completed: true,
                          ),
                        ),
                        wrapWithModel(
                          model: _model.punchSlotLoyaltyModel7,
                          updateCallback: () => safeSetState(() {}),
                          child: PunchSlotLoyaltyWidget(
                            completed: false,
                          ),
                        ),
                        wrapWithModel(
                          model: _model.punchSlotLoyaltyModel8,
                          updateCallback: () => safeSetState(() {}),
                          child: PunchSlotLoyaltyWidget(
                            completed: false,
                          ),
                        ),
                        wrapWithModel(
                          model: _model.punchSlotLoyaltyModel9,
                          updateCallback: () => safeSetState(() {}),
                          child: PunchSlotLoyaltyWidget(
                            completed: false,
                          ),
                        ),
                        wrapWithModel(
                          model: _model.punchSlotLoyaltyModel10,
                          updateCallback: () => safeSetState(() {}),
                          child: PunchSlotLoyaltyWidget(
                            completed: false,
                          ),
                        ),
                      ],
                    ),
                  ].divide(SizedBox(
                      height:
                          FlutterFlowTheme.of(context).designToken.spacing.md)),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                        FlutterFlowTheme.of(context).designToken.radius.md),
                    border: Border.all(
                      width: 1.0,
                    ),
                  ),
                  child: Align(
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: Padding(
                      padding: EdgeInsets.all(
                          FlutterFlowTheme.of(context).designToken.spacing.md),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: FlutterFlowTheme.of(context).primary,
                            size: 18.0,
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              valueOrDefault<String>(
                                widget!.reward_text,
                                '4 more visits until your free signature latte!',
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                    lineHeight: 1.5,
                                  ),
                            ),
                          ),
                        ].divide(SizedBox(
                            width: FlutterFlowTheme.of(context)
                                .designToken
                                .spacing
                                .sm)),
                      ),
                    ),
                  ),
                ),
              ].divide(SizedBox(
                  height: FlutterFlowTheme.of(context).designToken.spacing.lg)),
            ),
          ),
        ),
      ].divide(SizedBox(
          height: FlutterFlowTheme.of(context).designToken.spacing.md)),
    );
  }
}
