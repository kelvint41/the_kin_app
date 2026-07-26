import '/backend/backend.dart';
import '/components/kpi_card_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'executive_dashboard_widget.dart' show ExecutiveDashboardWidget;
import 'package:flutter/material.dart';

class ExecutiveDashboardModel
    extends FlutterFlowModel<ExecutiveDashboardWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - Read Document] action in Executive_Dashboard widget.
  UsersRecord? userDocument;
  // Model for KpiCard.
  late KpiCardModel kpiCardModel1;
  // Model for KpiCard.
  late KpiCardModel kpiCardModel2;
  // Model for KpiCard.
  late KpiCardModel kpiCardModel3;
  // Model for KpiCard.
  late KpiCardModel kpiCardModel4;
  // State field(s) for Dropdown widget.
  String? dropdownValue;
  FormFieldController<String>? dropdownValueController;

  @override
  void initState(BuildContext context) {
    kpiCardModel1 = createModel(context, () => KpiCardModel());
    kpiCardModel2 = createModel(context, () => KpiCardModel());
    kpiCardModel3 = createModel(context, () => KpiCardModel());
    kpiCardModel4 = createModel(context, () => KpiCardModel());
  }

  @override
  void dispose() {
    kpiCardModel1.dispose();
    kpiCardModel2.dispose();
    kpiCardModel3.dispose();
    kpiCardModel4.dispose();
  }
}
