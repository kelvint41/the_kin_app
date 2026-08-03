import '/backend/backend.dart';
import 'business_visibility.dart';

/// Which businesses may appear in the KIN Quest.
///
/// The Quest is a check-in game: you earn points by physically showing up.
/// That premise doesn't hold for service-area businesses - home care, HCS,
/// non-emergency medical transport - where the work happens at the client's
/// home and nobody ever visits the office. Those businesses should still be
/// listed, searchable, and on the Job Board; they just shouldn't be a Quest
/// stop.
///
/// Before this existed, [selectNearby] picked purely by distance, so any
/// listed business with coordinates was automatically a Quest target and
/// there was no way to express the exclusion at all.
///
/// The flag lives on `business_categories.quest_eligible` rather than on
/// each business: this is a property of the kind of business, so a new home
/// care agency inherits it on signup instead of needing someone to remember
/// to tick a box.
class QuestEligibility {
  /// Display names of categories opted out of the Quest, lowercased for
  /// comparison (businesses store the category's display name as a string).
  ///
  /// Absent flag means eligible - see BusinessCategoriesRecord.questEligible -
  /// so this only ever contains categories explicitly set to false.
  static Future<Set<String>> excludedCategoryNames() async {
    final categories = await queryBusinessCategoriesRecordOnce();
    return categories
        .where((c) => !c.questEligible)
        .map((c) => c.displayName.trim().toLowerCase())
        .where((name) => name.isNotEmpty)
        .toSet();
  }

  /// [businesses] minus those excluded from the Quest.
  ///
  /// Two levels, checked in this order:
  ///
  ///  1. `businesses.quest_eligible` - a per-business override. Set on the
  ///     doc, it wins outright.
  ///  2. `business_categories.quest_eligible` - the category default,
  ///     matched on the category's display name.
  ///
  /// The override exists because `category` on the ~500 bulk-imported rows
  /// is a raw Google Places string ("hair salon", "home health care
  /// service"), not one of the six curated display names - so the category
  /// flag only reaches businesses that picked a category through KIN's own
  /// setup form. Without the override, an imported home care agency would
  /// stay in the Quest no matter what the category said.
  ///
  /// A business whose category is empty or matches nothing is kept: the
  /// fallback is "behaves as it did before", so a typo or a legacy row
  /// never silently disappears from the Quest.
  static List<BusinessesRecord> filterQuestEligible(
    List<BusinessesRecord> businesses,
    Set<String> excludedCategoryNames,
  ) {
    return businesses.where((b) {
      final override = b.questEligible;
      if (override != null) return override;
      if (excludedCategoryNames.isEmpty) return true;
      return !excludedCategoryNames.contains(b.category.trim().toLowerCase());
    }).toList();
  }

  /// Convenience: every visible business, minus the Quest-excluded
  /// categories.
  ///
  /// Both Quest surfaces (the list and the search) call this so they can't
  /// drift apart on which businesses are in play. Admin-delisted businesses
  /// are dropped first - a business that shouldn't be in KIN at all
  /// certainly shouldn't be a check-in target.
  static Future<List<BusinessesRecord>> questEligibleBusinesses() async {
    final results = await Future.wait([
      queryBusinessesRecordOnce(),
      excludedCategoryNames(),
    ]);
    final businesses =
        BusinessVisibility.visible(results[0] as List<BusinessesRecord>);
    final excluded = results[1] as Set<String>;
    return filterQuestEligible(businesses, excluded);
  }
}
