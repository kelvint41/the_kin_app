import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'k_i_n_v_i_p_final_model.dart';
export 'k_i_n_v_i_p_final_model.dart';

/// "I have renamed the destination page to VIPShowcase_Final.
///
/// Please update the 'On Tap' action on the business cards in
/// MarketplaceHome_Premium to navigate to VIPShowcase_Final. Ensure it still
/// passes the businesses Item as the activeBusiness parameter."
class KINVIPFinalWidget extends StatefulWidget {
  const KINVIPFinalWidget({super.key});

  static String routeName = 'KIN_VIP_Final';
  static String routePath = '/kINVIPFinal';

  @override
  State<KINVIPFinalWidget> createState() => _KINVIPFinalWidgetState();
}

class _KINVIPFinalWidgetState extends State<KINVIPFinalWidget> {
  late KINVIPFinalModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => KINVIPFinalModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
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
