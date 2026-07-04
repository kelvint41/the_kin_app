import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'ticker_row_model.dart';
export 'ticker_row_model.dart';

class TickerRowWidget extends StatefulWidget {
  const TickerRowWidget({
    super.key,
    String? symbol,
    String? score,
    bool? isUp,
    Color? trendColor,
    String? trend,
  })  : this.symbol = symbol ?? 'JOYX',
        this.score = score ?? '545',
        this.isUp = isUp ?? true,
        this.trendColor = trendColor ?? const Color(0xFF10B981),
        this.trend = trend ?? '+1.2%';

  final String symbol;
  final String score;
  final bool isUp;
  final Color trendColor;
  final String trend;

  @override
  State<TickerRowWidget> createState() => _TickerRowWidgetState();
}

class _TickerRowWidgetState extends State<TickerRowWidget> {
  late TickerRowModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TickerRowModel());
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
        shape: BoxShape.rectangle,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(16.0, 24.0, 16.0, 24.0),
            child: Container(
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 80.0,
                    child: Text(
                      valueOrDefault<String>(
                        widget!.symbol,
                        'JOYX',
                      ),
                      style: FlutterFlowTheme.of(context).titleMedium.override(
                            font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).primaryText,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .titleMedium
                                .fontStyle,
                            lineHeight: 1.4,
                          ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      valueOrDefault<String>(
                        widget!.score,
                        '545',
                      ),
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(context).titleMedium.override(
                            font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w500,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).primaryText,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w500,
                            fontStyle: FlutterFlowTheme.of(context)
                                .titleMedium
                                .fontStyle,
                            lineHeight: 1.4,
                          ),
                    ),
                  ),
                  Container(
                    width: 80.0,
                    alignment: AlignmentDirectional(1.0, -1.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 18.0,
                          height: 18.0,
                          child: Stack(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            children: [
                              if (valueOrDefault<bool>(
                                valueOrDefault<bool>(
                                  widget!.isUp,
                                  true,
                                )
                                    ? true
                                    : false,
                                true,
                              ))
                                Icon(
                                  Icons.trending_up_rounded,
                                  color: valueOrDefault<Color>(
                                    widget!.trendColor,
                                    Color(0xFF10B981),
                                  ),
                                  size: 18.0,
                                ),
                              if (valueOrDefault<bool>(
                                valueOrDefault<bool>(
                                  widget!.isUp,
                                  true,
                                )
                                    ? false
                                    : true,
                                false,
                              ))
                                Icon(
                                  Icons.trending_down_rounded,
                                  color: valueOrDefault<Color>(
                                    widget!.trendColor,
                                    Color(0xFF10B981),
                                  ),
                                  size: 18.0,
                                ),
                            ],
                          ),
                        ),
                        Text(
                          valueOrDefault<String>(
                            widget!.trend,
                            '+1.2%',
                          ),
                          style:
                              FlutterFlowTheme.of(context).labelMedium.override(
                                    font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                    color: valueOrDefault<Color>(
                                      widget!.trendColor,
                                      Color(0xFF10B981),
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                    lineHeight: 1.4,
                                  ),
                        ),
                      ].divide(SizedBox(width: 4.0)),
                    ),
                  ),
                ].divide(SizedBox(width: 16.0)),
              ),
            ),
          ),
          Container(
            height: 1.0,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).alternate,
              shape: BoxShape.rectangle,
            ),
          ),
        ],
      ),
    );
  }
}
