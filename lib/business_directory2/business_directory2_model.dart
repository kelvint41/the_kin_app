import '/components/kin_bottom_nav_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'business_directory2_widget.dart' show BusinessDirectory2Widget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class BusinessDirectory2Model
    extends FlutterFlowModel<BusinessDirectory2Widget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Model for KinBottomNav component.
  late KinBottomNavModel kinBottomNavModel;

  /// Optional partner/API payload merged on top of Firestore data.
  List<Map<String, dynamic>> externalFeedPayload = [];

  @override
  void initState(BuildContext context) {
    kinBottomNavModel = createModel(context, () => KinBottomNavModel());
  }

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
    kinBottomNavModel.dispose();
  }
}
