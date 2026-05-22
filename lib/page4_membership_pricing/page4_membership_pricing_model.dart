import '/components/feature_bullet_widget.dart';
import '/components/local_punch_card_widget.dart';
import '/components/loyalty_header_widget.dart';
import '/components/visit_item2_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'page4_membership_pricing_widget.dart' show Page4MembershipPricingWidget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_palette/material_palette.dart';
import 'package:provider/provider.dart';

class Page4MembershipPricingModel
    extends FlutterFlowModel<Page4MembershipPricingWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for LoyaltyHeader component.
  late LoyaltyHeaderModel loyaltyHeaderModel;
  // Model for LocalPunchCard component.
  late LocalPunchCardModel localPunchCardModel;
  // Model for FeatureBullet component.
  late FeatureBulletModel featureBulletModel1;
  // Model for FeatureBullet component.
  late FeatureBulletModel featureBulletModel2;
  // Model for FeatureBullet component.
  late FeatureBulletModel featureBulletModel3;
  // Model for VisitItem2 component.
  late VisitItem2Model visitItem2Model1;
  // Model for VisitItem2 component.
  late VisitItem2Model visitItem2Model2;
  // Model for VisitItem2 component.
  late VisitItem2Model visitItem2Model3;

  @override
  void initState(BuildContext context) {
    loyaltyHeaderModel = createModel(context, () => LoyaltyHeaderModel());
    localPunchCardModel = createModel(context, () => LocalPunchCardModel());
    featureBulletModel1 = createModel(context, () => FeatureBulletModel());
    featureBulletModel2 = createModel(context, () => FeatureBulletModel());
    featureBulletModel3 = createModel(context, () => FeatureBulletModel());
    visitItem2Model1 = createModel(context, () => VisitItem2Model());
    visitItem2Model2 = createModel(context, () => VisitItem2Model());
    visitItem2Model3 = createModel(context, () => VisitItem2Model());
  }

  @override
  void dispose() {
    loyaltyHeaderModel.dispose();
    localPunchCardModel.dispose();
    featureBulletModel1.dispose();
    featureBulletModel2.dispose();
    featureBulletModel3.dispose();
    visitItem2Model1.dispose();
    visitItem2Model2.dispose();
    visitItem2Model3.dispose();
  }
}
