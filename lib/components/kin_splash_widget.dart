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
class KinSplashWidget extends StatefulWidget {
  const KinSplashWidget({super.key});

  /// How long the intro animation runs. `main.dart` holds the splash for at
  /// least this long so the animation isn't cut off mid-way.
  static const Duration introDuration = Duration(milliseconds: 1400);

  @override
  State<KinSplashWidget> createState() => _KinSplashWidgetState();
}

class _KinSplashWidgetState extends State<KinSplashWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _glow;
  late final List<Animation<double>> _wordFades;

  bool _honouredReducedMotion = false;

  /// Split into words so they can land one at a time - the tagline is the
  /// part that carries the intro, so it reads better arriving in sequence
  /// than as one block.
  static const List<String> _taglineWords = [
    'Discover.',
    'Support.',
    'Build.',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: KinSplashWidget.introDuration,
    );

    // The logo lands first, then the glow blooms behind it, then the tagline
    // fades up - staggered so it reads as a sequence rather than everything
    // arriving at once.
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.86, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.62, curve: Curves.easeOutBack),
      ),
    );
    _glow = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.30, 1.0, curve: Curves.easeInOut),
    );
    _wordFades = List<Animation<double>>.generate(_taglineWords.length, (i) {
      final start = 0.38 + i * 0.11;
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, start + 0.24, curve: Curves.easeOut),
      );
    });

    _controller.forward();
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
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    // Sized against the narrow edge so the logo stays proportionate on a
    // phone and doesn't balloon on an iPad.
    final logoWidth = (shortestSide * 0.52).clamp(140.0, 300.0);

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
        child: Center(
          child: AnimatedBuilder(
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
                      // Soft gold bloom behind the mark. Opacity is kept low
                      // deliberately - this should read as light coming off
                      // the logo, not as a visible circle.
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < _taglineWords.length; i++) ...[
                        if (i > 0) const SizedBox(width: 9.0),
                        Opacity(
                          opacity: _wordFades[i].value,
                          child: Transform.translate(
                            // Each word rises the last few pixels as it
                            // arrives, so the line assembles rather than
                            // simply appearing.
                            offset: Offset(0.0, 9.0 * (1 - _wordFades[i].value)),
                            child: Text(
                              _taglineWords[i],
                              style: theme.labelMedium.override(
                                // The splash's gradient (line ~120) is a
                                // fixed green-to-near-black literal, not
                                // theme-aware. theme.secondary flips to a
                                // darker gold in light mode (2.63:1 here vs
                                // 4.97:1 in dark), so it doesn't match this
                                // always-dark surface. accent1, already used
                                // for the glow above, is fixed and holds
                                // 5.8:1+ regardless of theme.
                                color: theme.accent1,
                                letterSpacing: 2.2,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
