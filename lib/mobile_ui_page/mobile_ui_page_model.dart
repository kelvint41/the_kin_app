import '/components/category_chip2_widget.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'mobile_ui_page_widget.dart' show MobileUiPageWidget;
import 'package:flutter/material.dart';

class MobileUiPageModel extends FlutterFlowModel<MobileUiPageWidget> {
  ///  Local state fields for this page.

  String selectedCategory = 'Near Me';

  ///  State fields for stateful widgets in this page.

  // State field(s) for Map Google Map widget.
  LatLng? mapGoogleMapsCenter;
  final mapGoogleMapsController = Completer<GoogleMapController>();
  // Model for CategoryChip.
  late CategoryChip2Model categoryChipModel1;
  // Model for CategoryChip.
  late CategoryChip2Model categoryChipModel2;
  // Model for CategoryChip.
  late CategoryChip2Model categoryChipModel3;
  // Model for CategoryChip.
  late CategoryChip2Model categoryChipModel4;
  // Model for CategoryChip.
  late CategoryChip2Model categoryChipModel5;

  @override
  void initState(BuildContext context) {
    categoryChipModel1 = createModel(context, () => CategoryChip2Model());
    categoryChipModel2 = createModel(context, () => CategoryChip2Model());
    categoryChipModel3 = createModel(context, () => CategoryChip2Model());
    categoryChipModel4 = createModel(context, () => CategoryChip2Model());
    categoryChipModel5 = createModel(context, () => CategoryChip2Model());
  }

  @override
  void dispose() {
    categoryChipModel1.dispose();
    categoryChipModel2.dispose();
    categoryChipModel3.dispose();
    categoryChipModel4.dispose();
    categoryChipModel5.dispose();
  }
}
