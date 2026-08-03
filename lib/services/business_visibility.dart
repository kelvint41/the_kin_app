import '/backend/backend.dart';

/// Which businesses a customer is allowed to see at all.
///
/// KIN lists verified Black-owned businesses. The bulk imports pulled in
/// rows that don't qualify - Panifico Bakeshop is the known example - and
/// until now there was no way to take one down short of deleting the
/// document, which a later re-import would just undo.
///
/// [BusinessesRecord.isHidden] is the delisting switch, set only by an
/// admin (see firestore.rules - it is not owner-writable, or a business
/// could un-hide itself). This filter is the single place that honors it,
/// so a new listing surface can't quietly forget to.
///
/// Filtered client-side on purpose: `is_hidden` is absent on every
/// pre-existing document, and a Firestore `where('is_hidden', isEqualTo:
/// false)` clause matches only documents where the field is present and
/// false - i.e. none of them. That exact null-matching trap already shipped
/// once in this codebase (see JobBoardService.getAllActiveJobs).
class BusinessVisibility {
  /// [businesses] minus anything an admin has delisted.
  static List<BusinessesRecord> visible(List<BusinessesRecord> businesses) =>
      businesses.where((b) => !b.isHidden).toList();
}
