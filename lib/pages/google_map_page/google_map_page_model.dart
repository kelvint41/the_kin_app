import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/business_preview_card_widget.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/premium_placement.dart';
import 'dart:ui';
import '/index.dart';
import 'google_map_page_widget.dart' show GoogleMapPageWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class GoogleMapPageModel extends FlutterFlowModel<GoogleMapPageWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for Map Google Map widget.
  LatLng? mapGoogleMapsCenter;
  final mapGoogleMapsController = Completer<GoogleMapController>();

  /// One model per premium carousel slot. Fixed length, since the
  /// carousel always renders at most [kPremiumCarouselSlots] cards and
  /// the businesses occupying them change with the rotation window, not
  /// the slot count.
  late final List<BusinessPreviewCardModel> premiumCardModels;

  @override
  void initState(BuildContext context) {
    premiumCardModels = List.generate(
      kPremiumCarouselSlots,
      (_) => createModel(context, () => BusinessPreviewCardModel()),
    );
  }

  @override
  void dispose() {
    for (final model in premiumCardModels) {
      model.dispose();
    }
  }
}
