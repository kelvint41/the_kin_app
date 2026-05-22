import '/components/black_owned_badge_widget.dart';
import '/components/cat_chip2_widget.dart';
import '/components/custom_verified_badge_mini_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'verified_badge_component_widget.dart' show VerifiedBadgeComponentWidget;
import 'package:flutter/material.dart';

class VerifiedBadgeComponentModel
    extends FlutterFlowModel<VerifiedBadgeComponentWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Model for CatChip2 component.
  late CatChip2Model catChip2Model1;
  // Model for CatChip2 component.
  late CatChip2Model catChip2Model2;
  // Model for CatChip2 component.
  late CatChip2Model catChip2Model3;
  // Model for CatChip2 component.
  late CatChip2Model catChip2Model4;
  // Model for CatChip2 component.
  late CatChip2Model catChip2Model5;
  // Model for CustomVerifiedBadgeMini component.
  late CustomVerifiedBadgeMiniModel customVerifiedBadgeMiniModel1;
  // Model for BlackOwnedBadge component.
  late BlackOwnedBadgeModel blackOwnedBadgeModel1;
  // Model for CustomVerifiedBadgeMini component.
  late CustomVerifiedBadgeMiniModel customVerifiedBadgeMiniModel2;
  // Model for BlackOwnedBadge component.
  late BlackOwnedBadgeModel blackOwnedBadgeModel2;

  @override
  void initState(BuildContext context) {
    catChip2Model1 = createModel(context, () => CatChip2Model());
    catChip2Model2 = createModel(context, () => CatChip2Model());
    catChip2Model3 = createModel(context, () => CatChip2Model());
    catChip2Model4 = createModel(context, () => CatChip2Model());
    catChip2Model5 = createModel(context, () => CatChip2Model());
    customVerifiedBadgeMiniModel1 =
        createModel(context, () => CustomVerifiedBadgeMiniModel());
    blackOwnedBadgeModel1 = createModel(context, () => BlackOwnedBadgeModel());
    customVerifiedBadgeMiniModel2 =
        createModel(context, () => CustomVerifiedBadgeMiniModel());
    blackOwnedBadgeModel2 = createModel(context, () => BlackOwnedBadgeModel());
  }

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();

    catChip2Model1.dispose();
    catChip2Model2.dispose();
    catChip2Model3.dispose();
    catChip2Model4.dispose();
    catChip2Model5.dispose();
    customVerifiedBadgeMiniModel1.dispose();
    blackOwnedBadgeModel1.dispose();
    customVerifiedBadgeMiniModel2.dispose();
    blackOwnedBadgeModel2.dispose();
  }
}
