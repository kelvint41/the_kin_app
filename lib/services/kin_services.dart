import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/kindex_ticker_util.dart';
import '/flutter_flow/place.dart';
import '/flutter_flow/revenue_cat_util.dart' as revenue_cat;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Result of a [KinServices] call. Callers branch on [isSuccess] instead of
/// catching exceptions themselves - every service method below already
/// wraps its Firebase call in a try/catch and reports failure this way.
class ServiceResult<T> {
  const ServiceResult.success([this.data]) : error = null;
  const ServiceResult.failure(this.error) : data = null;

  final T? data;
  final String? error;

  bool get isSuccess => error == null;
}

/// A single row of display data for the Kindex ticker (see
/// [KinServices.fetchTopBusinessKindex]).
class KindexTickerEntry {
  const KindexTickerEntry({
    required this.name,
    required this.score,
    required this.isTrendingUp,
  });

  final String name;
  final double score;
  final bool isTrendingUp;
}

/// Thin, reusable wrappers around this app's Firestore-backed actions.
///
/// Every method here does three things consistently: checks auth/input
/// preconditions up front, wraps the actual Firebase call in a try/catch,
/// and returns a [ServiceResult] instead of throwing - so a button's
/// onPressed never needs its own try/catch or crashes the app on failure.
class KinServices {
  KinServices._();

  /// Uppercases and strips [raw] down to alphanumeric characters, returning
  /// null if the result isn't exactly 5 characters. Exposed so a
  /// manual-entry fallback UI can validate user-typed tickers with the
  /// same rules as generated ones.
  static String? sanitizeTicker(String raw) => KindexTickerUtil.sanitize(raw);

  static Future<bool> _isTickerTaken(String ticker) async {
    final matches = await BusinessesRecord.collection
        .where('ticker_symbol', isEqualTo: ticker)
        .limit(1)
        .get();
    return matches.docs.isNotEmpty;
  }

