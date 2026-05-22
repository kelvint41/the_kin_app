import '/components/benefit_item_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'business_manager_upgrade_widget.dart' show BusinessManagerUpgradeWidget;
import 'package:flutter/material.dart';

class BusinessManagerUpgradeModel
    extends FlutterFlowModel<BusinessManagerUpgradeWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for BenefitItem component.
  late BenefitItemModel benefitItemModel1;
  // Model for BenefitItem component.
  late BenefitItemModel benefitItemModel2;
  // Model for BenefitItem component.
  late BenefitItemModel benefitItemModel3;
  // Model for BenefitItem component.
  late BenefitItemModel benefitItemModel4;

  @override
  void initState(BuildContext context) {
    benefitItemModel1 = createModel(context, () => BenefitItemModel());
    benefitItemModel2 = createModel(context, () => BenefitItemModel());
    benefitItemModel3 = createModel(context, () => BenefitItemModel());
    benefitItemModel4 = createModel(context, () => BenefitItemModel());
  }

  @override
  void dispose() {
    benefitItemModel1.dispose();
    benefitItemModel2.dispose();
    benefitItemModel3.dispose();
    benefitItemModel4.dispose();
  }
}
