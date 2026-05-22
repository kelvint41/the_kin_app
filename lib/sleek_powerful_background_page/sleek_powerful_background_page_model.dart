import '/components/stat_ticker_item_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'sleek_powerful_background_page_widget.dart'
    show SleekPowerfulBackgroundPageWidget;
import 'package:flutter/material.dart';

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