  /// Generates a unique 5-character alphanumeric ticker symbol for a new
  /// business registration.
  ///
  /// If [businessName] is given, prefers a semantic ticker derived from
  /// the name (e.g. 'KINVE' for 'Kinvest LLC') over a random one, so long
  /// as it's unclaimed. Falls back to a random candidate - retrying up to
  /// [maxAttempts] times - when the name is too short to yield 5
  /// characters or its derived ticker is already taken. On repeated
  /// collisions this returns a failure rather than throwing, matching
  /// every other method on this class - the caller (e.g. registerBusiness)
  /// is expected to surface that failure so the user can be prompted for
  /// a manual ticker.
  static Future<ServiceResult<String>> generateUniqueTicker({
    String? businessName,
    int maxAttempts = 3,
  }) async {
    try {
      if (businessName != null) {
        final semantic = KindexTickerUtil.semanticCandidate(businessName);
        if (semantic != null && !await _isTickerTaken(semantic)) {
          return ServiceResult.success(semantic);
        }
      }
      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        final candidate = KindexTickerUtil.randomCandidate();
        if (!await _isTickerTaken(candidate)) {
          return ServiceResult.success(candidate);
        }
      }
      return const ServiceResult.failure(
        'Could not generate a unique ticker symbol. Please enter one manually.',
      );
    } catch (_) {
      return const ServiceResult.failure(
        'Could not generate a unique ticker symbol. Please enter one manually.',
      );
    }
  }

  /// Generates a unique 5-character alphanumeric Kindex ticker symbol for
  /// a customer, reserved against `ticker_registry` via
  /// [KindexTickerUtil.reserve] - the `users` collection can't be queried
  /// for a uniqueness check the way `businesses` can, since its rules only
  /// allow reading your own doc. Best-effort: unlike [generateUniqueTicker]
  /// for businesses, a failure here should not block account creation, so
  /// callers should treat a [ServiceResult.failure] as "no ticker yet"
  /// rather than a hard error.
  static Future<ServiceResult<String>> generateUniqueUserTicker({
    required DocumentReference userRef,
    String? displayName,
    int maxAttempts = 3,
  }) async {
    try {
      if (displayName != null) {
        final semantic = KindexTickerUtil.semanticCandidate(displayName);
        if (semantic != null &&
            await KindexTickerUtil.reserve(semantic, userRef)) {
          return ServiceResult.success(semantic);
        }
      }
      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        final candidate = KindexTickerUtil.randomCandidate();
        if (await KindexTickerUtil.reserve(candidate, userRef)) {
          return ServiceResult.success(candidate);
        }
      }
      return const ServiceResult.failure(
        'Could not generate a unique ticker symbol.',
      );
    } catch (_) {
      return const ServiceResult.failure(
        'Could not generate a unique ticker symbol.',
      );
    }
  }

  /// Top businesses by Kindex score, for a scrolling ticker display.
  ///
  /// Reads only the `businesses` collection (public read, per
  /// firestore.rules) so this is safe to call from a logged-out screen
  /// like onboarding.
  /// Used by: Onboarding screen -> MarqueeTicker (business row).
  static Future<ServiceResult<List<KindexTickerEntry>>> fetchTopBusinessKindex({
    int limit = 20,
  }) async {
    try {
      final snapshot = await BusinessesRecord.collection
          .orderBy('kindex_score', descending: true)
          .limit(limit)
          .get();
      final entries = snapshot.docs
          .map((doc) => BusinessesRecord.fromSnapshot(doc))
          .where((record) => record.businessName.isNotEmpty)
          .map((record) => KindexTickerEntry(
                name: record.businessName,
                score: record.kindexScore,
                isTrendingUp: record.kindexVelocity >= 0,
              ))
          .toList();
      return ServiceResult.success(entries);
    } catch (_) {
      return const ServiceResult.failure('Could not load the Kindex ticker.');
    }
  }

  /// Top customers by Kindex score, for a scrolling ticker display.
  ///
  /// Reads only `KindexScores` (public read, per firestore.rules), using
  /// the ticker_symbol/is_trending_up fields the Kindex scoring Cloud
  /// Function denormalizes onto each score doc (see kindex_engine.js) -
  /// `users` itself is self-only readable so can't be queried directly.
  /// Customers who haven't been assigned a ticker yet (e.g. they signed up
  /// before this existed, or ticker reservation failed) are skipped rather
  /// than shown with a blank label.
  /// Used by: Onboarding screen -> MarqueeTicker (customer row).
  static Future<ServiceResult<List<KindexTickerEntry>>> fetchTopCustomerKindex({
    int limit = 20,
  }) async {
    try {
      final snapshot = await KindexScoresRecord.collection
          .orderBy('score', descending: true)
          .limit(limit)
          .get();
      final entries = snapshot.docs
          .map((doc) => KindexScoresRecord.fromSnapshot(doc))
          .where((record) => record.tickerSymbol.isNotEmpty)
          .map((record) => KindexTickerEntry(
                name: record.tickerSymbol,
                score: record.score,
                isTrendingUp: record.isTrendingUp,
              ))
          .toList();
      return ServiceResult.success(entries);
    } catch (_) {
      return const ServiceResult.failure('Could not load the Kindex ticker.');
    }
  }

  /// Submits a star rating + text review for a business.
  /// Used by: Business Profile V2 -> "Submit Review".
  static Future<ServiceResult<void>> submitReview({
    required DocumentReference businessRef,
    required double rating,
    required String reviewText,
  }) async {
    final userRef = currentUserReference;
    if (userRef == null) {
      return const ServiceResult.failure(
          'You need to be signed in to leave a review.');
    }
    try {
      await ReviewsRecord.collection.doc().set(createReviewsRecordData(
            businessRef: businessRef,
            userRef: userRef,
            rating: rating,
            reviewText: reviewText,
            timestamp: getCurrentTimestamp,
          ));
      return const ServiceResult.success();
    } catch (_) {
      return const ServiceResult.failure(
          'Could not submit your review. Please try again.');
    }
  }

  /// Registers a new business for the signed-in user and links it to
  /// their account so pages gating on `ownedBusiness` see it immediately.
  /// Used by: Business Setup Page -> "Register Now".
  static Future<ServiceResult<DocumentReference>> registerBusiness({
    String? category,
    required String businessType,
    required bool isBlackOwned,
    required FFPlace place,
    String? businessName,
    String? phoneNumber,
    String? email,
    String? website,
    String? description,
  }) async {
    final ownerRef = currentUserReference;
    if (ownerRef == null) {
      return const ServiceResult.failure(
          'You need to be signed in to register a business.');
    }

    // Assign a unique KINDEX ticker symbol before creating the business.
    // If we can't find a free one after a few tries, stop here and let the
    // caller prompt for a manual ticker rather than silently registering
    // without one.
    final tickerResult = await generateUniqueTicker(businessName: businessName);
    if (!tickerResult.isSuccess) {
      return ServiceResult.failure(tickerResult.error);
    }

    try {
      final businessRef = BusinessesRecord.collection.doc();
      final data = createBusinessesRecordData(
        ownerRef: ownerRef,
        category: category,
        businessType: businessType,
        isBlackOwned: isBlackOwned,
        address: place.address,
        city: place.city,
        state: place.state,
        zipCodePostcode: place.zipCode,
        businessLocation: place.latLng,
        businessName: businessName,
        phoneNumber: phoneNumber,
        email: email,
        website: website,
        description: description,
        tickerSymbol: tickerResult.data,
        isVerified: false,
        isClaimed: true,
        subscriptionTier: 'Community',
        isPremium: false,
      );
      await businessRef.set(data);
      await currentUserDocument!.reference.update(createUsersRecordData(
        ownedBusiness: businessRef,
      ));
      currentUserDocument = await UsersRecord.getDocumentOnce(ownerRef);
      return ServiceResult.success(businessRef);
    } catch (_) {
      return const ServiceResult.failure(
          'Could not register your business. Please try again.');
    }
  }

  /// Purchases/activates a subscription tier for a business via RevenueCat,
  /// then updates the business record only on a confirmed purchase.
  /// Used by: Merchant Pricing Suite -> each tier card's action button.
  static Future<ServiceResult<void>> upgradeBusinessTier({
    required DocumentReference businessRef,
    required String packageId,
    required String tierName,
    required bool isPremium,
    bool isPriorityPinned = false,
    bool hasFlashBeacon = false,
  }) async {
    try {
      final purchased = await revenue_cat.purchasePackage(packageId);
      if (!purchased) {
        return const ServiceResult.failure(
            'Purchase could not be completed. Please try again.');
      }
      await businessRef.update(createBusinessesRecordData(
        subscriptionTier: tierName,
        isPremium: isPremium,
        isPriorityPinned: isPriorityPinned,
        hasFlashBeacon: hasFlashBeacon,
      ));
      return const ServiceResult.success();
    } catch (_) {
      return const ServiceResult.failure('Could not update your subscription.');
    }
  }

  /// Downgrades a business back to the free Community tier - no purchase
  /// involved. Used by: Merchant Pricing Suite -> "Community" tier card.
  static Future<ServiceResult<void>> downgradeToCommunity({
    required DocumentReference businessRef,
  }) async {
    try {
      await businessRef.update(createBusinessesRecordData(
        subscriptionTier: 'Community',
        isPremium: false,
        isPriorityPinned: false,
        hasFlashBeacon: false,
      ));
      return const ServiceResult.success();
    } catch (_) {
      return const ServiceResult.failure('Could not update your plan.');
    }
  }
}
