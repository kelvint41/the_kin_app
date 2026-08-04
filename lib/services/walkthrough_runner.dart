import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '/backend/backend.dart';
import 'walkthrough_service.dart';

/// Wraps the ShowcaseView register/start/unregister lifecycle for one
/// walkthrough on one screen, so a screen only has to: create one per
/// State, register its own GlobalKeys against the walkthrough's
/// target_ids, call maybeStart() after first frame (or in didChangeDeps/
/// a stream callback once user data is available), and call dispose() in
/// its own dispose().
class WalkthroughRunner {
  WalkthroughRunner({required this.walkthroughKey, required this.targetKeys});

  /// Firestore doc id under onboarding_walkthroughs/{key} - also used as
  /// the ShowcaseView scope name, so there's exactly one string per
  /// walkthrough to keep in sync rather than two.
  final String walkthroughKey;

  /// target_id (from the loaded steps) -> the GlobalKey the calling
  /// screen registered for that on-screen element. A loaded step whose
  /// target_id has no entry here is skipped - lets a screen ship partial
  /// anchor coverage without every Firestore step needing one yet.
  final Map<String, GlobalKey> targetKeys;

  List<WalkthroughStep> _steps = const [];
  bool _registered = false;

  /// Title/body for [targetId] from the loaded steps, or null if that
  /// step wasn't loaded (not present in Firestore, or the walkthrough was
  /// already seen and never loaded at all - the common case, since most
  /// visits after the first shouldn't load anything).
  WalkthroughStep? stepFor(String targetId) {
    for (final step in _steps) {
      if (step.targetId == targetId) return step;
    }
    return null;
  }

  /// Loads steps and starts the showcase if [seenWalkthroughs] doesn't
  /// already include this walkthrough's key. No-op if already seen, the
  /// load comes back empty (missing/disabled doc, or a failed read), or
  /// none of the loaded steps' target_ids match [targetKeys] (nothing on
  /// this screen ready to point at yet).
  Future<void> maybeStart({
    required BuildContext context,
    required DocumentReference? userRef,
    required List<String> seenWalkthroughs,
  }) async {
    if (userRef == null) return;
    if (WalkthroughService.hasSeen(seenWalkthroughs, walkthroughKey)) return;

    final loadedSteps = await WalkthroughService.loadSteps(walkthroughKey);
    final orderedKeys = <GlobalKey>[
      for (final step in loadedSteps)
        if (targetKeys[step.targetId] != null) targetKeys[step.targetId]!,
    ];
    if (orderedKeys.isEmpty) return;

    _steps = loadedSteps;
    ShowcaseView.register(
      scope: walkthroughKey,
      onFinish: () => WalkthroughService.markSeen(userRef, walkthroughKey),
      onDismiss: (_) => WalkthroughService.markSeen(userRef, walkthroughKey),
    );
    _registered = true;

    if (!context.mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_registered) {
        ShowcaseView.getNamed(walkthroughKey).startShowCase(orderedKeys);
      }
    });
  }

  /// Unregisters the ShowcaseView scope, if maybeStart ever actually
  /// registered one. Safe to call unconditionally from a State's
  /// dispose() even when the walkthrough never ran (already seen, no
  /// matching targets, load failed) - ShowcaseView.getNamed() throws for
  /// a scope that was never registered, which is exactly the case
  /// [_registered] exists to guard against.
  void dispose() {
    if (!_registered) return;
    ShowcaseView.getNamed(walkthroughKey).unregister();
    _registered = false;
  }
}
