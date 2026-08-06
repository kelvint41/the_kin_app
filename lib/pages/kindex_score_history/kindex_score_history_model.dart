import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'kindex_score_history_widget.dart' show KindexScoreHistoryWidget;
import 'package:flutter/material.dart';

class KindexScoreHistoryModel
    extends FlutterFlowModel<KindexScoreHistoryWidget> {
  Future<List<KindexScoreHistoryRecord>>? _history;

  /// One fetch per visit, same reasoning as BusinessInsightsModel.visitsFor
  /// - this is a historical ledger, not something that needs a live
  /// listener while the screen is open. 90 days covers a full quarter of
  /// nightly rows, which is plenty for a trend view without an unbounded
  /// read growing every day forever.
  Future<List<KindexScoreHistoryRecord>> historyFor({
    DocumentReference? businessRef,
    DocumentReference? userRef,
  }) =>
      _history ??= queryKindexScoreHistoryRecordOnce(
        queryBuilder: (q) => businessRef != null
            ? q
                .where('business_ref', isEqualTo: businessRef)
                .orderBy('recorded_at', descending: true)
            : q
                .where('user_ref', isEqualTo: userRef)
                .orderBy('recorded_at', descending: true),
        limit: 90,
      );

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
