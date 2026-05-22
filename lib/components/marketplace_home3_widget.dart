import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'marketplace_home3_model.dart';
export 'marketplace_home3_model.dart';

/// "On the MarketplaceHome_Premium page, I have a ListView of businesses.
///
/// Create an Action for the business card container: On Tap, Navigate to
/// VIPShowcase. For the parameter activeBusiness, pass the businesses Item
/// document. Set the transition to Slide Up at 400ms. Ensure the ListView has
/// a Backend Query filtering for city == 'San Antonio' and is_black_owned ==
/// 'True'."
class MarketplaceHome3Widget extends StatefulWidget {
  const MarketplaceHome3Widget({super.key});

  static String routeName = 'MarketplaceHome3';
  static String routePath = '/marketplaceHome3';

  @override
  State<MarketplaceHome3Widget> createState() => _MarketplaceHome3WidgetState();
}

class _MarketplaceHome3WidgetState extends State<MarketplaceHome3Widget> {
  late MarketplaceHome3Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MarketplaceHome3Model());

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
