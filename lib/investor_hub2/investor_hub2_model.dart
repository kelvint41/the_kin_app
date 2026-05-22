import '/components/impact_growth_card2_widget.dart';
import '/components/investment_item_refined2_widget.dart';
import '/components/local_punch_card_section2_widget.dart';
import '/components/portfolio_impact_card2_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'investor_hub2_widget.dart' show InvestorHub2Widget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class InvestorHub2Model extends FlutterFlowModel<InvestorHub2Widget> {
  ///  State fields for stateful widgets in this page.

  // Model for ImpactGrowthCard2 component.
  late ImpactGrowthCard2Model impactGrowthCard2Model;
  // Model for PortfolioImpactCard2 component.
  late PortfolioImpactCard2Model portfolioImpactCard2Model;
  // Model for LocalPunchCardSection2 component.
  late LocalPunchCardSection2Model localPunchCardSection2Model;
  // Model for InvestmentItemRefined2 component.
  late InvestmentItemRefined2Model investmentItemRefined2Model1;
  // Model for InvestmentItemRefined2 component.
  late InvestmentItemRefined2Model investmentItemRefined2Model2;
  // Model for InvestmentItemRefined2 component.
  late InvestmentItemRefined2Model investmentItemRefined2Model3;

  @override
  void initState(BuildContext context) {
    impactGrowthCard2Model =
        createModel(context, () => ImpactGrowthCard2Model());
    portfolioImpactCard2Model =
        createModel(context, () => PortfolioImpactCard2Model());
    localPunchCardSection2Model =
        createModel(context, () => LocalPunchCardSection2Model());
    investmentItemRefined2Model1 =
        createModel(context, () => InvestmentItemRefined2Model());
    investmentItemRefined2Model2 =
        createModel(context, () => InvestmentItemRefined2Model());
    investmentItemRefined2Model3 =
        createModel(context, () => InvestmentItemRefined2Model());
  }

  @override
  void dispose() {
    impactGrowthCard2Model.dispose();
    portfolioImpactCard2Model.dispose();
    localPunchCardSection2Model.dispose();
    investmentItemRefined2Model1.dispose();
    investmentItemRefined2Model2.dispose();
    investmentItemRefined2Model3.dispose();
  }
}
