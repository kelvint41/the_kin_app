import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'form_section_child_model.dart';
export 'form_section_child_model.dart';

class FormSectionChildWidget extends StatefulWidget {
  const FormSectionChildWidget({super.key});

  @override
  State<FormSectionChildWidget> createState() => _FormSectionChildWidgetState();
}

class _FormSectionChildWidgetState extends State<FormSectionChildWidget> {
  late FormSectionChildModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FormSectionChildModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.0,
      height: 0.0,
    );
  }
}
