import '/components/feature_item_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'tier_card_widget.dart' show TierCardWidget;
import 'package:flutter/material.dart';

class TierCardModel extends FlutterFlowModel<TierCardWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for FeatureItem.
  late FeatureItemModel featureItemModel1;
  // Model for FeatureItem.
  late FeatureItemModel featureItemModel2;
  // Model for FeatureItem.
  late FeatureItemModel featureItemModel3;
  // Model for FeatureItem.
  late FeatureItemModel featureItemModel4;

  @override
  void initState(BuildContext context) {
    featureItemModel1 = createModel(context, () => FeatureItemModel());
    featureItemModel2 = createModel(context, () => FeatureItemModel());
    featureItemModel3 = createModel(context, () => FeatureItemModel());
    featureItemModel4 = createModel(context, () => FeatureItemModel());
  }

  @override
  void dispose() {
    featureItemModel1.dispose();
    featureItemModel2.dispose();
    featureItemModel3.dispose();
    featureItemModel4.dispose();
  }
}
