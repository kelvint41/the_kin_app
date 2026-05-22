import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'form_section_child3_model.dart';
export 'form_section_child3_model.dart';

class FormSectionChild3Widget extends StatefulWidget {
  const FormSectionChild3Widget({super.key});

  @override
  State<FormSectionChild3Widget> createState() =>
      _FormSectionChild3WidgetState();
}

class _FormSectionChild3WidgetState extends State<FormSectionChild3Widget> {
  late FormSectionChild3Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FormSectionChild3Model());

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
      constraints: BoxConstraints(
        minHeight: 120.0,
      ),
      child: Container(
        width: 0.0,
        height: 0.0,
      ),
    );
  }
}
