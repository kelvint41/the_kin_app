import '/components/business_card_widget.dart';
import '/components/category_item_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'professional_landing_page_widget.dart'
    show ProfessionalLandingPageWidget;
import 'package:flutter/material.dart';

class ProfessionalLandingPageModel
    extends FlutterFlowModel<ProfessionalLandingPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for CategoryItem.
  late CategoryItemModel categoryItemModel1;
  // Model for CategoryItem.
  late CategoryItemModel categoryItemModel2;
  // Model for CategoryItem.
  late CategoryItemModel categoryItemModel3;
  // Model for CategoryItem.
  late CategoryItemModel categoryItemModel4;
  // Model for BusinessCard.
  late BusinessCardModel businessCardModel1;
  // Model for BusinessCard.
  late BusinessCardModel businessCardModel2;
  // Model for BusinessCard.
  late BusinessCardModel businessCardModel3;

  @override
  void initState(BuildContext context) {
    categoryItemModel1 = createModel(context, () => CategoryItemModel());
    categoryItemModel2 = createModel(context, () => CategoryItemModel());
    categoryItemModel3 = createModel(context, () => CategoryItemModel());
    categoryItemModel4 = createModel(context, () => CategoryItemModel());
    businessCardModel1 = createModel(context, () => BusinessCardModel());
    businessCardModel2 = createModel(context, () => BusinessCardModel());
    businessCardModel3 = createModel(context, () => BusinessCardModel());
  }

  @override
  void dispose() {
    categoryItemModel1.dispose();
    categoryItemModel2.dispose();
    categoryItemModel3.dispose();
    categoryItemModel4.dispose();
    businessCardModel1.dispose();
    businessCardModel2.dispose();
    businessCardModel3.dispose();
  }
}
