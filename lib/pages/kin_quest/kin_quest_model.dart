import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'kin_quest_widget.dart' show KinQuestWidget;
import 'package:flutter/material.dart';

class KinQuestModel extends FlutterFlowModel<KinQuestWidget> {
  /// The user's location, resolved once in initState. Null means "still
  /// resolving"; [locationResolved] disambiguates that from "resolved, but
  /// permission was denied and we fell back to the default" - same split
  /// as NearbyFeedModel.
  LatLng? userLocation;
  bool locationResolved = false;

  /// The directory, fetched once per visit - same one-shot pattern as
  /// NearbyFeedModel.businesses(). Rarity/points fields on each record are
  /// static enough that a live listener isn't worth paying for here.
  Future<List<BusinessesRecord>>? _businesses;

  Future<List<BusinessesRecord>> businesses() =>
      _businesses ??= queryBusinessesRecordOnce();

  /// True while a check-in call is in flight, to disable the button and
  /// stop a double-tap firing two check-ins (the server already dedupes,
  /// but this avoids the round-trip and the flicker of two snackbars).
  bool checkingIn = false;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
