import '/components/ticker_card_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'premium_mobile_user_page_widget.dart' show PremiumMobileUserPageWidget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PremiumMobileUserPageModel
    extends FlutterFlowModel<PremiumMobileUserPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for TickerCard.
  late TickerCardModel tickerCardModel1;
  // Model for TickerCard.
  late TickerCardModel tickerCardModel2;

  @override
  void initState(BuildContext context) {
    tickerCardModel1 = createModel(context, () => TickerCardModel());
    tickerCardModel2 = createModel(context, () => TickerCardModel());
  }

  @override
  void dispose() {
    tickerCardModel1.dispose();
    tickerCardModel2.dispose();
  }
}
