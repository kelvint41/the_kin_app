import '/components/kindex_trend_indicator.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'metric_card3_model.dart';
export 'metric_card3_model.dart';

class MetricCard3Widget extends StatefulWidget {
  const MetricCard3Widget({
    super.key,
    this.icon,
    Color? tint,
    String? label,
    String? value,
    this.isTrendingUp,
    this.showTrend = false,
  })  : this.tint = tint ?? const Color(0xFFFF8C00),
        this.label = label ?? '7-Day Support Streak',
        this.value = value ?? '14 🔥';

  final Widget? icon;
  final Color tint;
  final String label;
  final String value;

  /// Direction beside [value]: true up, false down, null not known.
  final bool? isTrendingUp;

  /// Whether this metric has a direction at all.
  ///
  /// Opt-in, because this card also renders Support Streak and Milestones
  /// Unlocked, which are counts with no trend concept - a marker on those
  /// would be meaningless rather than merely unknown. Only the score cards
  /// set it.
  ///
  /// The distinction this preserves: a card that opts out shows nothing,
  /// while a card that opts in always shows something, falling back to the
  /// flat marker when [isTrendingUp] is null. Previously null rendered
  /// nothing, which made "we don't know yet" indistinguishable from "this
  /// number doesn't move" - and since no customer has a KindexScores row
  /// with a direction, that was every card, every time.
  final bool showTrend;

  @override
  State<MetricCard3Widget> createState() => _MetricCard3WidgetState();
}

class _MetricCard3WidgetState extends State<MetricCard3Widget> {
  late MetricCard3Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MetricCard3Model());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180.0,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(24.0),
        shape: BoxShape.rectangle,
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  widget!.icon!,
                  // maxLines and ellipsis below only take effect once the
                  // Text has a bounded width. Unwrapped in a
                  // MainAxisSize.min Row inside a fixed-width card, it took
                  // its natural width and overflowed the card instead.
                  Flexible(
                    child: Text(
                      valueOrDefault<String>(
                        widget!.label,
                        '7-Day Support Streak',
                      ),
                      maxLines: 1,
                      style: FlutterFlowTheme.of(context).labelSmall.override(
                            font: GoogleFonts.plusJakartaSans(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).secondaryText,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontStyle,
                            lineHeight: 1.4,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ].divide(SizedBox(width: 4.0)),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      valueOrDefault<String>(
                        widget!.value,
                        '14 🔥',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FlutterFlowTheme.of(context).titleLarge.override(
                            font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .titleLarge
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).primaryText,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .titleLarge
                                .fontStyle,
                            lineHeight: 1.4,
                          ),
                    ),
                  ),
                  // Was gated on `isTrendingUp != null`, so a customer with
                  // no KindexScores row saw a bare number with no trend
                  // marker at all - which reads as "this score has no
                  // trend" rather than "we don't know yet". The shared
                  // indicator renders a flat marker for that case, and is
                  // the same widget the business profile uses so both
                  // sides of the app say it the same way.
                  if (widget!.showTrend)
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(6.0, 0.0, 0.0, 0.0),
                      child: KindexTrendIndicator.fromTrend(
                        isTrendingUp: widget!.isTrendingUp,
                      ),
                    ),
                ],
              ),
            ].divide(SizedBox(height: 16.0)),
          ),
        ),
      ),
    );
  }
}
