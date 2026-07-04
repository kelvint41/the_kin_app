import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'gold_map_pin_model.dart';
export 'gold_map_pin_model.dart';

class GoldMapPinWidget extends StatefulWidget {
  const GoldMapPinWidget({super.key});

  @override
  State<GoldMapPinWidget> createState() => _GoldMapPinWidgetState();
}

class _GoldMapPinWidgetState extends State<GoldMapPinWidget> {
  late GoldMapPinModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => GoldMapPinModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional(0.0, 0.0),
      children: [
        ClipRect(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: 6.0,
              sigmaY: 6.0,
            ),
            child: Container(
              width: 42.0,
              height: 42.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                    FlutterFlowTheme.of(context).designToken.radius.full),
              ),
            ),
          ),
        ),
        Container(
          width: 32.0,
          height: 32.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
                FlutterFlowTheme.of(context).designToken.radius.full),
            border: Border.all(
              width: 2.0,
            ),
          ),
        ),
        Container(
          width: 24.0,
          height: 24.0,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primary,
            borderRadius: BorderRadius.circular(
                FlutterFlowTheme.of(context).designToken.radius.full),
          ),
          alignment: AlignmentDirectional(0.0, 0.0),
          child: Icon(
            Icons.location_on_rounded,
            color: FlutterFlowTheme.of(context).primaryBackground,
            size: 14.0,
          ),
        ),
      ],
    );
  }
}
