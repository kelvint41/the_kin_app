// Derives the "Personal Milestones" figures on the Directory page
// (lib/pages/customer_profile_page/) from a user's real activity.
//
// Background: the three metric cards used to be literals in the widget -
// '14 🔥', '5 Reviews', 'Top 5%' - so every account saw the same numbers no
// matter what it had actually done. The data to compute them honestly is
// already in Firestore: `activity_logs` carries a timestamped row per user
// action, and `reviews` carries one row per review written.
//
// Everything here is pure: no Firestore, no widgets, no plugins. The page
// fetches the documents and passes their timestamps in.

/// Number of consecutive days, ending today, on which the user did something.
///
/// [timestamps] is every activity time for the user, in any order. [now] is
/// the reference point - passed in rather than read from the clock so this
/// stays deterministic under test.
///
/// The streak is counted in whole local days: several actions on one day
/// count once, and a day with no activity ends the streak. A user who was
/// active yesterday but not yet today keeps their streak - it only breaks
/// once a full day has been missed, which is what makes "don't lose your
/// streak" a fair prompt rather than one that punishes sleeping in.
int supportStreakDays(List<DateTime> timestamps, {required DateTime now}) {
  if (timestamps.isEmpty) return 0;

  final activeDays = timestamps.map(_dayNumber).toSet();
  final today = _dayNumber(now);

  // Anchor on today if there is activity today, otherwise on yesterday. Any
  // older gap means the streak is already over.
  int cursor;
  if (activeDays.contains(today)) {
    cursor = today;
  } else if (activeDays.contains(today - 1)) {
    cursor = today - 1;
  } else {
    return 0;
  }

  var streak = 0;
  while (activeDays.contains(cursor)) {
    streak += 1;
    cursor -= 1;
  }
  return streak;
}

/// Days since the epoch in local time.
///
/// Constructing a fresh local DateTime at midnight (rather than dividing the
/// raw millisecond value) keeps this correct across daylight-saving changes,
/// where a local day is 23 or 25 hours long.
int _dayNumber(DateTime time) {
  final local = time.toLocal();
  return DateTime(local.year, local.month, local.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}

/// Label for the "Milestones Unlocked" card, e.g. "5 Reviews".
///
/// Singular at one, so the card never reads "1 Reviews".
String reviewMilestoneLabel(int reviewCount) {
  if (reviewCount == 1) return '1 Review';
  return '$reviewCount Reviews';
}

/// Countdown shown on a Connection Stream promo card, e.g. "2h 14m".
///
/// Returns null when the promotion has no expiry or has already lapsed - the
/// caller drops those rather than rendering "0h 0m", which reads as a live
/// offer that has in fact ended.
String? countdownLabel(DateTime? expiresAt, {required DateTime now}) {
  if (expiresAt == null) return null;
  final remaining = expiresAt.difference(now);
  if (remaining.isNegative || remaining == Duration.zero) return null;

  final days = remaining.inDays;
  if (days >= 1) {
    final hours = remaining.inHours - days * 24;
    return '${days}d ${hours}h';
  }
  final hours = remaining.inHours;
  final minutes = remaining.inMinutes - hours * 60;
  return '${hours}h ${minutes}m';
}

/// Two-letter monogram for a business, used as the promo card avatar.
///
/// Takes the initials of the first two words so "Estate Coffee Co." reads
/// "EC"; falls back to the first two characters for single-word names.
String businessInitials(String businessName) {
  final words = businessName
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) {
    final word = words.first;
    return (word.length == 1 ? word : word.substring(0, 2)).toUpperCase();
  }
  return '${words[0][0]}${words[1][0]}'.toUpperCase();
}

/// Label for the "Impact Score" card.
///
/// Returns the score itself rather than a percentile. The old 'Top 5%' was a
/// literal, and a real percentile needs the distribution of every user's
/// score - a query this page does not make and should not, since it would
/// have to read the whole KindexScores collection to render one card.
String impactScoreLabel(double? kindexScore) {
  if (kindexScore == null) return '--';
  return kindexScore.round().toString();
}
