import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'cinematic_reel_model.dart';
export 'cinematic_reel_model.dart';

class CinematicReelWidget extends StatefulWidget {
  const CinematicReelWidget({super.key});

  @override
  State<CinematicReelWidget> createState() => _CinematicReelWidgetState();
}

class _CinematicReelWidgetState extends State<CinematicReelWidget> {
  late CinematicReelModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CinematicReelModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CachedNetworkImage(
          fadeInDuration: Duration(milliseconds: 0),
          fadeOutDuration: Duration(milliseconds: 0),
          imageUrl:
              'https://dimg.dreamflow.cloud/v1/image/cinematic%20montage%20of%20luxury%20black-owned%20boutique%20interior%2C%20modern%20cafe%20with%20espresso%20machine%2C%20professional%20tech%20office%2C%20and%20vibrant%20community%20market%2C%20high%20contrast%2C%20golden%20hour%20lighting',
          fit: BoxFit.cover,
        ),
        Container(
          decoration: BoxDecoration(),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                FlutterFlowTheme.of(context).primaryBackground,
                FlutterFlowTheme.of(context).secondaryBackground
              ],
              stops: [0.0, 1.0],
              begin: AlignmentDirectional(0.94, 1.0),
              end: AlignmentDirectional(-0.94, -1.0),
            ),
          ),
        ),
      ],
    );
  }
}
