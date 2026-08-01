import 'package:flutter_test/flutter_test.dart';
import 'package:the_k_i_n_app/services/business_category_filter.dart';

/// [BusinessCategoryFilter.matchesCategory] is pure, so the chips are
/// exercised here against the raw category strings the bulk directory
/// import actually carries - no Firestore, no widget tree.
BusinessCategoryFilter _chip(String label) => kBusinessCategoryFilters
    .firstWhere((f) => f.label == label, orElse: () => throw StateError('no chip labelled $label'));

/// Every chip that claims [category], in row order.
List<String> _chipsFor(String category) => kBusinessCategoryFilters
    .where((f) => !f.isMatchAll && f.matchesCategory(category))
    .map((f) => f.label)
    .toList();

void main() {
  group('chip row', () {
    test('Near Me is first and matches everything', () {
      expect(kBusinessCategoryFilters.first.label, 'Near Me');
      expect(kNearMeFilter.isMatchAll, isTrue);
      expect(kNearMeFilter.matchesCategory('Anything at all'), isTrue);
      expect(kNearMeFilter.matchesCategory(''), isTrue);
    });

    test('Near Me is the only match-all chip', () {
      expect(
        kBusinessCategoryFilters.where((f) => f.isMatchAll).map((f) => f.label),
        ['Near Me'],
      );
    });

    test('labels are unique', () {
      final labels = kBusinessCategoryFilters.map((f) => f.label).toList();
      expect(labels.toSet().length, labels.length);
    });

    test('keywords are lowercase, or they can never match', () {
      for (final filter in kBusinessCategoryFilters) {
        for (final keyword in filter.keywords) {
          expect(keyword, keyword.toLowerCase(), reason: '${filter.label} keyword "$keyword"');
        }
      }
    });
  });

  group('matchesCategory', () {
    test('an empty category matches no real chip', () {
      for (final filter in kBusinessCategoryFilters.where((f) => !f.isMatchAll)) {
        expect(filter.matchesCategory(''), isFalse, reason: filter.label);
      }
    });

    test('is case-insensitive', () {
      expect(_chip('Beauty').matchesCategory('HAIR SALON'), isTrue);
      expect(_chip('Beauty').matchesCategory('hair salon'), isTrue);
    });
  });

  // The substring rule makes a handful of short keywords actively
  // dangerous. These are the collisions that a well-meaning edit is most
  // likely to reintroduce.
  group('keyword collision traps', () {
    test("'shop' is not a keyword - it would swallow Barber shop and Coffee shop", () {
      expect(_chipsFor('Barber shop'), ['Beauty']);
      expect(_chipsFor('Coffee shop'), ['Restaurants']);
    });

    test("'bar' is not a keyword - it would swallow Barber shop and Barbecue restaurant", () {
      expect(_chipsFor('Barbecue restaurant'), ['Restaurants']);
      expect(_chipsFor('Barber shop'), isNot(contains('Restaurants')));
    });

    test("'market' is not a keyword - it would drag marketing into Shopping", () {
      expect(_chipsFor('Marketing agency'), ['Professional']);
      expect(_chipsFor('Marketing consultant'), isNot(contains('Shopping')));
    });
  });

  group('Shopping', () {
    test('claims the retail cluster that previously had no chip', () {
      for (final category in const [
        'Clothing store',
        "Women's clothing store",
        'Boutique',
        'Book store',
        'Gift shop',
        'Shoe store',
        'Grocery store',
        'Gourmet grocery store',
        'Supermarket',
        'African goods store',
        'Handbags shop',
        'Jewelry manufacturer',
        'Custom t-shirt store',
        'Fashion accessories store',
        'Metaphysical supply store',
        'Custom tailor',
        'Plant nursery',
      ]) {
        expect(_chipsFor(category), contains('Shopping'), reason: category);
      }
    });

    test('overlaps Beauty on beauty retail, which is intended', () {
      expect(_chipsFor('Beauty supply store'), containsAll(['Beauty', 'Shopping']));
    });
  });

  group('widened keywords', () {
    test('drink-led venues reach Restaurants', () {
      for (final category in const ['Brewery', 'Winery', 'Cocktail bar', 'Hookah bar']) {
        expect(_chipsFor(category), contains('Restaurants'), reason: category);
      }
    });

    test('personal-care near-misses reach Beauty', () {
      for (final category in const ['Stylist', 'Loctician service']) {
        expect(_chipsFor(category), contains('Beauty'), reason: category);
      }
    });

    test('trades and B2B services reach Professional', () {
      for (final category in const [
        'Cleaning Services',
        'Janitorial Services',
        'Security Services',
        'Mover',
        'Plumber',
        'Trucking company',
        'Event planner',
        'Event venue',
        'Business development service',
        'Business networking company',
        'Business to business service',
        'Professional organizer',
        'Office Supplies Wholesaler',
      ]) {
        expect(_chipsFor(category), contains('Professional'), reason: category);
      }
    });

    test('Wellness still reaches its own categories', () {
      for (final category in const ['Health Care Services', 'Massage therapist', 'Gym']) {
        expect(_chipsFor(category), contains('Wellness'), reason: category);
      }
    });
  });

  group('signup dropdown categories', () {
    // business_setup_page offers a fixed five-value dropdown, separate from
    // the free-text Google-Places wording the bulk import carries. Two of
    // those five ('Professional Services', 'Retail') previously matched no
    // keyword at all, so anyone registering through the app's own form under
    // them was reachable only via Near Me - invisible under every category
    // chip. Asserted here because nothing else connects the dropdown's
    // wording to this keyword list.
    test('every dropdown value reaches at least one chip', () {
      for (final category in const [
        'Restaurant & Food',
        'Beauty & Personal Care',
        'Health & Wellness',
        'Professional Services',
        'Retail',
      ]) {
        expect(_chipsFor(category), isNotEmpty, reason: category);
      }
    });

    test('dropdown values land on the chip a user would expect', () {
      expect(_chipsFor('Restaurant & Food'), contains('Restaurants'));
      expect(_chipsFor('Beauty & Personal Care'), contains('Beauty'));
      expect(_chipsFor('Health & Wellness'), contains('Wellness'));
      expect(_chipsFor('Professional Services'), contains('Professional'));
      expect(_chipsFor('Retail'), contains('Shopping'));
    });

    test("'professional' still reaches the organizer case it replaced", () {
      expect(_chipsFor('Professional organizer'), contains('Professional'));
    });
  });

  group('deliberate non-matches', () {
    // These are genuinely none of the above. Forcing them into a chip
    // would be worse than leaving them to Near Me, so the residual is
    // asserted rather than left to drift.
    test('unclassifiable categories stay chip-less', () {
      for (final category in const [
        'Casino',
        'Museum',
        'Performing arts group',
        'Fishing charter',
        'Indoor golf course',
        'Trade school',
        'Farm',
      ]) {
        expect(_chipsFor(category), isEmpty, reason: category);
      }
    });
  });

  group('applyCategoryFilter', () {
    test('a match-all chip returns the list untouched', () {
      expect(applyCategoryFilter(const [], kNearMeFilter), isEmpty);
    });
  });
}
