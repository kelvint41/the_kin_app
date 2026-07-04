import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'date_item_model.dart';
export 'date_item_model.dart';

class DateItemWidget extends StatefulWidget {
  const DateItemWidget({
    super.key,
    bool? active,
    bool? disabled,
    String? day,
    String? date,
  })  : this.active = active ?? false,
        this.disabled = disabled ?? true,
        this.day = day ?? 'MON',
        this.date = date ?? '23';

  final bool active;
  final bool disabled;
  final String day;
  final String date;

  @override
  State<DateItemWidget> createState() => _DateItemWidgetState();
}

class _DateItemWidgetState extends State<DateItemWidget> {
  late DateItemModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DateItemModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: valueOrDefault<double>(
        valueOrDefault<bool>(
          widget!.disabled,
          true,
        )
            ? 0.4
            : 1.0,
        0.4,
      ),
      child: Container(
        width: 64.0,
        height: 80.0,
        decoration: BoxDecoration(
          color: valueOrDefault<Color>(
            valueOrDefault<bool>(
              widget!.active,
              false,
            )
                ? FlutterFlowTheme.of(context).primaryText
                : Color(0xFF242424),
            Color(0x00000000),
          ),
          borderRadius: BorderRadius.circular(14.0),
          shape: BoxShape.rectangle,
          border: Border.all(
            color: valueOrDefault<Color>(
              valueOrDefault<bool>(
                widget!.active,
                false,
              )
                  ? FlutterFlowTheme.of(context).primaryText
                  : Color(0xFF333333),
              Color(0x00000000),
            ),
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              valueOrDefault<String>(
                widget!.day,
                'MON',
              ),
              style: FlutterFlowTheme.of(context).labelSmall.override(
                    font: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelSmall.fontStyle,
                    ),
                    color: valueOrDefault<Color>(
                      valueOrDefault<bool>(
                        widget!.active,
                        false,
                      )
                          ? Color(0xFF121212)
                          : FlutterFlowTheme.of(context).secondary,
                      Color(0x00000000),
                    ),
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.bold,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelSmall.fontStyle,
                    lineHeight: 1.4,
                  ),
            ),
            Text(
              valueOrDefault<String>(
                widget!.date,
                '23',
              ),
              style: FlutterFlowTheme.of(context).titleMedium.override(
                    font: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontStyle:
                          FlutterFlowTheme.of(context).titleMedium.fontStyle,
                    ),
                    color: valueOrDefault<Color>(
                      valueOrDefault<bool>(
                        widget!.active,
                        false,
                      )
                          ? Color(0xFF121212)
                          : FlutterFlowTheme.of(context).primaryText,
                      Color(0x00000000),
                    ),
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.bold,
                    fontStyle:
                        FlutterFlowTheme.of(context).titleMedium.fontStyle,
                    lineHeight: 1.4,
                  ),
            ),
          ].divide(SizedBox(height: 4.0)),
        ),
      ),
    );
  }
}
