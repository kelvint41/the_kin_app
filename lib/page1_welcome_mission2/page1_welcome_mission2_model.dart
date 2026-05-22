import '/components/verified_trust_badge_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'page1_welcome_mission2_widget.dart' show Page1WelcomeMission2Widget;
import 'package:flutter/material.dart';

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
