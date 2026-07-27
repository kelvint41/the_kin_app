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

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
