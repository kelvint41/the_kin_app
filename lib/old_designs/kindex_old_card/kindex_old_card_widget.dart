import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'kindex_old_card_model.dart';
export 'kindex_old_card_model.dart';

/// New Component Gen
class KindexOldCardWidget extends StatefulWidget {
  const KindexOldCardWidget({super.key});

  @override
  State<KindexOldCardWidget> createState() => _KindexOldCardWidgetState();
}

class _KindexOldCardWidgetState extends State<KindexOldCardWidget> {
  late KindexOldCardModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => KindexOldCardModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
