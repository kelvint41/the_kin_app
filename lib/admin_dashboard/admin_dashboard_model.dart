import '/components/admin_campaign_card_widget.dart';
import '/flutter_flow/flutter_flow_charts.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'admin_dashboard_widget.dart' show AdminDashboardWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AdminDashboardModel extends FlutterFlowModel<AdminDashboardWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for AdminCampaignCard component.
  late AdminCampaignCardModel adminCampaignCardModel1;
  // Model for AdminCampaignCard component.
  late AdminCampaignCardModel adminCampaignCardModel2;
  // Model for AdminCampaignCard component.
  late AdminCampaignCardModel adminCampaignCardModel3;
  // Model for AdminCampaignCard component.
  late AdminCampaignCardModel adminCampaignCardModel4;

  @override
  void initState(BuildContext context) {
    adminCampaignCardModel1 =
        createModel(context, () => AdminCampaignCardModel());
    adminCampaignCardModel2 =
        createModel(context, () => AdminCampaignCardModel());
    adminCampaignCardModel3 =
        createModel(context, () => AdminCampaignCardModel());
    adminCampaignCardModel4 =
        createModel(context, () => AdminCampaignCardModel());
  }

  @override
  void dispose() {
    adminCampaignCardModel1.dispose();
    adminCampaignCardModel2.dispose();
    adminCampaignCardModel3.dispose();
    adminCampaignCardModel4.dispose();
  }
}
