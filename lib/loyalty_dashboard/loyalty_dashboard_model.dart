import '/components/visit_item_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'loyalty_dashboard_widget.dart' show LoyaltyDashboardWidget;
import 'package:flutter/material.dart';

class LoyaltyDashboardModel extends FlutterFlowModel<LoyaltyDashboardWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for VisitItem component.
  late VisitItemModel visitItemModel1;
  // Model for VisitItem component.
  late VisitItemModel visitItemModel2;
  // Model for VisitItem component.
  late VisitItemModel visitItemModel3;

  @override
  void initState(BuildContext context) {
    visitItemModel1 = createModel(context, () => VisitItemModel());
    visitItemModel2 = createModel(context, () => VisitItemModel());
    visitItemModel3 = createModel(context, () => VisitItemModel());
  }

  @override
  void dispose() {
    visitItemModel1.dispose();
    visitItemModel2.dispose();
    visitItemModel3.dispose();
  }
}
