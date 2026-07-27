import 'package:flutter/material.dart';

import '/backend/backend.dart';

/// The map page's category filter chips.
///
/// `businesses.category` is not a controlled vocabulary - the bulk
/// directory import carries raw Google-Places category strings ('Hair
/// salon', 'Barbecue restaurant', 'Business management consultant',
/// 'Soul food restaurant', ...), roughly 100 distinct values across the
/// seeded rows. So a chip cannot match on equality; each chip owns a set
/// of substrings and claims any business whose category contains one of
/// them, case-insensitively.
///
/// Chips are allowed to overlap - a 'Day spa' is reachable from both
/// Beauty and Wellness, which is the useful behaviour for a discovery
/// filter.
@immutable
class BusinessCategoryFilter {
  const BusinessCategoryFilter({
    required this.label,
    required this.icon,
    required this.keywords,
  });

  final String label;
  final IconData icon;

  /// Lowercase substrings matched against `businesses.category`. Empty
  /// means "matches everything" (the Near Me chip).
  final List<String> keywords;

  bool get isMatchAll => keywords.isEmpty;

  bool matches(BusinessesRecord business) {
    if (isMatchAll) return true;
    final category = business.category.toLowerCase();
    if (category.isEmpty) return false;
    return keywords.any(category.contains);
  }
}

/// Near Me is the default/cleared state. It does not actually sort by
/// distance: the app has no user-location plumbing yet (see the note on
/// `BusinessPreviewCardWidget.distance`), so it behaves as "no category
/// filter" until a real location source exists.
const BusinessCategoryFilter kNearMeFilter = BusinessCategoryFilter(
  label: 'Near Me',
  icon: Icons.check_rounded,
  keywords: [],
);

const List<BusinessCategoryFilter> kBusinessCategoryFilters = [
  kNearMeFilter,
  BusinessCategoryFilter(
    label: 'Restaurants',
    icon: Icons.restaurant_rounded,
    keywords: [
      'restaurant',
      'cafe',
      'café',
      'coffee',
      'bakery',
      'bar & grill',
      'grill',
      'pizza',
      'deli',
      'caterer',
      'catering',
      'sandwich',
      'steak house',
      'buffet',
      'juice',
      'smoothie',
      'ice cream',
      'diner',
      'bbq',
      'barbecue',
      'seafood',
      'soul food',
      'food truck',
      'bistro',
      'brunch',
      'bakery shop',
    ],
  ),
  BusinessCategoryFilter(
    label: 'Beauty',
    icon: Icons.content_cut_rounded,
    keywords: [
      'hair',
      'salon',
      'barber',
      'beauty',
      'nail',
      'braid',
      'weave',
      'wig',
      'lash',
      'eyebrow',
      'brow',
      'makeup',
      'make-up',
      'cosmetic',
      'skin care',
      'esthetic',
      'tattoo',
      'spa',
    ],
  ),
  BusinessCategoryFilter(
    label: 'Professional',
    icon: Icons.work_rounded,
    keywords: [
      'consultant',
      'consulting',
      'agency',
      'attorney',
      'lawyer',
      'law firm',
      'legal',
      'accounting',
      'accountant',
      'bookkeep',
      'insurance',
      'real estate',
      'realtor',
      'mortgage',
      'marketing',
      'advertising',
      'financial',
      'notary',
      'tax',
      'photographer',
      'photography',
      'contractor',
      'construction',
      'chamber of commerce',
      'printing',
      'software',
      'it service',
      'staffing',
      'non-profit',
      'nonprofit',
    ],
  ),
  BusinessCategoryFilter(
    label: 'Wellness',
    icon: Icons.self_improvement_rounded,
    keywords: [
      'wellness',
      'fitness',
      'gym',
      'yoga',
      'pilates',
      'massage',
      'therapy',
      'therapist',
      'health',
      'medical',
      'clinic',
      'doctor',
      'physician',
      'dental',
      'dentist',
      'chiropract',
      'nutrition',
      'dietitian',
      'counsel',
      'psycholog',
      'pharmacy',
      'acupunctur',
    ],
  ),
];

/// [businesses] narrowed to [filter]. Near Me (and any other match-all
/// chip) returns the list untouched.
List<BusinessesRecord> applyCategoryFilter(
  List<BusinessesRecord> businesses,
  BusinessCategoryFilter filter,
) =>
    filter.isMatchAll ? businesses : businesses.where(filter.matches).toList();
