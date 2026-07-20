import '/flutter_flow/flutter_flow_util.dart';
import 'referral_share_widget.dart' show ReferralShareWidget;
import 'package:flutter/material.dart';

class ReferralShareModel extends FlutterFlowModel<ReferralShareWidget> {
  ///  State fields for stateful widgets in this component.

  // The current user's referral code for this campaign, fetched once from
  // KinServices.getOrCreateReferralCode. Null until loaded.
  String? code;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
