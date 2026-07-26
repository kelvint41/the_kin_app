import '/components/podium_spot_widget.dart';
import '/components/rank_card_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'community_prestige_widget.dart' show CommunityPrestigeWidget;
import 'package:flutter/material.dart';

class CommunityPrestigeModel extends FlutterFlowModel<CommunityPrestigeWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for PodiumSpot.
  late PodiumSpotModel podiumSpotModel1;
  // Model for PodiumSpot.
  late PodiumSpotModel podiumSpotModel2;
  // Model for PodiumSpot.
  late PodiumSpotModel podiumSpotModel3;
  // Model for RankCard.
  late RankCardModel rankCardModel1;
  // Model for RankCard.
  late RankCardModel rankCardModel2;
  // Model for RankCard.
  late RankCardModel rankCardModel3;
  // Model for RankCard.
  late RankCardModel rankCardModel4;
  // Model for RankCard.
  late RankCardModel rankCardModel5;
  // Model for RankCard.
  late RankCardModel rankCardModel6;
  // Model for RankCard.
  late RankCardModel rankCardModel7;

  @override
  void initState(BuildContext context) {
    podiumSpotModel1 = createModel(context, () => PodiumSpotModel());
    podiumSpotModel2 = createModel(context, () => PodiumSpotModel());
    podiumSpotModel3 = createModel(context, () => PodiumSpotModel());
    rankCardModel1 = createModel(context, () => RankCardModel());
    rankCardModel2 = createModel(context, () => RankCardModel());
    rankCardModel3 = createModel(context, () => RankCardModel());
    rankCardModel4 = createModel(context, () => RankCardModel());
    rankCardModel5 = createModel(context, () => RankCardModel());
    rankCardModel6 = createModel(context, () => RankCardModel());
    rankCardModel7 = createModel(context, () => RankCardModel());
  }

  @override
  void dispose() {
    podiumSpotModel1.dispose();
    podiumSpotModel2.dispose();
    podiumSpotModel3.dispose();
    rankCardModel1.dispose();
    rankCardModel2.dispose();
    rankCardModel3.dispose();
    rankCardModel4.dispose();
    rankCardModel5.dispose();
    rankCardModel6.dispose();
    rankCardModel7.dispose();
  }
}
