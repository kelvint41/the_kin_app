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
/// filter. 'Beauty supply store' likewise sits in both Beauty and
/// Shopping.
///
/// Keywords are raw substrings, so a few tempting ones are booby traps
/// and are deliberately absent:
///
///   - 'shop'   matches 'Barber shop' (21 rows) and 'Coffee shop' (7).
///   - 'bar'    matches 'Barber shop' and 'Barbecue restaurant'.
///   - 'market' matches 'marketing', pulling agencies into Shopping.
///
/// Prefer a longer, unambiguous substring ('gift shop', 'cocktail',
/// 'supermarket') over a short one that happens to work today.
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

  /// The matching rule itself, on a raw category string. Kept separate
  /// from [matches] so it can be tested without building a Firestore
  /// record.
  bool matchesCategory(String category) {
    if (isMatchAll) return true;
    final normalized = category.toLowerCase();
    if (normalized.isEmpty) return false;
    return keywords.any(normalized.contains);
  }

  bool matches(BusinessesRecord business) => matchesCategory(business.category);
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
      // Drink-led venues. Spelled out rather than matching 'bar',
      // which collides with 'Barber shop'.
      'brewery',
      'brewpub',
      'taproom',
      'winery',
      'wine bar',
      'cocktail',
      'hookah',
      'distillery',
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
      'stylist',
      'loctician',
      'waxing',
      'electrolysis',
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
      // Trades and business-to-business services. These read as
      // 'Professional' to a user browsing for someone to hire.
      'cleaning',
      'janitorial',
      'security service',
      'mover',
      'moving service',
      'plumb',
      'electric',
      'trucking',
      'event planner',
      'event venue',
      'business development',
      'business networking',
      'business to business',
      'professional organizer',
      'wholesaler',
    ],
  ),
  BusinessCategoryFilter(
    label: 'Shopping',
    icon: Icons.shopping_bag_rounded,
    keywords: [
      // 'store' is the broad retail token and is safe - every category
      // containing it is genuinely retail.
      'store',
      'boutique',
      'gift shop',
      'grocery',
      'supermarket',
      'farmers market',
      'clothing',
      'apparel',
      'shoe',
      'handbag',
      'jewelry',
      'custom tailor',
      'thrift',
      'furniture',
      'plant nursery',
      'african goods',
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
