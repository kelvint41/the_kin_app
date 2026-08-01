import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'kin_quest_search_widget.dart' show KinQuestSearchWidget;
import 'package:flutter/material.dart';

class KinQuestSearchModel extends FlutterFlowModel<KinQuestSearchWidget> {
  /// One fetch of the whole directory, same one-shot pattern as
  /// KinQuestModel.businesses() - search runs entirely client-side over
  /// this, unfiltered by distance.
  Future<List<BusinessesRecord>>? _businesses;

  Future<List<BusinessesRecord>> businesses() =>
      _businesses ??= queryBusinessesRecordOnce();

  bool checkingIn = false;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
