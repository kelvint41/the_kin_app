import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';

/// The app's launch screen.
///
/// Replaces what was a bare full-screen `Image.asset` on a
/// `Colors.transparent` container in `createRouter` - which had no brand
/// colour behind it, and, being `BoxFit.contain` inside a full-screen box,
/// scaled the logo edge-to-edge on tall devices.
///
/// Unlike the rest of the app this deliberately commits to one look rather
/// than following the light/dark tokens: a launch screen is brand, and the
/// gold logo needs a deep backdrop to read against in either mode. The
/// colours are still taken from the theme's own palette (`primary` and
/// `primaryBackground` from the dark theme) rather than invented here.
///
/// Rendered while `AppStateNotifier.loading` is true, so it is rebuilt on
/// every route build during startup - the animation is driven by this
/// widget's own controller, not by anything in the router.
///
/// Sequence (see `_KinSplashWidgetState.initState` for exact intervals): a
/// faint radar grid + slowly rotating sweep line establish the KIN Quest
/// map theme as a continuous backdrop (its own looping controller, since it
/// keeps going for as long as the splash is on screen rather than
/// finishing once); the mark blooms in behind a soft gold glow; "The KIN
/// App" fades up as a single wordmark rather than word-by-word; and a thin
/// gold rule draws itself left-to-right underneath, closing the sequence -
/// no locale tag under the rule any more (this used to read "SAN ANTONIO",
/// dropped so the brand moment doesn't read as market-specific). Once that
/// sequence finishes, a "Tap to enter" pill fades in and gently pulses - the splash
/// then holds (tap anywhere to continue immediately) rather than
/// auto-dismissing right away, so the logo actually gets seen rather than
/// flashing past. [onContinue] is called either on that tap or, if nobody
/// taps, automatically after [maxAutoContinueDuration] so no one gets
/// stuck on it.
class KinSplashWidget extends StatefulWidget {
  const KinSplashWidget({super.key, this.onContinue});

  /// Called once, either when the user taps the splash or when
  /// [maxAutoContinueDuration] elapses without a tap - whichever comes
  /// first. `nav.dart` wires this to `AppStateNotifier.stopShowingSplashImage`
  /// for the real launch splash. Left null for the other call site
  /// (`kin_quest_map_page.dart`'s `FutureBuilder` loading placeholder),
  /// which has nothing to dismiss and shouldn't show the CTA or hold at
  /// all - that use just wants the reveal animation as a loading visual.
  final VoidCallback? onContinue;

  /// How long the intro animation runs before the "Tap to enter" CTA
  /// appears. Widened from the original 1400ms to fit the wordmark,
  /// rule-draw, and locale-tag beats added after the mark without rushing
  /// any of them.
  static const Duration introDuration = Duration(milliseconds: 2000);

  /// Absolute cap on how long the splash waits for a tap before calling
  /// [onContinue] on its own. Measured from mount, not from when the CTA
  /// appears - so this is roughly introDuration + 6s of actual dwell time
  /// with the CTA visible. Generous on purpose: the whole point of this
  /// screen is letting people actually see the logo (it's a marketing
  /// moment, not just a loading gate), so someone who doesn't tap right
  /// away shouldn't get cut off early - but it still needs a ceiling so a
  /// user who never taps isn't stuck.
  static const Duration maxAutoContinueDuration = Duration(milliseconds: 8000);

  @override
  State<KinSplashWidget> createState() => _KinSplashWidgetState();
}

