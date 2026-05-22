import '/components/form_field_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'customer_sign_up_widget.dart' show CustomerSignUpWidget;
import 'package:flutter/material.dart';

class CustomerSignUpModel extends FlutterFlowModel<CustomerSignUpWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for FormField component.
  late FormFieldModel formFieldModel1;
  // Model for FormField component.
  late FormFieldModel formFieldModel2;
  // Model for FormField component.
  late FormFieldModel formFieldModel3;

  @override
  void initState(BuildContext context) {
    formFieldModel1 = createModel(context, () => FormFieldModel());
    formFieldModel2 = createModel(context, () => FormFieldModel());
    formFieldModel3 = createModel(context, () => FormFieldModel());
  }

  @override
  void dispose() {
    formFieldModel1.dispose();
    formFieldModel2.dispose();
    formFieldModel3.dispose();
  }
}
