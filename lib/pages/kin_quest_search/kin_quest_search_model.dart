import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/quest_eligibility.dart';
import 'kin_quest_search_widget.dart' show KinQuestSearchWidget;
import 'package:flutter/material.dart';

class KinQuestSearchModel extends FlutterFlowModel<KinQuestSearchWidget> {
  /// One fetch of the whole directory, same one-shot pattern as
  /// KinQuestModel.businesses() - search runs entirely client-side over
  /// this, unfiltered by distance.
  ///
  /// Quest-excluded categories are filtered out here too: this screen's
  /// results are check-in targets, so letting a search surface a business
  /// the Quest list deliberately hides would just be a back door to the
  /// same dead end.
  Future<List<BusinessesRecord>>? _businesses;

  Future<List<BusinessesRecord>> businesses() =>
      _businesses ??= QuestEligibility.questEligibleBusinesses();

  bool checkingIn = false;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
