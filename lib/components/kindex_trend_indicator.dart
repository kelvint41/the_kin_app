import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';

/// The green-up / red-down / flat marker that sits beside a KINDEX score.
///
/// One widget for both sides of the app, because the business profile and
/// the customer profile were showing the same idea two different ways: the
/// business side rendered an arrow only when `kindex_velocity` was
/// non-zero, and the customer side only when `is_trending_up` was
/// non-null. Both therefore showed nothing at all most of the time, and a
/// score with no marker beside it reads as a score that has no trend
/// rather than one whose trend isn't known yet.
///
/// The flat state is the important part. `kindex_velocity` is currently
/// unset on every business in the directory, so a widget that renders only
/// on non-zero would still be invisible everywhere - which is exactly the
/// bug being fixed. Flat says "level" and is honest; it is not a
/// green arrow standing in for missing data.
///
/// This deliberately does not infer direction from the score itself.
/// business_kindex_engine.js declines to write a velocity precisely
/// because a sign-based placeholder "would look more meaningful than it
/// is", and guessing one here would be the same mistake a layer up.
class KindexTrendIndicator extends StatelessWidget {
  /// From a business's `kindex_velocity`.
  const KindexTrendIndicator({super.key, required int velocity})
      : _up = velocity > 0,
        _down = velocity < 0,
        size = 20.0;

  /// From a customer's `KindexScores.is_trending_up`, which is a nullable
  /// bool rather than a magnitude - null means no score row yet.
  const KindexTrendIndicator.fromTrend({
    super.key,
    required bool? isTrendingUp,
    this.size = 20.0,
  })  : _up = isTrendingUp == true,
        _down = isTrendingUp == false;

  final bool _up;
  final bool _down;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    late final IconData icon;
    late final Color color;
    late final String label;

    if (_up) {
      icon = Icons.arrow_upward_rounded;
      // Not theme.success/primary - the brand green is dark enough to
      // disappear against the dark profile header this sits on.
      color = const Color(0xFF2ECC71);
      label = 'Trending up';
    } else if (_down) {
      icon = Icons.arrow_downward_rounded;
      color = theme.error;
      label = 'Trending down';
    } else {
      icon = Icons.trending_flat_rounded;
      color = theme.secondaryText;
      label = 'No change yet';
    }

    return Semantics(
      label: label,
      child: Icon(icon, color: color, size: size),
    );
  }
}
