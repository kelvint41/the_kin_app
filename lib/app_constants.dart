import 'package:flutter/material.dart';
import 'flutter_flow/flutter_flow_util.dart';

abstract class FFAppConstants {
  static const String SanAntonio = 'San Antonio';

  // V1 store release: community features (The Exchange, Community Prestige
  // feed) are hidden from navigation so we can ship the core MVP quickly.
  // Flip to true to re-enable every gated nav entry in a later update.
  static const bool communityFeaturesEnabled = false;
}
