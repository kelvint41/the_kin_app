import '/components/business_preview_card_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'map_page_view_item_widget.dart' show MapPageViewItemWidget;
import 'package:flutter/material.dart';

class MapPageViewItemModel extends FlutterFlowModel<MapPageViewItemWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for PageView widget.
  PageController? pageViewController;

  int get pageViewCurrentIndex => pageViewController != null &&
          pageViewController!.hasClients &&
          pageViewController!.page != null
      ? pageViewController!.page!.round()
      : 0;
  // Model for BusinessPreviewCard component.
  late BusinessPreviewCardModel businessPreviewCardModel;

  @override
  void initState(BuildContext context) {
    businessPreviewCardModel =
        createModel(context, () => BusinessPreviewCardModel());
  }

  @override
  void dispose() {
    businessPreviewCardModel.dispose();
  }
}
