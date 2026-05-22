import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/flutter_flow/revenue_cat_util.dart' as revenue_cat;
import '/index.dart';
import 'the_membership_suite_widget.dart' show TheMembershipSuiteWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class TheMembershipSuiteModel
    extends FlutterFlowModel<TheMembershipSuiteWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [RevenueCat - Purchase] action in Button widget.
  bool? proPurchase;
  // Stores action output result for [RevenueCat - Purchase] action in Button widget.
  bool? elitePurchase;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
