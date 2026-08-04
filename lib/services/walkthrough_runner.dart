import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '/backend/backend.dart';
import 'walkthrough_service.dart';

/// Wraps the ShowcaseView register/start/unregister lifecycle for one
/// walkthrough on one screen, so a screen only has to: construct one per
/// State *during initState* (not lazily via a `late final` field only
/// touched inside a post-frame callback - see the constructor's doc
/// comment for why that distinction matters), register its own GlobalKeys
/// against the walkthrough's target_ids, pass [scope] to every `Showcase`
/// widget using this runner's key, call maybeStart() after first frame,
/// and call dispose() in its own dispose().
class WalkthroughRunner {
  /// Registers a ShowcaseView for [walkthroughKey] immediately, in the
  /// constructor - not deferred to maybeStart() or a post-frame callback.
  ///
  /// `Showcase` widgets look up their scope's registered ShowcaseView
  /// synchronously in their own `initState`, and throw
  /// ("No ShowcaseView is registered...") if it isn't there yet. Since
  /// every target this runner covers is wrapped in `Showcase` unconditionally
  /// (whether or not the walkthrough ever actually plays - most visits it
  /// won't, because the user has already seen it), registration has to be
  /// unconditional and synchronous too. Building this runner as a `late
  /// final` field only ever touched inside a post-frame callback silently
  /// defers the constructor - and this registration - to that same
  /// deferred point, which is exactly what caused the crash: construct it
  /// as a plain assignment in initState() instead, before returning to
  /// the framework for the first build.
  WalkthroughRunner({required this.walkthroughKey, required this.targetKeys}) {
    ShowcaseView.register(
      scope: walkthroughKey,
      onFinish: _handleFinishedOrDismissed,
      onDismiss: (_) => _handleFinishedOrDismissed(),
    );
  }

  /// Firestore doc id under onboarding_walkthroughs/{key} - also used as
  /// the ShowcaseView scope name (pass this to every `Showcase(scope: ...)`
  /// using this runner), so there's exactly one string per walkthrough to
  /// keep in sync rather than two.
  final String walkthroughKey;

  /// target_id (from the loaded steps) -> the GlobalKey the calling
  /// screen registered for that on-screen element. A loaded step whose
  /// target_id has no entry here is skipped - lets a screen ship partial
  /// anchor coverage without every Firestore step needing one yet.
  final Map<String, GlobalKey> targetKeys;

  List<WalkthroughStep> _steps = const [];
  DocumentReference? _userRef;

  void _handleFinishedOrDismissed() {
    final userRef = _userRef;
    if (userRef != null) {
      WalkthroughService.markSeen(userRef, walkthroughKey);
    }
  }

  /// Title/body for [targetId] from the loaded steps, or null if that
  /// step wasn't loaded (not present in Firestore, or the walkthrough was
  /// already seen and never loaded at all - the common case, since most
  /// visits after the first shouldn't load anything). Callers should pass
  /// their own fallback copy for the case this returns null, since a
  /// `Showcase` still needs *some* title/description even when it will
  /// never actually be shown.
  WalkthroughStep? stepFor(String targetId) {
    for (final step in _steps) {
      if (step.targetId == targetId) return step;
    }
    return null;
  }

  /// Loads steps and starts the showcase if [seenWalkthroughs] doesn't
  /// already include this walkthrough's key. No-op (steps stays empty,
  /// nothing shown) if already seen, the load comes back empty (missing/
  /// disabled doc, or a failed read), or none of the loaded steps'
  /// target_ids match [targetKeys] (nothing on this screen ready to point
  /// at yet).
  ///
  /// [onStepsLoaded] fires once real copy has loaded, before the showcase
  /// starts - callers should use it to trigger a rebuild (e.g.
  /// `safeSetState(() {})`) so their `Showcase` widgets pick up
  /// [stepFor]'s real title/body instead of whatever fallback text they
  /// were built with on the first frame.
  Future<void> maybeStart({
    required BuildContext context,
    required DocumentReference? userRef,
    required List<String> seenWalkthroughs,
    VoidCallback? onStepsLoaded,
  }) async {
    _userRef = userRef;
    if (userRef == null) return;
    if (WalkthroughService.hasSeen(seenWalkthroughs, walkthroughKey)) return;

    final loadedSteps = await WalkthroughService.loadSteps(walkthroughKey);
    final orderedKeys = <GlobalKey>[
      for (final step in loadedSteps)
        if (targetKeys[step.targetId] != null) targetKeys[step.targetId]!,
    ];
    if (orderedKeys.isEmpty) return;

    _steps = loadedSteps;
    onStepsLoaded?.call();

    if (!context.mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Re-checked here, not just above: dispose() (which unregisters this
      // scope) can run in the gap between scheduling this callback and it
      // actually firing if the screen is popped fast enough. Calling
      // ShowcaseView.getNamed() for an unregistered scope throws, so this
      // guards the exact race that produced the original crash, just at a
      // different point in the timeline.
      if (!context.mounted) return;
      ShowcaseView.getNamed(walkthroughKey).startShowCase(orderedKeys);
    });
  }

  /// Unregisters this runner's ShowcaseView scope. Always safe to call
  /// from a State's dispose() - the constructor always registers, so
  /// there's no "was it ever registered" case to guard here the way an
  /// earlier version of this class needed to.
  void dispose() {
    ShowcaseView.getNamed(walkthroughKey).unregister();
  }
}
