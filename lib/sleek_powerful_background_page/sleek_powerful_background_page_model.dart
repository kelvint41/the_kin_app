import '/components/stat_ticker_item_widget.dart';
import '/flutter_flow/flutter_flow_charts.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'sleek_powerful_background_page_widget.dart'
    show SleekPowerfulBackgroundPageWidget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SleekPowerfulBackgroundPageModel
    extends FlutterFlowModel<SleekPowerfulBackgroundPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for StatTickerItem.
  late StatTickerItemModel statTickerItemModel1;
  // Model for StatTickerItem.
  late StatTickerItemModel statTickerItemModel2;
  // Model for StatTickerItem.
  late StatTickerItemModel statTickerItemModel3;
  // Model for StatTickerItem.
  late StatTickerItemModel statTickerItemModel4;

  @override
  void initState(BuildContext context) {
    statTickerItemModel1 = createModel(context, () => StatTickerItemModel());
    statTickerItemModel2 = createModel(context, () => StatTickerItemModel());
    statTickerItemModel3 = createModel(context, () => StatTickerItemModel());
    statTickerItemModel4 = createModel(context, () => StatTickerItemModel());
  }

  @override
  void dispose() {
    statTickerItemModel1.dispose();
    statTickerItemModel2.dispose();
    statTickerItemModel3.dispose();
    statTickerItemModel4.dispose();
  }
}
