import '/components/local_verified_badge_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'refined_preview_sheet_widget.dart' show RefinedPreviewSheetWidget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class RefinedPreviewSheetModel
    extends FlutterFlowModel<RefinedPreviewSheetWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for LocalVerifiedBadge component.
  late LocalVerifiedBadgeModel localVerifiedBadgeModel;

  @override
  void initState(BuildContext context) {
    localVerifiedBadgeModel =
        createModel(context, () => LocalVerifiedBadgeModel());
  }

  @override
  void dispose() {
    localVerifiedBadgeModel.dispose();
  }
}
