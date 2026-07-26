import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ticker_item4_model.dart';
export 'ticker_item4_model.dart';

class TickerItem4Widget extends StatefulWidget {
  const TickerItem4Widget({
    super.key,
    String? ticker,
    String? score,
    bool? up,
  })  : this.ticker = ticker ?? 'ALMO',
        this.score = score ?? '1240',
        this.up = up ?? true;

  final String ticker;
  final String score;
  final bool up;

  @override
  State<TickerItem4Widget> createState() => _TickerItem4WidgetState();
}

class _TickerItem4WidgetState extends State<TickerItem4Widget> {
  late TickerItem4Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TickerItem4Model());
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          valueOrDefault<String>(
            widget.ticker,
            'ALMO',
          ),
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
                color: FlutterFlowTheme.of(context).primaryText,
                letterSpacing: 0.0,
                fontWeight: FontWeight.bold,
                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                lineHeight: 1.4,
              ),
        ),
        Text(
          valueOrDefault<String>(
            '${widget.score}',
            '1240',
          ),
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.plusJakartaSans(
                  fontWeight:
                      FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
                color: valueOrDefault<Color>(
                  valueOrDefault<bool>(
                    widget.up,
                    true,
                  )
                      ? Color(0xFF10B981)
                      : Color(0xFFEF4444),
                  Color(0xFF10B981),
                ),
                letterSpacing: 0.0,
                fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                lineHeight: 1.4,
              ),
        ),
        Container(
          width: 14.0,
          height: 14.0,
          child: Stack(
            alignment: AlignmentDirectional(0.0, 0.0),
            children: [
              if (valueOrDefault<bool>(
                valueOrDefault<bool>(
                  widget.up,
                  true,
                )
                    ? true
                    : false,
                true,
              ))
                Icon(
                  Icons.change_history_rounded,
                  color: valueOrDefault<Color>(
                    valueOrDefault<bool>(
                      widget.up,
                      true,
                    )
                        ? Color(0xFF10B981)
                        : Color(0xFFEF4444),
                    Color(0xFF10B981),
                  ),
                  size: 14.0,
                ),
              if (valueOrDefault<bool>(
                valueOrDefault<bool>(
                  widget.up,
                  true,
                )
                    ? false
                    : true,
                false,
              ))
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: valueOrDefault<Color>(
                    valueOrDefault<bool>(
                      widget.up,
                      true,
                    )
                        ? Color(0xFF10B981)
                        : Color(0xFFEF4444),
                    Color(0xFF10B981),
                  ),
                  size: 14.0,
                ),
            ],
          ),
        ),
        Text(
          '  •  ',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.plusJakartaSans(
                  fontWeight:
                      FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
                color: Color(0xFF333333),
                letterSpacing: 0.0,
                fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                lineHeight: 1.4,
              ),
        ),
      ].divide(SizedBox(width: 4.0)),
    );
  }
}
