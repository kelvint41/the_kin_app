import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/action_btn_widget.dart';
import '/components/clean_elegant_mobile_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'business_profile_v2_widget.dart' show BusinessProfileV2Widget;
import 'package:map_launcher/map_launcher.dart' as $ml;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class BusinessProfileV2Model extends FlutterFlowModel<BusinessProfileV2Widget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for RatingBar widget.
  double? ratingBarValue;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Stores action output result for [Custom Action - calculateRealTimeKindex] action in Column widget.
  double? updatedKindexResult;
  // V1 review section: optional photo attachment (draft - kept local for
  // preview only, not yet uploaded to Firebase Storage; see
  // KinServices.submitReview call site for the pending-approval note).
  // Stored as decoded bytes (rather than the picker's XFile/File) so the
  // thumbnail renders the same way on web and mobile.
  Uint8List? attachedReviewPhotoBytes;
  String? attachedReviewPhotoName;
  // Guards Submit Review against a double-tap while a photo upload (or the
  // review write itself) is in flight.
  bool isSubmittingReview = false;
  // Models for the owner-only "Manage Your Business" action row.
  late ActionBtnModel ownerSetupActionModel;
  late ActionBtnModel ownerPricingActionModel;
  late ActionBtnModel ownerDashboardActionModel;
  late ActionBtnModel ownerAiMarketingActionModel;

  @override
  void initState(BuildContext context) {
    ownerSetupActionModel = createModel(context, () => ActionBtnModel());
    ownerPricingActionModel = createModel(context, () => ActionBtnModel());
    ownerDashboardActionModel = createModel(context, () => ActionBtnModel());
    ownerAiMarketingActionModel = createModel(context, () => ActionBtnModel());
  }

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();

    ownerSetupActionModel.dispose();
    ownerPricingActionModel.dispose();
    ownerDashboardActionModel.dispose();
    ownerAiMarketingActionModel.dispose();
  }
}