class _KinSplashWidgetState extends State<KinSplashWidget>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _glow;
  late final Animation<double> _wordmarkFade;
  late final Animation<double> _ruleWidth;

  /// Drives the background radar grid's sweep line. Separate from
  /// [_controller] and left `repeat()`-ing for as long as the splash is
  /// mounted, rather than a single pass tied to the intro timeline - it's
  /// ambient atmosphere, not a beat in the reveal sequence, so it keeps
  /// turning even after the wordmark/rule have landed.
  late final AnimationController _ambientController;

  /// Drives the "Tap to enter" pill's gentle breathing pulse once it's
  /// visible. Separate from [_controller] for the same reason
  /// [_ambientController] is - it starts only after the reveal sequence
  /// finishes and then loops indefinitely, rather than running once on a
  /// fixed timeline.
  late final AnimationController _ctaPulseController;
  late final Animation<double> _ctaPulseScale;

  bool _honouredReducedMotion = false;
  bool _showCta = false;
  Timer? _autoContinueTimer;

  static const double _ruleWidthMax = 64.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: KinSplashWidget.introDuration,
    );
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
    _ctaPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _ctaPulseScale = Tween<double>(begin: 1.0, end: 1.045).animate(
      CurvedAnimation(parent: _ctaPulseController, curve: Curves.easeInOut),
    );

    // Mark + glow land first, same shape as before: fade slightly ahead of
    // the scale so the overshoot on the scale curve doesn't look like a
    // bounce on a still-transparent logo.
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.40, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.86, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.50, curve: Curves.easeOutBack),
      ),
    );
    _glow = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.20, 1.0, curve: Curves.easeInOut),
    );

    // One wordmark fade instead of the old per-word stagger - "The KIN App"
    // arrives as a single logotype moment rather than assembling itself.
    _wordmarkFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.30, 0.575, curve: Curves.easeOut),
    );
    // Slightly overlapping the wordmark interval rather than starting
    // right as it ends (0.575 -> 0.55 start) so the beat begins while the
    // last is still settling - a continuous flow instead of a dead stop,
    // matching the approved mockup's pacing.
    _ruleWidth = Tween<double>(begin: 0.0, end: _ruleWidthMax).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.80, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // The CTA only matters when there's actually something to dismiss -
    // see the onContinue doc comment for why the loading-placeholder call
    // site leaves it null and gets none of this.
    if (widget.onContinue != null) {
      Future.delayed(KinSplashWidget.introDuration, () {
        if (!mounted) return;
        setState(() => _showCta = true);
        if (!_honouredReducedMotion) {
          _ctaPulseController.repeat(reverse: true);
        }
      });
      _autoContinueTimer = Timer(
        KinSplashWidget.maxAutoContinueDuration,
        () => widget.onContinue?.call(),
      );
    }
  }

  void _handleContinue() {
    if (widget.onContinue == null) return;
    _autoContinueTimer?.cancel();
    widget.onContinue!();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Someone who has asked the OS to reduce motion gets the finished frame
    // rather than the animation. Read here rather than in initState because
    // MediaQuery isn't available that early.
    if (!_honouredReducedMotion &&
        MediaQuery.maybeOf(context)?.disableAnimations == true) {
      _honouredReducedMotion = true;
      _controller.value = 1.0;
      // The rotating sweep line is the one piece of this screen that would
      // otherwise animate indefinitely regardless of the reduced-motion
      // check above (it isn't driven by _controller at all) - stop it
      // rather than just freezing its current angle, and skip drawing it
      // entirely in build below. The static rings stay: they're plain
      // decoration, not motion.
      _ambientController.stop();
    }
  }

  @override
  void dispose() {
    _autoContinueTimer?.cancel();
    _controller.dispose();
    _ambientController.dispose();
    _ctaPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    // Sized against the narrow edge so the logo stays proportionate on a
    // phone and doesn't balloon on an iPad.
    final logoWidth = (shortestSide * 0.52).clamp(140.0, 300.0);
    final radarDiameter = logoWidth * 2.2;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0B3D2E), // primary - dark forest green
            Color(0xFF121212), // primaryBackground - near black
          ],
          stops: [0.0, 0.72],
        ),
      ),
      // Without a Material ancestor, Text falls back to the default style
      // and picks up the debug underline - the splash sits outside any
      // Scaffold, so it has to supply one itself.
      child: Material(
        color: Colors.transparent,
        // Tap anywhere to continue immediately, not just the CTA pill -
        // more forgiving than requiring a precise tap, and standard splash
        // UX (someone who's seen this before shouldn't have to wait for
        // the pill to even appear). A no-op when onContinue is null (the
        // loading-placeholder call site).
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleContinue,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Radar grid backdrop - establishes the KIN Quest map theme
              // immediately, before the mark has even faded in. Kept at very
              // low opacity throughout so it reads as ambient texture behind
              // the logotype, never competing with it for attention.
              IgnorePointer(
                child: SizedBox(
                  width: radarDiameter,
                  height: radarDiameter,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (final fraction in const [1.0, 0.66, 0.33])
                        Container(
                          width: radarDiameter * fraction,
                          height: radarDiameter * fraction,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.accent1.withValues(alpha: 0.14),
                              width: 1.0,
                            ),
                          ),
                        ),
                      if (!_honouredReducedMotion)
                        AnimatedBuilder(
                          animation: _ambientController,
                          builder: (context, _) {
                            return Transform.rotate(
                              angle: _ambientController.value * 2 * math.pi,
                              child: Align(
                                alignment: Alignment.center,
                                child: Container(
                                  width: radarDiameter / 2,
                                  height: 1.0,
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    width: radarDiameter / 2,
                                    height: 1.0,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.accent1.withValues(alpha: 0.35),
                                          theme.accent1.withValues(alpha: 0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: logoWidth,
                        height: logoWidth,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Soft gold bloom behind the mark. Opacity is kept
                            // low deliberately - this should read as light
                            // coming off the logo, not as a visible circle.
                            Opacity(
                              opacity: _glow.value * 0.55,
                              child: Container(
                                width: logoWidth * (0.75 + 0.35 * _glow.value),
                                height: logoWidth * (0.75 + 0.35 * _glow.value),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      theme.accent1.withValues(alpha: 0.42),
                                      theme.accent1.withValues(alpha: 0.0),
                                    ],
                                    stops: const [0.0, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            Opacity(
                              opacity: _logoFade.value,
                              child: Transform.scale(
                                scale: _logoScale.value,
                                child: Image.asset(
                                  'assets/images/kin_logo.png',
                                  width: logoWidth,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 22.0),
                        child: Opacity(
                          opacity: _wordmarkFade.value,
                          child: Transform.translate(
                            offset:
                                Offset(0.0, 9.0 * (1 - _wordmarkFade.value)),
                            child: Text(
                              'The KIN App',
                              style: theme.headlineSmall.override(
                                // Fixed, not theme-aware - see the class doc
                                // comment: this surface always renders the
                                // same dark gradient regardless of the app's
                                // light/dark setting, so accent1 (identical
                                // in both theme classes) is used directly
                                // rather than a token that would otherwise
                                // flip underneath it.
                                color: theme.accent1,
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 14.0),
                        child: Container(
                          width: _ruleWidth.value,
                          height: 1.0,
                          color: theme.accent1,
                        ),
                      ),
                      // Fades in once the reveal sequence above finishes (see
                      // the Future.delayed in initState), then pulses gently
                      // to invite a tap - the splash holds here rather than
                      // dismissing itself, see the class doc comment. Hidden
                      // entirely (AnimatedOpacity to 0, not built
                      // conditionally) so its layout space is reserved from
                      // the start and nothing else in the column shifts when
                      // it appears.
                      Padding(
                        padding: const EdgeInsets.only(top: 40.0),
                        child: AnimatedOpacity(
                          opacity: _showCta ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 400),
                          child: ScaleTransition(
                            scale: _ctaPulseScale,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28.0, vertical: 12.0),
                              decoration: BoxDecoration(
                                color: theme.accent1,
                                borderRadius: BorderRadius.circular(999.0),
                              ),
                              child: Text(
                                'Tap to enter',
                                style: theme.labelMedium.override(
                                  // Dark green rather than white/cream - this
                                  // sits on solid gold, not the dark
                                  // backdrop, so it needs a dark foreground
                                  // to read (same primary green as the
                                  // gradient's own top stop, for a colour
                                  // already established elsewhere on this
                                  // screen rather than a new one).
                                  color: const Color(0xFF0B3D2E),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
