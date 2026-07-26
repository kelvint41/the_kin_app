import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'podium_spot_model.dart';
export 'podium_spot_model.dart';

class PodiumSpotWidget extends StatefulWidget {
  const PodiumSpotWidget({
    super.key,
    double? size,
    Color? accent,
    String? name,
    this.icon,
    this.score,
  })  : this.size = size ?? 70.0,
        this.accent = accent ?? const Color(0xFFC0C0C0),
        this.name = name ?? 'Heritage Coffee';

  final double size;
  final Color accent;
  final String name;
  final Widget? icon;
  final double? score;

  @override
  State<PodiumSpotWidget> createState() => _PodiumSpotWidgetState();
}

class _PodiumSpotWidgetState extends State<PodiumSpotWidget> {
  late PodiumSpotModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PodiumSpotModel());
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
        Stack(
          alignment: AlignmentDirectional(0.0, 0.0),
          children: [
            Container(
              width: valueOrDefault<double>(
                widget.size,
                70.0,
              ),
              height: valueOrDefault<double>(
                widget.size,
                70.0,
              ),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                borderRadius: BorderRadius.circular(9999.0),
                shape: BoxShape.rectangle,
              ),
              child: Padding(
                padding: EdgeInsets.all(4.0),
                child: Container(
                  child: Container(
                    width: 40.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      shape: BoxShape.circle,
                    ),
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: Text(
                      valueOrDefault<String>(
                        widget.name,
                        'Heritage Coffee',
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: FlutterFlowTheme.of(context).labelMedium.override(
                            font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).primaryText,
                            fontSize: 15.2,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelMedium
                                .fontStyle,
                            lineHeight: 1.4,
                          ),
                      overflow: TextOverflow.clip,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional(1.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: valueOrDefault<Color>(
                    widget.accent,
                    Color(0xFFC0C0C0),
                  ),
                  borderRadius: BorderRadius.circular(9999.0),
                  shape: BoxShape.rectangle,
                ),
                child: Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Container(
                    child: widget.icon!,
                  ),
                ),
              ),
            ),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              valueOrDefault<String>(
                widget.name,
                'Heritage Coffee',
              ),
              maxLines: 1,
              style: FlutterFlowTheme.of(context).titleSmall.override(
                    font: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontStyle:
                          FlutterFlowTheme.of(context).titleSmall.fontStyle,
                    ),
                    color: FlutterFlowTheme.of(context).primaryText,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.bold,
                    fontStyle:
                        FlutterFlowTheme.of(context).titleSmall.fontStyle,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
            Container(
              decoration: BoxDecoration(
                color: valueOrDefault<Color>(
                  widget.accent,
                  Color(0xFFC0C0C0),
                ),
                shape: BoxShape.rectangle,
              ),
              child: Text(
                valueOrDefault<String>(
                  widget.score?.toString(),
                  '982',
                ),
                style: FlutterFlowTheme.of(context).labelLarge.override(
                      font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontStyle:
                            FlutterFlowTheme.of(context).labelLarge.fontStyle,
                      ),
                      color: valueOrDefault<Color>(
                        widget.accent,
                        Color(0xFFC0C0C0),
                      ),
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.bold,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelLarge.fontStyle,
                      lineHeight: 1.4,
                    ),
              ),
            ),
          ].divide(SizedBox(height: 4.0)),
        ),
      ].divide(SizedBox(height: 8.0)),
    );
  }
}
