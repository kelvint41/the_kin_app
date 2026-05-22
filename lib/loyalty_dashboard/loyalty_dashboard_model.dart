import '/components/kin_bottom_nav_widget.dart';
import '/components/visit_item_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'loyalty_dashboard_widget.dart' show LoyaltyDashboardWidget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_palette/material_palette.dart';
import 'package:provider/provider.dart';

class LoyaltyDashboardModel extends FlutterFlowModel<LoyaltyDashboardWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for VisitItem component.
  late VisitItemModel visitItemModel1;
  // Model for VisitItem component.
  late VisitItemModel visitItemModel2;
  // Model for VisitItem component.
  late VisitItemModel visitItemModel3;
  // Model for KinBottomNav component.
  late KinBottomNavModel kinBottomNavModel;

  @override
  void initState(BuildContext context) {
    visitItemModel1 = createModel(context, () => VisitItemModel());
    visitItemModel2 = createModel(context, () => VisitItemModel());
    visitItemModel3 = createModel(context, () => VisitItemModel());
    kinBottomNavModel = createModel(context, () => KinBottomNavModel());
  }

  @override
  void dispose() {
    visitItemModel1.dispose();
    visitItemModel2.dispose();
    visitItemModel3.dispose();
    kinBottomNavModel.dispose();
  }
}
