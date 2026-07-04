import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'pulsing_logo_marker_model.dart';
export 'pulsing_logo_marker_model.dart';

class PulsingLogoMarkerWidget extends StatefulWidget {
  const PulsingLogoMarkerWidget({
    super.key,
    this.logo_desc,
  });

  final String? logo_desc;

  @override
  State<PulsingLogoMarkerWidget> createState() =>
      _PulsingLogoMarkerWidgetState();
}

class _PulsingLogoMarkerWidgetState extends State<PulsingLogoMarkerWidget> {
  late PulsingLogoMarkerModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PulsingLogoMarkerModel());
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
        Opacity(
          opacity: 0.4,
          child: Container(
            width: 64.0,
            height: 64.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                  FlutterFlowTheme.of(context).designToken.radius.full),
              border: Border.all(
                width: 2.0,
              ),
            ),
          ),
        ),
        Opacity(
          opacity: 0.7,
          child: Container(
            width: 54.0,
            height: 54.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                  FlutterFlowTheme.of(context).designToken.radius.full),
              border: Border.all(
                width: 1.5,
              ),
            ),
          ),
        ),
        Container(
          width: 44.0,
          height: 54.0,
          child: Align(
            alignment: AlignmentDirectional(0.0, 0.0),
            child: Stack(
              alignment: AlignmentDirectional(0.0, 0.0),
              children: [
                Transform.rotate(
                  angle: 45.0 * (math.pi / 180),
                  child: Align(
                    alignment: AlignmentDirectional(0.0, 1.0),
                    child: Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 6.0),
                      child: Container(
                        width: 14.0,
                        height: 14.0,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primary,
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional(0.0, -1.0),
                  child: Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primary,
                      borderRadius: BorderRadius.circular(
                          FlutterFlowTheme.of(context).designToken.radius.full),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(2.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                            FlutterFlowTheme.of(context)
                                .designToken
                                .radius
                                .full),
                        child: Container(
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            borderRadius: BorderRadius.circular(
                                FlutterFlowTheme.of(context)
                                    .designToken
                                    .radius
                                    .full),
                          ),
                          alignment: AlignmentDirectional(0.0, 0.0),
                          child: CachedNetworkImage(
                            fadeInDuration: Duration(milliseconds: 0),
                            fadeOutDuration: Duration(milliseconds: 0),
                            imageUrl: valueOrDefault<String>(
                              widget!.logo_desc,
                              'https://dimg.dreamflow.cloud/v1/image/Kinship%20Botanicals%20logo%2C%20elegant%20gold%20and%20black%20floral%20typography%2C%20minimalist%20and%20premium%2C%20high-end%20aesthetic',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
