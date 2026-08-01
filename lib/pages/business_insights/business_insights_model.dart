import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'business_insights_widget.dart' show BusinessInsightsWidget;
import 'package:flutter/material.dart';

class BusinessInsightsModel extends FlutterFlowModel<BusinessInsightsWidget> {
  /// One fetch per visit, same reasoning as KinQuestModel.businesses() -
  /// check-in history doesn't need a live listener for a stats summary.
  Future<List<UservisitsRecord>>? _visits;

  Future<List<UservisitsRecord>> visitsFor(DocumentReference businessRef) =>
      _visits ??= queryUservisitsRecordOnce(
        queryBuilder: (q) => q.where('business_ref', isEqualTo: businessRef),
      );

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
