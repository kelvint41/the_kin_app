import '/components/admin_campaign_card_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'admin_dashboard_widget.dart' show AdminDashboardWidget;
import 'package:flutter/material.dart';

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
