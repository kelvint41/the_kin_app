import '/components/ticker_item_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'cinematic_high_contrast_page_widget.dart'
    show CinematicHighContrastPageWidget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CinematicHighContrastPageModel
    extends FlutterFlowModel<CinematicHighContrastPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for TickerItem.
  late TickerItemModel tickerItemModel1;
  // Model for TickerItem.
  late TickerItemModel tickerItemModel2;
  // Model for TickerItem.
  late TickerItemModel tickerItemModel3;
  // Model for TickerItem.
  late TickerItemModel tickerItemModel4;

  @override
  void initState(BuildContext context) {
    tickerItemModel1 = createModel(context, () => TickerItemModel());
    tickerItemModel2 = createModel(context, () => TickerItemModel());
    tickerItemModel3 = createModel(context, () => TickerItemModel());
    tickerItemModel4 = createModel(context, () => TickerItemModel());
  }

  @override
  void dispose() {
    tickerItemModel1.dispose();
    tickerItemModel2.dispose();
    tickerItemModel3.dispose();
    tickerItemModel4.dispose();
  }
}
