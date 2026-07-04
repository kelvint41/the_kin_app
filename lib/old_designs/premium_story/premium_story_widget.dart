import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'premium_story_model.dart';
export 'premium_story_model.dart';

class PremiumStoryWidget extends StatefulWidget {
  const PremiumStoryWidget({
    super.key,
    this.img_desc,
    this.label,
  });

  final String? img_desc;
  final String? label;

  @override
  State<PremiumStoryWidget> createState() => _PremiumStoryWidgetState();
}

class _PremiumStoryWidgetState extends State<PremiumStoryWidget> {
  late PremiumStoryModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PremiumStoryModel());
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
        Container(
          width: 76.0,
          height: 76.0,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                FlutterFlowTheme.of(context).accent1,
                FlutterFlowTheme.of(context).secondary
              ],
              stops: [0.0, 1.0],
              begin: AlignmentDirectional(-1.0, 1.0),
              end: AlignmentDirectional(1.0, -1.0),
            ),
            borderRadius: BorderRadius.circular(
                FlutterFlowTheme.of(context).designToken.radius.full),
          ),
          child: Padding(
            padding: EdgeInsets.all(2.0),
            child: Container(
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primaryBackground,
                borderRadius: BorderRadius.circular(
                    FlutterFlowTheme.of(context).designToken.radius.full),
              ),
              child: Padding(
                padding: EdgeInsets.all(3.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                      FlutterFlowTheme.of(context).designToken.radius.full),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                          FlutterFlowTheme.of(context).designToken.radius.full),
                    ),
                    child: CachedNetworkImage(
                      fadeInDuration: Duration(milliseconds: 0),
                      fadeOutDuration: Duration(milliseconds: 0),
                      imageUrl: valueOrDefault<String>(
                        widget!.img_desc,
                        'https://dimg.dreamflow.cloud/v1/image/smiling%20black%20woman%20coffee%20shop%20owner',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Text(
          valueOrDefault<String>(
            widget!.label,
            'The Grind',
          ),
          maxLines: 1,
          style: FlutterFlowTheme.of(context).labelSmall.override(
                font: GoogleFonts.plusJakartaSans(
                  fontWeight:
                      FlutterFlowTheme.of(context).labelSmall.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                ),
                color: FlutterFlowTheme.of(context).primaryText,
                letterSpacing: 0.0,
                fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
              ),
          overflow: TextOverflow.ellipsis,
        ),
      ].divide(SizedBox(
          height: FlutterFlowTheme.of(context).designToken.spacing.xs)),
    );
  }
}
