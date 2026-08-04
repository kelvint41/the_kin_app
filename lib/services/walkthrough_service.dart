import '/backend/backend.dart';

/// One coach-mark step, parsed from an onboarding_walkthroughs/{key} doc's
/// steps array. targetId is matched against a GlobalKey the showing screen
/// registers for that on-screen element - see WalkthroughRunner.
class WalkthroughStep {
  const WalkthroughStep({
    required this.targetId,
    required this.title,
    required this.body,
  });

  final String targetId;
  final String title;
  final String body;
}

/// Firestore I/O for onboarding walkthroughs - loading a walkthrough's
/// steps and tracking which ones a user has already been shown. Screen
/// wiring (which GlobalKey a target_id maps to, when to trigger) lives in
/// WalkthroughRunner instead, since that part is inherently per-screen.
class WalkthroughService {
  WalkthroughService._();

  /// Steps for [key] (an onboarding_walkthroughs doc id, e.g.
  /// 'general_tour'), in the order Firestore returned the array - empty
  /// if the doc doesn't exist, has no steps, is explicitly disabled, or
  /// the read fails. Never throws: a broken/missing walkthrough doc
  /// should mean "don't show anything," not a crashed screen.
  static Future<List<WalkthroughStep>> loadSteps(String key) async {
    try {
      final doc = await OnboardingWalkthroughsRecord.collection.doc(key).get();
      if (!doc.exists) return const [];
      final record = OnboardingWalkthroughsRecord.fromSnapshot(doc);
      if (!record.enabled) return const [];
      return record.steps
          .map((step) => WalkthroughStep(
                targetId: (step['target_id'] as String?) ?? '',
                title: (step['title'] as String?) ?? '',
                body: (step['body'] as String?) ?? '',
              ))
          .where((step) => step.targetId.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Whether [seenWalkthroughs] (a user's UsersRecord.seenWalkthroughs)
  /// already includes [key] - a plain list check, kept as a named method
  /// so callers read as intent ("has this user seen X") rather than a
  /// bare .contains() at every call site.
  static bool hasSeen(List<String> seenWalkthroughs, String key) =>
      seenWalkthroughs.contains(key);

  /// Records that the signed-in user has completed or dismissed [key], so
  /// it never auto-starts again. Fire-and-forget by design (callers wrap
  /// this in `unawaited`) - by the time this runs the walkthrough has
  /// already finished on screen, so a write failure here shouldn't block
  /// or retry against the user's flow, just mean it might show once more
  /// next time.
  static Future<void> markSeen(DocumentReference userRef, String key) async {
    try {
      await userRef.update({
        'seen_walkthroughs': FieldValue.arrayUnion([key]),
      });
    } catch (_) {
      // Best-effort - see doc comment above.
    }
  }
}
