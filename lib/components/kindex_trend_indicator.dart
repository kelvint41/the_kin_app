import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

/// The KINDEX score itself, with a slow pulse behind it.
///
/// The score is the app's core trust signal and it read as ordinary body
/// text next to its own label. This gives it a soft halo that breathes -
/// enough to draw the eye on arrival without becoming a flashing element
/// someone has to sit next to.
///
/// Deliberately a two-second ease rather than a flash: rapidly flashing
/// content is an accessibility hazard, and this sits on a profile people
/// read rather than glance at. It also stops after a few cycles - a badge
/// that pulses forever stops meaning anything and just costs battery.
class KindexScoreBadge extends StatefulWidget {
  const KindexScoreBadge({
    super.key,
    required this.score,
    required this.velocity,
  });

  final double score;
  final int velocity;

  @override
  State<KindexScoreBadge> createState() => _KindexScoreBadgeState();
}

class _KindexScoreBadgeState extends State<KindexScoreBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _cycles = 3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _runPulses();
  }

  Future<void> _runPulses() async {
    for (var i = 0; i < _cycles; i++) {
      if (!mounted) return;
      await _controller.forward(from: 0.0);
      if (!mounted) return;
      await _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final gold = theme.accentOnSurface;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999.0),
            color: gold.withValues(alpha: 0.06 + 0.10 * t),
            border: Border.all(
              color: gold.withValues(alpha: 0.25 + 0.45 * t),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: gold.withValues(alpha: 0.28 * t),
                blurRadius: 14.0 * t,
                spreadRadius: 1.0 * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'KINDEX Score',
            style: theme.labelMedium.override(
              font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              color: theme.secondaryText,
              letterSpacing: 0.0,
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 0.0, 0.0),
            child: Text(
              widget.score.round().toString(),
              style: theme.headlineSmall.override(
                font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                color: theme.accentOnSurface,
                letterSpacing: 0.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(6.0, 0.0, 0.0, 0.0),
            child: KindexTrendIndicator(velocity: widget.velocity),
          ),
        ],
      ),
    );
  }
}
