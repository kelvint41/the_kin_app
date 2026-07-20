import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'story_detail_model.dart';
export 'story_detail_model.dart';

/// Detail page for a premium story tile tapped from The Exchange.
///
/// Receives the story's [storyLabel] and hero image [imgDesc] as query
/// parameters so a single page can back any of the story tiles.
class StoryDetailWidget extends StatefulWidget {
  const StoryDetailWidget({
    super.key,
    this.storyLabel,
    this.imgDesc,
  });

  final String? storyLabel;
  final String? imgDesc;

  static String routeName = 'StoryDetail';
  static String routePath = '/storyDetail';

  @override
  State<StoryDetailWidget> createState() => _StoryDetailWidgetState();
}

class _StoryDetailWidgetState extends State<StoryDetailWidget> {
  late StoryDetailModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => StoryDetailModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final label = valueOrDefault<String>(widget.storyLabel, 'Story');
    final imageUrl = valueOrDefault<String>(
      widget.imgDesc,
      'https://dimg.dreamflow.cloud/v1/image/smiling%20black%20woman%20coffee%20shop%20owner',
    );

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.primaryBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320.0,
            pinned: true,
            backgroundColor: theme.primaryBackground,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: theme.primaryText),
              onPressed: () => context.safePop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  color: theme.secondaryBackground,
                  child: Icon(Icons.broken_image_rounded,
                      color: theme.secondaryText, size: 48.0),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(24.0, 24.0, 24.0, 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.headlineMedium.override(
                      font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                      ),
                      color: theme.primaryText,
                      letterSpacing: 0.0,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 0.0),
                    child: Text(
                      'This is the story of $label. Full story content coming '
                      'soon — this page is wired up and ready for its content.',
                      style: theme.bodyMedium.override(
                        font: GoogleFonts.plusJakartaSans(),
                        color: theme.secondaryText,
                        letterSpacing: 0.0,
                        lineHeight: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
