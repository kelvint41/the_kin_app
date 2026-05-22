import '/components/ticker_pulse_item_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'page1_welcome_mission_copy_widget.dart'
    show Page1WelcomeMissionCopyWidget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_palette/material_palette.dart';
import 'package:provider/provider.dart';

class Page1WelcomeMissionCopyModel
    extends FlutterFlowModel<Page1WelcomeMissionCopyWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for TickerPulseItem component.
  late TickerPulseItemModel tickerPulseItemModel1;
  // Model for TickerPulseItem component.
  late TickerPulseItemModel tickerPulseItemModel2;
  // Model for TickerPulseItem component.
  late TickerPulseItemModel tickerPulseItemModel3;
  // Model for TickerPulseItem component.
  late TickerPulseItemModel tickerPulseItemModel4;

  @override
  void initState(BuildContext context) {
    tickerPulseItemModel1 = createModel(context, () => TickerPulseItemModel());
    tickerPulseItemModel2 = createModel(context, () => TickerPulseItemModel());
    tickerPulseItemModel3 = createModel(context, () => TickerPulseItemModel());
    tickerPulseItemModel4 = createModel(context, () => TickerPulseItemModel());
  }

  @override
  void dispose() {
    tickerPulseItemModel1.dispose();
    tickerPulseItemModel2.dispose();
    tickerPulseItemModel3.dispose();
    tickerPulseItemModel4.dispose();
  }
}
