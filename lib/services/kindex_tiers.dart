import 'package:flutter/material.dart';

/// A KINdex score tier: a display label and accent color, derived purely
/// from a score - see [kindexTierForScore].
class KindexTier {
  const KindexTier(this.label, this.color);

  final String label;
  final Color color;
}

/// Score-band tiers spanning the documented KINdex range: 300 is the
/// baseline every business/customer starts at, 850 is the cap (see the
/// KINdex scoring rebuild in kindex_scoring_dynamics.js /
/// customer_kindex_nightly.js - frozen pre-launch, so these thresholds are
/// safe to hardcode against the current score distribution).
///
/// Deliberately score-only, not rank-based. KindexSpotlightWidget's top-10
/// podium already answers "am I actually in the top 10" with its own
/// fetchTopBusinessKindex/fetchTopCustomerKindex query; re-running that
/// per post on every feed render (to badge someone "Top 10 Business")
/// would mean a top-10 lookup for every post shown, and would also let a
/// badge lag behind reality between leaderboard refreshes. A tier here is
/// just a threshold check on a score the caller already has in hand.
///
/// Ordered highest-first so [kindexTierForScore] returns on first match.
const _kKindexTiers = <(int min, KindexTier tier)>[
  (810, KindexTier('KINdex Elite', Color(0xFFFFD700))), // gold
  (720, KindexTier('Founding Backer', Color(0xFFC0C0C0))), // silver
  (580, KindexTier('Trusted Neighbor', Color(0xFFCD7F32))), // bronze
  (440, KindexTier('Rising Voice', Color(0xFF6B8F71))), // muted green
];

/// Tier for [score], or null at/below the 300 baseline where a member's
/// score hasn't moved yet - nothing distinguishes a brand-new account at
/// that point, so no badge renders rather than badging every account that
/// hasn't done anything yet the same way as one that has.
KindexTier? kindexTierForScore(double score) {
  for (final (min, tier) in _kKindexTiers) {
    if (score >= min) return tier;
  }
  return null;
}
