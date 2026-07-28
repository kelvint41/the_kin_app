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

  /// The directory, fetched once per visit to this page.
  ///
  /// This was a `queryBusinessesRecord()` stream, which holds an open
  /// snapshot listener over every document in `businesses` for as long as
  /// the page is mounted. Nothing on this page needs that: the directory
  /// is a bulk-imported dataset that changes when someone runs an import
  /// script, not while a customer is panning the map, and none of what we
  /// derive from it - pins, the premium carousel, the category filter -
  /// would be meaningfully stale after a few minutes.
  ///
  /// Memoized in the model rather than the widget so a rebuild (a
  /// category chip tap, a camera idle) reuses the resolved list instead of
  /// re-issuing the query, which is what a bare `FutureBuilder(future:
  /// queryOnce())` in `build` would do.
  ///
  /// Note this is still an unbounded read of the whole collection - 500
  /// documents today, all of them Texas. That is fine at this size and
  /// will not be at national scale. Bounding it properly needs viewport
  /// querying, and that needs a geohash on each document: Firestore cannot
  /// range-query a GeoPoint on both axes, which is also why proximity in
  /// NearbyFeed is computed client-side. Until those exist there is no
  /// honest server-side bound - a bare `.limit()` would silently drop
  /// businesses off the map with no way to tell which.
  Future<List<BusinessesRecord>>? _businesses;

  Future<List<BusinessesRecord>> businesses() =>
      _businesses ??= queryBusinessesRecordOnce();

  /// Drops the memoized copy so the next build refetches.
  void refreshBusinesses() => _businesses = null;

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
