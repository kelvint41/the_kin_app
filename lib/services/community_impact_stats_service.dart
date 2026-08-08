import 'package:cloud_firestore/cloud_firestore.dart';

/// One city or category's slice of community-wide spend, already joined
/// to its display label and sorted for ranked display.
class RankedTotal {
  const RankedTotal(this.label, this.total);
  final String label;
  final double total;
}

class CommunityImpactAggregate {
  const CommunityImpactAggregate({
    required this.totalSpend,
    required this.totalEntries,
    required this.topCities,
    required this.topCategories,
  });

  static const empty = CommunityImpactAggregate(
    totalSpend: 0,
    totalEntries: 0,
    topCities: [],
    topCategories: [],
  );

  final double totalSpend;
  final int totalEntries;
  final List<RankedTotal> topCities;
  final List<RankedTotal> topCategories;
}

/// Reads `community_impact_stats/aggregate` - the one place community-wide
/// spend data is readable from. Never reads `spend_logs` itself, which
/// firestore.rules keeps strictly owner-only; this doc is maintained
/// server-side by spend_log_aggregate.js's onCreate/onDelete triggers on
/// that collection instead. See that rules file's comment on `spend_logs`
/// for the product decision behind the split.
///
/// Shared by [AdminCommunityImpactMetricsCard] and the investor PDF export
/// so both read the exact same numbers the exact same way.
Future<CommunityImpactAggregate> fetchCommunityImpactAggregate({
  int topN = 5,
}) async {
  final snap = await FirebaseFirestore.instance
      .collection('community_impact_stats')
      .doc('aggregate')
      .get();
  final data = snap.data();
  if (data == null) return CommunityImpactAggregate.empty;

  List<RankedTotal> topEntries(String totalsKey, String labelsKey) {
    final totals = data[totalsKey] as Map<String, dynamic>?;
    final labels = data[labelsKey] as Map<String, dynamic>?;
    if (totals == null || totals.isEmpty) return const [];
    final entries = totals.entries
        .map((e) => RankedTotal(
              (labels?[e.key] as String?) ?? e.key,
              (e.value as num).toDouble(),
            ))
        .where((e) => e.total > 0)
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return entries.take(topN).toList();
  }

  return CommunityImpactAggregate(
    totalSpend: (data['total_spend'] as num?)?.toDouble() ?? 0,
    totalEntries: (data['total_entries'] as num?)?.toInt() ?? 0,
    topCities: topEntries('city_totals', 'city_labels'),
    topCategories: topEntries('category_totals', 'category_labels'),
  );
}
