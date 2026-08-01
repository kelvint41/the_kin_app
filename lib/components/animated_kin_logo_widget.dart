import 'dart:math' as math;

import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';

/// The KIN mark with continuous motion, for screens where it's the hero
/// rather than a passing splash.
///
/// Three things run at once, deliberately slow so it reads as premium
/// rather than busy:
///
///   - a breathe, scaling a couple of percent either side of rest
///   - a gold bloom behind the mark, pulsing against the breathe so the
///     logo appears to sit in its own light
///   - a highlight that sweeps across the gold every few seconds, with a
///     long pause between passes - this is the part that catches the eye,
///     and it only works because it's occasional
///
/// The artwork is untouched; everything here is composited over it.
///
/// Distinct from [KinSplashWidget], which plays once and hands off. This
/// one loops for as long as the screen is up.
class AnimatedKinLogo extends StatefulWidget {
  const AnimatedKinLogo({
    super.key,
    this.size = 200.0,
    this.asset = 'assets/images/kin_logo.png',
  });

  final double size;
  final String asset;

  @override
  State<AnimatedKinLogo> createState() => _AnimatedKinLogoState();
}

class _AnimatedKinLogoState extends State<AnimatedKinLogo>
    with TickerProviderStateMixin {
  // Separate controllers so the sweep can stay rare while the breathe stays
  // continuous - one controller would force them onto the same period.
  late final AnimationController _breathe;
  late final AnimationController _sweep;

  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honour the OS setting: hold a still frame rather than looping.
    final disable = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disable && !_reducedMotion) {
      _reducedMotion = true;
      _breathe.stop();
      _sweep.stop();
      _breathe.value = 0.5;
      _sweep.value = 0.0;
    }
  }

  @override
  void dispose() {
    _breathe.dispose();
    _sweep.dispose();
    super.dispose();
  }

  /// Where the highlight sits, as a fraction of the way across.
  ///
  /// The sweep occupies only the first third of the cycle; the rest is dead
  /// time. A highlight crossing continuously reads as a glitch, whereas one
  /// that arrives now and then reads as light catching the metal.
  double? _sweepPosition() {
    const activeFraction = 0.34;
    final t = _sweep.value;
    if (t > activeFraction) return null;
    return t / activeFraction;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breathe, _sweep]),
        builder: (context, _) {
          // Sine rather than the raw controller value so the turn at each
          // end is smooth instead of a visible bounce.
          final breath = math.sin(_breathe.value * math.pi);
          final scale = 1.0 + 0.035 * breath;
          final glow = 0.30 + 0.30 * breath;
          final sweepAt = _sweepPosition();

          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.size * (0.82 + 0.10 * breath),
                height: widget.size * (0.82 + 0.10 * breath),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.accent1.withValues(alpha: glow * 0.55),
                      theme.accent1.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              Transform.scale(
                scale: scale,
                child: sweepAt == null
                    ? Image.asset(widget.asset,
                        width: widget.size, fit: BoxFit.contain)
                    : ShaderMask(
                        // srcATop keeps the highlight inside the mark's own
                        // opaque pixels, so it never bleeds onto the
                        // background as a rectangle.
                        blendMode: BlendMode.srcATop,
                        shaderCallback: (bounds) {
                          final x = -1.0 + 2.6 * sweepAt;
                          return LinearGradient(
                            begin: Alignment(x - 0.45, -1.0),
                            end: Alignment(x + 0.45, 1.0),
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.42),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ).createShader(bounds);
                        },
                        child: Image.asset(widget.asset,
                            width: widget.size, fit: BoxFit.contain),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
