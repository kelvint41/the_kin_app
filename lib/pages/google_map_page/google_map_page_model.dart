import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/business_preview_card_widget.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/geohash_util.dart';
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

  /// Map pins for the current viewport, fetched via a bounded geohash
  /// range query rather than the whole `businesses` collection.
  ///
  /// This used to be `queryBusinessesRecordOnce()` with no `where`/bounds -
  /// an unbounded read of every document (500 at the time, all Texas; fine
  /// then, not at national scale). Real bounding needs a geohash on each
  /// document, since Firestore can't range-query a GeoPoint on both axes -
  /// see backfill_business_geohashes.js for the migration that adds it.
  /// Businesses written before that migration runs simply won't have a
  /// `geohash` field and won't appear here until it does.
  ///
  /// Memoized per-viewport (not per page-load) so panning the map re-queries,
  /// but a rebuild that doesn't change the viewport (a category chip tap)
  /// reuses the last result instead of re-issuing the query.
  Future<List<BusinessesRecord>>? _businesses;
  LatLngBounds? _queriedBounds;

  Future<List<BusinessesRecord>> businessesForViewport(
    LatLngBounds bounds,
  ) {
    if (_businesses != null && _boundsRoughlyEqual(_queriedBounds, bounds)) {
      return _businesses!;
    }
    _queriedBounds = bounds;
    return _businesses = _queryViewport(bounds);
  }

  /// Within ~1km, camera jitter (a sub-pixel drag, a rebuild with no real
  /// pan) shouldn't trigger a re-query.
  bool _boundsRoughlyEqual(LatLngBounds? a, LatLngBounds b) {
    if (a == null) return false;
    const eps = 0.01;
    return (a.southwest.latitude - b.southwest.latitude).abs() < eps &&
        (a.southwest.longitude - b.southwest.longitude).abs() < eps &&
        (a.northeast.latitude - b.northeast.latitude).abs() < eps &&
        (a.northeast.longitude - b.northeast.longitude).abs() < eps;
  }

  Future<List<BusinessesRecord>> _queryViewport(LatLngBounds bounds) async {
    final prefixes = geohashPrefixesForBounds(
      swLat: bounds.southwest.latitude,
      swLng: bounds.southwest.longitude,
      neLat: bounds.northeast.latitude,
      neLng: bounds.northeast.longitude,
    );
    final results = await Future.wait(prefixes.map(
      (prefix) => queryBusinessesRecordOnce(
        queryBuilder: (q) => q
            .where('geohash', isGreaterThanOrEqualTo: prefix)
            .where('geohash', isLessThan: '$prefix~'),
      ),
    ));
    final byPath = <String, BusinessesRecord>{};
    for (final list in results) {
      for (final b in list) {
        byPath[b.reference.path] = b;
      }
    }
    return byPath.values.toList();
  }

  /// Drops the memoized copy so the next build refetches even if the
  /// viewport hasn't changed (e.g. after a manual refresh action).
  void refreshBusinesses() {
    _businesses = null;
    _queriedBounds = null;
  }

  /// Businesses on a paid plan, for the premium carousel - a small targeted
  /// query on `subscription_tier` (see kPaidSubscriptionTiers in
  /// premium_placement.dart), independent of the map viewport: a merchant
  /// who paid for placement shouldn't lose it just because the customer
  /// panned away, so this deliberately isn't bounded by geohash like the
  /// map pins are.
  Future<List<BusinessesRecord>>? _premiumBusinesses;

  Future<List<BusinessesRecord>> premiumBusinesses() =>
      _premiumBusinesses ??= queryBusinessesRecordOnce(
        queryBuilder: (q) => q.where(
          'subscription_tier',
          whereIn: kPaidSubscriptionTiers.toList(),
        ),
      );

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
