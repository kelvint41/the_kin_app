import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'nearby_feed_widget.dart' show NearbyFeedWidget;
import 'package:flutter/material.dart';

class NearbyFeedModel extends FlutterFlowModel<NearbyFeedWidget> {
  /// The user's location, resolved once in initState.
  ///
  /// Null means "still resolving"; [locationResolved] disambiguates that from
  /// "resolved, but permission was denied and we fell back to the default".
  LatLng? userLocation;
  bool locationResolved = false;

  /// The directory, fetched once per visit, for the same reason as
  /// GoogleMapPage - see `GoogleMapPageModel.businesses`. This was the
  /// identical whole-collection snapshot listener.
  ///
  /// Only the business layer is a one-shot: the `exchange_posts` streams
  /// nested underneath stay live, because a post appearing on a nearby
  /// wall while the user is reading the feed is exactly the update this
  /// page exists to show.
  Future<List<BusinessesRecord>>? _businesses;

  Future<List<BusinessesRecord>> businesses() =>
      _businesses ??= queryBusinessesRecordOnce();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
