import '/components/impact_growth_card_widget.dart';
import '/components/investment_item_refined_widget.dart';
import '/components/local_punch_card_section_widget.dart';
import '/components/portfolio_impact_card_widget.dart';
import '/components/profile_header_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'investor_hub_widget.dart' show InvestorHubWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class InvestorHubModel extends FlutterFlowModel<InvestorHubWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for ProfileHeader component.
  late ProfileHeaderModel profileHeaderModel;
  // Model for ImpactGrowthCard component.
  late ImpactGrowthCardModel impactGrowthCardModel;
  // Model for PortfolioImpactCard component.
  late PortfolioImpactCardModel portfolioImpactCardModel;
  // Model for LocalPunchCardSection component.
  late LocalPunchCardSectionModel localPunchCardSectionModel;
  // Model for InvestmentItemRefined component.
  late InvestmentItemRefinedModel investmentItemRefinedModel1;
  // Model for InvestmentItemRefined component.
  late InvestmentItemRefinedModel investmentItemRefinedModel2;

  @override
  void initState(BuildContext context) {
    profileHeaderModel = createModel(context, () => ProfileHeaderModel());
    impactGrowthCardModel = createModel(context, () => ImpactGrowthCardModel());
    portfolioImpactCardModel =
        createModel(context, () => PortfolioImpactCardModel());
    localPunchCardSectionModel =
        createModel(context, () => LocalPunchCardSectionModel());
    investmentItemRefinedModel1 =
        createModel(context, () => InvestmentItemRefinedModel());
    investmentItemRefinedModel2 =
        createModel(context, () => InvestmentItemRefinedModel());
  }

  @override
  void dispose() {
    profileHeaderModel.dispose();
    impactGrowthCardModel.dispose();
    portfolioImpactCardModel.dispose();
    localPunchCardSectionModel.dispose();
    investmentItemRefinedModel1.dispose();
    investmentItemRefinedModel2.dispose();
  }
}
