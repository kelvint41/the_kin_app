import '/flutter_flow/flutter_flow_util.dart';
import '/pages/local_verified_badge/local_verified_badge_widget.dart';
import 'refined_preview_sheet_widget.dart' show RefinedPreviewSheetWidget;
import 'package:flutter/material.dart';

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
