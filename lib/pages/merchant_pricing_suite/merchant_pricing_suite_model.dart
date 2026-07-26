import '/components/tier_card_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'merchant_pricing_suite_widget.dart' show MerchantPricingSuiteWidget;
import 'package:flutter/material.dart';

class MerchantPricingSuiteModel
    extends FlutterFlowModel<MerchantPricingSuiteWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for TierCard.
  late TierCardModel tierCardModel1;
  // Model for TierCard.
  late TierCardModel tierCardModel2;
  // Model for TierCard.
  late TierCardModel tierCardModel3;
  // Model for TierCard.
  late TierCardModel tierCardModel4;

  @override
  void initState(BuildContext context) {
    tierCardModel1 = createModel(context, () => TierCardModel());
    tierCardModel2 = createModel(context, () => TierCardModel());
    tierCardModel3 = createModel(context, () => TierCardModel());
    tierCardModel4 = createModel(context, () => TierCardModel());
  }

  @override
  void dispose() {
    tierCardModel1.dispose();
    tierCardModel2.dispose();
    tierCardModel3.dispose();
    tierCardModel4.dispose();
  }
}
