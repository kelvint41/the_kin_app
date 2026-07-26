import '/flutter_flow/flutter_flow_util.dart';
import 'admin_campaign_card_widget.dart' show AdminCampaignCardWidget;
import 'package:flutter/material.dart';

class AdminCampaignCardModel extends FlutterFlowModel<AdminCampaignCardWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for Switch widget.
  bool? switchValue;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
