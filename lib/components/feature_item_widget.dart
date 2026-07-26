import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'feature_item_model.dart';
export 'feature_item_model.dart';

class FeatureItemWidget extends StatefulWidget {
  const FeatureItemWidget({
    super.key,
    Color? iconColor,
    String? benefit,
  })  : this.iconColor = iconColor ?? const Color(0x00000000),
        this.benefit = benefit ?? '';

  final Color iconColor;
  final String benefit;

  @override
  State<FeatureItemWidget> createState() => _FeatureItemWidgetState();
}

class _FeatureItemWidgetState extends State<FeatureItemWidget> {
  late FeatureItemModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FeatureItemModel());
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_rounded,
          color: widget.iconColor,
          size: 18.0,
        ),
        Expanded(
          flex: 1,
          child: Text(
            widget.benefit,
            maxLines: 2,
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  font: GoogleFonts.playfairDisplay(
                    fontWeight:
                        FlutterFlowTheme.of(context).bodySmall.fontWeight,
                    fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                  ),
                  color: FlutterFlowTheme.of(context).primaryText,
                  letterSpacing: 0.0,
                  fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                  lineHeight: 1.4,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ].divide(SizedBox(width: 16.0)),
    );
  }
}
