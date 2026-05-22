import '/components/verified_trust_badge_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'page1_welcome_mission2_widget.dart' show Page1WelcomeMission2Widget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class Page1WelcomeMission2Model
    extends FlutterFlowModel<Page1WelcomeMission2Widget> {
  ///  State fields for stateful widgets in this page.

  // Model for VerifiedTrustBadge component.
  late VerifiedTrustBadgeModel verifiedTrustBadgeModel;

  @override
  void initState(BuildContext context) {
    verifiedTrustBadgeModel =
        createModel(context, () => VerifiedTrustBadgeModel());
  }

  @override
  void dispose() {
    verifiedTrustBadgeModel.dispose();
  }
}
