import '/backend/backend.dart';

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

  /// [businesses] minus those in a Quest-excluded category.
  ///
  /// A business whose `category` is empty or doesn't match any known
  /// category is kept: the fallback is "behaves as it did before", so a
  /// typo or a legacy row never silently disappears from the Quest.
  static List<BusinessesRecord> filterQuestEligible(
    List<BusinessesRecord> businesses,
    Set<String> excludedCategoryNames,
  ) {
    if (excludedCategoryNames.isEmpty) return businesses;
    return businesses
        .where((b) =>
            !excludedCategoryNames.contains(b.category.trim().toLowerCase()))
        .toList();
  }

  /// Convenience: load every business, minus the Quest-excluded categories.
  ///
  /// Both Quest surfaces (the list and the search) call this so they can't
  /// drift apart on which businesses are in play.
  static Future<List<BusinessesRecord>> questEligibleBusinesses() async {
    final results = await Future.wait([
      queryBusinessesRecordOnce(),
      excludedCategoryNames(),
    ]);
    final businesses = results[0] as List<BusinessesRecord>;
    final excluded = results[1] as Set<String>;
    return filterQuestEligible(businesses, excluded);
  }
}
