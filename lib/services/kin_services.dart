import 'dart:math';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
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

/// Thin, reusable wrappers around this app's Firestore-backed actions.
///
/// Every method here does three things consistently: checks auth/input
/// preconditions up front, wraps the actual Firebase call in a try/catch,
/// and returns a [ServiceResult] instead of throwing - so a button's
/// onPressed never needs its own try/catch or crashes the app on failure.
class KinServices {
  KinServices._();

  static final _random = Random();
  static const _tickerChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static const _tickerLength = 5;

  /// Uppercases and strips [raw] down to alphanumeric characters, returning
  /// null if the result isn't exactly [_tickerLength] characters. Exposed
  /// so a manual-entry fallback UI can validate user-typed tickers with
  /// the same rules as generated ones.
  static String? sanitizeTicker(String raw) {
    final cleaned = raw.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    return cleaned.length == _tickerLength ? cleaned : null;
  }

  static String _randomTickerCandidate() => List.generate(
        _tickerLength,
        (_) => _tickerChars[_random.nextInt(_tickerChars.length)],
      ).join();

  // Filler words stripped from a business name before deriving a semantic
  // ticker - matched as whole tokens (case-insensitive), not substrings,
  // so e.g. "Cole" doesn't lose its 'co'.
  static const _tickerFillerWords = ['LLC', 'INC', 'CO', 'THE'];

  /// Derives a semantic ticker candidate from [businessName] (e.g.
  /// 'Rollin Smoke BBQ' -> 'ROLLI'), or null if fewer than
  /// [_tickerLength] alphanumeric characters remain once filler words
  /// ('LLC', 'Inc', 'Co', 'The') and punctuation/spaces are stripped.
  static String? _semanticTickerCandidate(String businessName) {
    final words = businessName
        .toUpperCase()
        .split(RegExp(r'[^A-Z0-9]+'))
        .where((w) => w.isNotEmpty && !_tickerFillerWords.contains(w));
    final cleaned = words.join();
    return cleaned.length >= _tickerLength
        ? cleaned.substring(0, _tickerLength)
        : null;
  }

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
        final semantic = _semanticTickerCandidate(businessName);
        if (semantic != null && !await _isTickerTaken(semantic)) {
          return ServiceResult.success(semantic);
        }
      }
      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        final candidate = _randomTickerCandidate();
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
