import '/backend/backend.dart';
import '/backend/gemini/gemini.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'business_profile2_widget.dart' show BusinessProfile2Widget;
import 'package:map_launcher/map_launcher.dart' as $ml;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class BusinessProfile2Model extends FlutterFlowModel<BusinessProfile2Widget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Gemini - Generate Text] action in BusinessProfile_2 widget.
  String? aiInsight;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
