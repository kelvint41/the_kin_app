import '/auth/firebase_auth/auth_util.dart';
import '/auth/firebase_auth/google_auth.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/geohash_util.dart';
import '/flutter_flow/kindex_ticker_util.dart';
import '/flutter_flow/place.dart';
import '/flutter_flow/revenue_cat_util.dart' as revenue_cat;
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:share_plus/share_plus.dart';

/// Real package name as of the applicationId rename; still a placeholder
/// in the sense that this URL won't resolve to anything until the Play
/// Store listing actually goes live.
const String kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.thekinapp.kin';

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

/// Aggregated AI Marketing usage, for the Executive Dashboard (see
/// [KinServices.getAiMarketingStats]).
///
/// Counts only - the underlying `ai_generation_logs` documents hold the
/// generated captions and the prompts behind them, and never leave the
/// server.
class AiMarketingStats {
  const AiMarketingStats({
    required this.total,
    required this.byStatus,
    required this.byTier,
    required this.byEngagement,
    required this.unrecognisedStatus,
    required this.engagementUnavailable,
  });

  final int total;

  /// Keyed by the orchestrator's own status values: `success`,
  /// `rejected_not_entitled`, `rejected_quota_exceeded`, `error`.
  final Map<String, int> byStatus;

  /// Requests per `subscription_tier` at the time of the request. The
  /// unentitled tiers matter most here - a Community-tier request is an
  /// owner who wanted this and couldn't buy it.
  final Map<String, int> byTier;

  /// What owners did with the suggestions: `used`, `edited`,
  /// `regenerated`, `dismissed`.
  final Map<String, int> byEngagement;

  /// Logs whose status the server didn't recognise. Non-zero means the
  /// orchestrator has grown a status the stats function doesn't know
  /// about, so the breakdown under-reports and should be trusted less
  /// than [total].
  final int unrecognisedStatus;

  /// True when the engagement counts could not be read at all - so an
  /// empty [byEngagement] means "unknown", not "nobody responded".
  final bool engagementUnavailable;

  int get succeeded => byStatus['success'] ?? 0;
  int get turnedAwayUnentitled => byStatus['rejected_not_entitled'] ?? 0;
  int get turnedAwayOverQuota => byStatus['rejected_quota_exceeded'] ?? 0;
  int get errored => byStatus['error'] ?? 0;
}

/// One classified, summarized entry from the support chat log, for the
/// Executive Dashboard's recent-themes list - never the raw message text or
/// who sent it, see [KinServices.getSupportChatStats].
class SupportChatRecentEntry {
  const SupportChatRecentEntry({
    required this.category,
    this.summary,
    this.createdAt,
  });

  final String category;
  final String? summary;
  final DateTime? createdAt;
}

/// Aggregated counts from `support_chat_logs` (see
/// [KinServices.getSupportChatStats]) - counts and short summaries only,
/// same reasoning as [AiMarketingStats].
class SupportChatStats {
  const SupportChatStats({
    required this.total,
    required this.byCategory,
    required this.unrecognisedCategory,
    required this.recent,
  });

  final int total;

  /// Keyed by the classifier's categories: `question`, `bug_report`,
  /// `suggestion`, `praise`, `other`.
  final Map<String, int> byCategory;

  final int unrecognisedCategory;
  final List<SupportChatRecentEntry> recent;

  int get questions => byCategory['question'] ?? 0;
  int get bugReports => byCategory['bug_report'] ?? 0;
  int get suggestions => byCategory['suggestion'] ?? 0;
  int get praise => byCategory['praise'] ?? 0;
}

/// One turn in a support chat exchange - kept client-side only, as recent
/// context sent with the next message (see
/// [KinServices.sendSupportChatMessage]). Never persisted locally between
/// app sessions.
class SupportChatTurn {
  const SupportChatTurn({required this.role, required this.text});

  /// 'user' or 'assistant'.
  final String role;
  final String text;

  Map<String, String> toJson() => {'role': role, 'text': text};
}

/// A pending customer-submitted KIN Quest discovery that matches a
/// business name an owner is entering during setup - see
/// [KinServices.findMatchingBusinessSubmission].
class MatchedBusinessSubmission {
  const MatchedBusinessSubmission({
    required this.submissionId,
    required this.businessName,
    required this.address,
    required this.category,
  });

  final String submissionId;
  final String businessName;
  final String address;
  final String category;
}

/// Result of a GPS-verified check-in (see
/// [KinServices.checkInToBusiness]).
class VisitCheckIn {
  const VisitCheckIn({
    required this.visitId,
    required this.alreadyCheckedIn,
    required this.distanceMeters,
    this.rarityTier = 'Standard',
    this.pointsAwarded = 0,
    this.totalPoints,
  });

  final String visitId;

  /// True when a recent visit was reused rather than a new one recorded,
  /// so repeated taps during one trip don't stack duplicate visits.
  final bool alreadyCheckedIn;

  final int distanceMeters;

  /// The business's rarity_tier at check-in time - 'Standard', 'Rare', or
  /// 'Hidden Gem'. Used by the Scavenger Hunt page to show the right
  /// celebration for what was just found.
  final String rarityTier;

  /// Scavenger points this check-in was worth. Zero for a deduped repeat
  /// check-in - see [alreadyCheckedIn].
  final int pointsAwarded;

  /// The caller's scavenger point total after this check-in. Null on the
  /// deduped path (the server doesn't recompute it there).
  final int? totalPoints;
}

/// A single row of display data for the Kindex ticker (see
/// [KinServices.fetchTopBusinessKindex]).
class KindexTickerEntry {
  const KindexTickerEntry({
    required this.name,
    required this.score,
    required this.isTrendingUp,
    this.businessRef,
  });

  final String name;
  final double score;
  final bool isTrendingUp;

  /// Only set for business entries (see [KinServices.fetchTopBusinessKindex])
  /// - null for customer entries, which have no business profile to link to.
  final DocumentReference? businessRef;
}

/// One AI-generated post concept, returned by
/// [KinServices.generateMarketingContent]. [generationLogId] identifies the
/// `ai_generation_logs` doc this came from server-side - pass it back to
/// [KinServices.logAiSuggestionEngagement] so usage can be tied to the
/// specific generation that produced it.
class MarketingContent {
  const MarketingContent({
    required this.caption,
    required this.hashtags,
    required this.cta,
    required this.imageConcept,
    required this.generationLogId,
  });

  final String caption;
  final List<String> hashtags;
  final String cta;
  final String imageConcept;
  final String generationLogId;
}

/// Power Hour caps for one subscription tier. See
/// [KinServices.startPowerHour].
class _PowerHourLimits {
  const _PowerHourLimits({required this.durationCapMinutes, this.monthlyLimit});

  final int durationCapMinutes;

  /// Max Power Hours per rolling 30-day window. Null means unlimited -
  /// skip the frequency check entirely.
  final int? monthlyLimit;
}

/// Real subscription_tier values, as written by the live upgrade flow in
/// merchant_pricing_suite_widget.dart - not the generic 'Community' /
/// 'Pro' / 'Elite' names a first pass might assume. Any business whose
/// subscription_tier isn't one of these keys (a typo, or an ad-hoc value
/// like 'Founder'/'unlimited' set outside the normal upgrade flow) falls
/// through to [_defaultPowerHourLimits] rather than risk granting
/// broader access than intended.
const _powerHourLimitsByTier = <String, _PowerHourLimits>{
  'Community': _PowerHourLimits(durationCapMinutes: 30, monthlyLimit: 1),
  'Founding Local': _PowerHourLimits(durationCapMinutes: 45, monthlyLimit: 2),
  'Pro Growth': _PowerHourLimits(durationCapMinutes: 60, monthlyLimit: 4),
  'Elite Growth': _PowerHourLimits(durationCapMinutes: 90, monthlyLimit: null),
};
const _defaultPowerHourLimits =
    _PowerHourLimits(durationCapMinutes: 30, monthlyLimit: 1);

String _powerHourLimitMessage(String tier) {
  switch (tier) {
    case 'Community':
      return "You've reached your monthly Power Hour limit. Upgrade to "
          'Founding Local or Pro Growth for more!';
    case 'Founding Local':
      return "You've reached your monthly Power Hour limit for Founding "
          'Local. Upgrade to Pro Growth for more!';
    case 'Pro Growth':
      return "You've reached your monthly Power Hour limit for Pro Growth. "
          'Upgrade to Elite Growth for unlimited Power Hours!';
    default:
      return "You've reached your monthly Power Hour limit. Upgrade your "
          'plan for more!';
  }
}

/// Thin, reusable wrappers around this app's Firestore-backed actions.
///
/// Every method here does three things consistently: checks auth/input
/// preconditions up front, wraps the actual Firebase call in a try/catch,
/// and returns a [ServiceResult] instead of throwing - so a button's
/// onPressed never needs its own try/catch or crashes the app on failure.
class KinServices {
  KinServices._();

  /// Power Hour duration cap in minutes for [tier], from the same table
  /// [startPowerHour] enforces server-side. Exposed so UI (duration
  /// pickers, slider validation) can show/validate against the real
  /// limit without duplicating it.
  static int powerHourDurationCapMinutes(String tier) =>
      (_powerHourLimitsByTier[tier] ?? _defaultPowerHourLimits)
          .durationCapMinutes;

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
                businessRef: record.reference,
              ))
          .toList();
      return ServiceResult.success(entries);
    } catch (_) {
      return const ServiceResult.failure('Could not load the KINDEX ticker.');
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
      return const ServiceResult.failure('Could not load the KINDEX ticker.');
    }
  }

  /// Deterministic review id: one review document per customer per
  /// business, so re-submitting edits the existing review in place instead
  /// of stacking duplicates.
  static String reviewDocId({
    required DocumentReference businessRef,
    required DocumentReference userRef,
  }) =>
      '${businessRef.id}_${userRef.id}';

  /// Records a GPS-verified check-in, the prerequisite for a review to
  /// count toward the business's Kindex score.
  ///
  /// Takes a single one-shot location reading (no background tracking) and
  /// hands it to the `recordVerifiedVisit` callable, which does the radius
  /// check server-side and writes the visit with the Admin SDK - clients
  /// cannot write `uservisits` directly.
  ///
  /// Used by: Business Profile V2 -> "I'm Here" check-in.
  static Future<ServiceResult<VisitCheckIn>> checkInToBusiness({
    required DocumentReference businessRef,
  }) async {
    if (currentUserReference == null) {
      return const ServiceResult.failure(
          'You need to be signed in to check in.');
    }

    LatLng? position;
    try {
      position = await queryCurrentUserLocation();
    } catch (e) {
      // queryCurrentUserLocation surfaces denied/disabled as errors. Say
      // why location is needed rather than just failing - the review can
      // still be posted, it just won't count toward the score.
      final message = e.toString();
      if (message.contains('denied') || message.contains('disabled')) {
        return const ServiceResult.failure(
            'Location access is needed to verify you visited this business. '
            'You can still leave a review without checking in - it just '
            "won't count toward the business's KINDEX score.");
      }
      return const ServiceResult.failure(
          'Could not read your location. Please try again.');
    }

    if (position == null) {
      return const ServiceResult.failure(
          'Could not get a location fix. Please try again.');
    }

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable(
        'recordVerifiedVisit',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      )
          .call<Map<String, dynamic>>({
        'businessRefPath': businessRef.path,
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
      final data = result.data;
      return ServiceResult.success(VisitCheckIn(
        visitId: data['visitId'] as String,
        alreadyCheckedIn: data['alreadyCheckedIn'] as bool? ?? false,
        distanceMeters: (data['distanceMeters'] as num?)?.toInt() ?? 0,
        rarityTier: data['rarityTier'] as String? ?? 'Standard',
        pointsAwarded: (data['pointsAwarded'] as num?)?.toInt() ?? 0,
        totalPoints: (data['totalPoints'] as num?)?.toInt(),
      ));
    } on FirebaseFunctionsException catch (e) {
      return ServiceResult.failure(e.message ?? 'Could not check you in.');
    } catch (_) {
      return const ServiceResult.failure(
          'Could not check you in. Please try again.');
    }
  }

  /// Submits a new business the signed-in owner found, via the
  /// `submitBusinessDiscovery` callable. This is what advances
  /// businesses_discovered_count toward the 5/15/30 mystery-reward
  /// milestones (mystery_reward_engine.js).
  static Future<ServiceResult<void>> submitBusinessDiscovery({
    required String businessName,
    required String address,
    required String category,
    double? latitude,
    double? longitude,
  }) async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable(
        'submitBusinessDiscovery',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      )
          .call<Map<String, dynamic>>({
        'businessName': businessName,
        'address': address,
        'category': category,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      });
      return const ServiceResult.success(null);
    } on FirebaseFunctionsException catch (e) {
      return ServiceResult.failure(
          e.message ?? 'Could not submit that business.');
    } catch (_) {
      return const ServiceResult.failure(
          'Could not submit that business. Please try again.');
    }
  }

  /// Submits a business a *customer* found while traveling outside their
  /// usual KIN Quest radius, via the `submitCustomerBusinessDiscovery`
  /// callable. Unlike [submitBusinessDiscovery], this has no owned-business
  /// gate and captures the device's current coordinates as the business's
  /// starting `business_location` - the callable rejects it outright if it
  /// looks like a duplicate of something already in the directory or
  /// already submitted. It only queues a `business_submissions` row for
  /// review; it does not make the business check-in-able immediately.
  static Future<ServiceResult<void>> submitTravelerBusinessDiscovery({
    required String businessName,
    required String address,
    required String category,
    required double latitude,
    required double longitude,

    /// True only when the submitter's own GPS put them at the business.
    ///
    /// A submission vouched for from a business card is still worth having,
    /// but KIN lists *verified* Black-owned businesses, so it can't be
    /// recorded as the same thing as someone confirming it on the ground.
    /// The server re-derives nothing here - it just carries the flag onto
    /// the submission for review.
    bool verifiedOnSite = false,
  }) async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable(
        'submitCustomerBusinessDiscovery',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      )
          .call<Map<String, dynamic>>({
        'businessName': businessName,
        'address': address,
        'category': category,
        'latitude': latitude,
        'longitude': longitude,
        'verifiedOnSite': verifiedOnSite,
      });
      return const ServiceResult.success(null);
    } on FirebaseFunctionsException catch (e) {
      return ServiceResult.failure(
          e.message ?? 'Could not submit that business.');
    } catch (_) {
      return const ServiceResult.failure(
          'Could not submit that business. Please try again.');
    }
  }

  /// Looks up whether a customer already submitted this business as a KIN
  /// Quest discovery while an owner is filling out business setup - see
  /// `findMatchingBusinessSubmission` (business_discovery.js). Deliberately
  /// never surfaces who submitted it, only business-shaped fields the owner
  /// would already know.
  static Future<ServiceResult<MatchedBusinessSubmission?>>
      findMatchingBusinessSubmission({
    required String businessName,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable(
        'findMatchingBusinessSubmission',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
      )
          .call<Map<String, dynamic>>({
        'businessName': businessName,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      });
      final data = result.data;
      if (data['matched'] != true) {
        return const ServiceResult.success(null);
      }
      return ServiceResult.success(MatchedBusinessSubmission(
        submissionId: data['submissionId'] as String,
        businessName: data['businessName'] as String? ?? '',
        address: data['address'] as String? ?? '',
        category: data['category'] as String? ?? '',
      ));
    } on FirebaseFunctionsException catch (e) {
      return ServiceResult.failure(
          e.message ?? 'Could not check for a matching submission.');
    } catch (_) {
      return const ServiceResult.failure(
          'Could not check for a matching submission.');
    }
  }

  /// Marks a matched submission as claimed once the owner it matched has
  /// finished registering their business - see [findMatchingBusinessSubmission].
  /// Best-effort: a failure here shouldn't block business registration,
  /// which has already completed by the time this is called, so callers
  /// should ignore [ServiceResult.failure] rather than surface it.
  static Future<ServiceResult<void>> resolveBusinessSubmission({
    required String submissionId,
    required DocumentReference businessRef,
  }) async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable(
        'resolveBusinessSubmission',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
      )
          .call<Map<String, dynamic>>({
        'submissionId': submissionId,
        'businessRefPath': businessRef.path,
      });
      return const ServiceResult.success(null);
    } catch (_) {
      return const ServiceResult.failure('Could not resolve the submission.');
    }
  }

  /// Redeems an unlocked mystery reward via the `redeemReward` callable,
  /// which validates ownership/expiry server-side and applies the tier or
  /// beacon grant.
  static Future<ServiceResult<String>> redeemReward({
    required String rewardId,
  }) async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable(
        'redeemReward',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      )
          .call<Map<String, dynamic>>({'rewardId': rewardId});
      final rewardType = result.data['rewardType'] as String? ?? '';
      return ServiceResult.success(rewardType);
    } on FirebaseFunctionsException catch (e) {
      return ServiceResult.failure(
          e.message ?? 'Could not redeem this reward.');
    } catch (_) {
      return const ServiceResult.failure(
          'Could not redeem this reward. Please try again.');
    }
  }

  /// Sends post text to the `cleanUpPostText` callable for an optional,
  /// opt-in AI grammar/spelling cleanup pass. Never called automatically -
  /// only from an explicit "Clean up with AI" tap in the composer/editor.
  static Future<ServiceResult<String>> cleanUpPostText({
    required String postText,
  }) async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable(
        'cleanUpPostText',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      )
          .call<Map<String, dynamic>>({'postText': postText});
      final cleanedText = result.data['cleanedText'] as String? ?? postText;
      return ServiceResult.success(cleanedText);
    } on FirebaseFunctionsException catch (e) {
      return ServiceResult.failure(
          e.message ?? 'Could not clean up this post.');
    } catch (_) {
      return const ServiceResult.failure(
          'Could not clean up this post. Please try again.');
    }
  }

  /// Edits an Exchange post the signed-in user authored. Firestore rules
  /// should restrict this write to the post's own user_ref - this method
  /// doesn't re-check ownership client-side beyond what the UI already
  /// gates, since rules are the actual enforcement boundary.
  static Future<ServiceResult<void>> editExchangePost({
    required DocumentReference postRef,
    required String postText,
  }) async {
    try {
      await postRef.update({
        'post_text': postText,
        'is_edited': true,
        'edited_at': FieldValue.serverTimestamp(),
      });
      return const ServiceResult.success(null);
    } catch (_) {
      return const ServiceResult.failure(
          'Could not save your changes. Please try again.');
    }
  }

  /// Whether the signed-in user has a verified visit to this business
  /// inside the scoring window, which is what decides if their review
  /// counts toward the Kindex score.
  static Future<bool> hasVerifiedVisit({
    required DocumentReference businessRef,
    Duration window = const Duration(days: 7),
  }) async {
    final userRef = currentUserReference;
    if (userRef == null) return false;
    try {
      final snapshot = await UservisitsRecord.collection
          .where('user_ref', isEqualTo: userRef)
          .where('business_ref', isEqualTo: businessRef)
          .where('visit_timestamp',
              isGreaterThanOrEqualTo: DateTime.now().subtract(window))
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Submits or updates a star rating + text review for a business.
  ///
  /// Reviews always post, whether or not the customer checked in - only
  /// whether they *count toward the score* depends on a verified visit,
  /// which the nightly recompute decides. Writing at a composite id means a
  /// second submission edits the customer's existing review rather than
  /// creating a duplicate.
  ///
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
    final docRef = ReviewsRecord.collection
        .doc(reviewDocId(businessRef: businessRef, userRef: userRef));
    try {
      final existing = await docRef.get();
      if (!existing.exists) {
        await docRef.set(createReviewsRecordData(
          businessRef: businessRef,
          userRef: userRef,
          rating: rating,
          reviewText: reviewText,
          timestamp: getCurrentTimestamp,
          editCount: 0,
        ));
        return const ServiceResult.success();
      }

      // Editing an existing review. The cap is enforced in Firestore rules
      // too; this check exists to give a clear message instead of a bare
      // permission-denied.
      final currentEdits =
          (existing.data() as Map<String, dynamic>?)?['edit_count'] as int? ??
              0;
      if (currentEdits >= 2) {
        return const ServiceResult.failure(
            "You've reached the edit limit for this review.");
      }
      await docRef.update({
        'rating': rating,
        'review_text': reviewText,
        'timestamp': getCurrentTimestamp,
        'edit_count': currentEdits + 1,
      });
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
    String? heroImageUrl,
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
        heroImage: heroImageUrl,
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

  /// Updates an already-claimed business's own listing fields in place.
  /// Used by: Business Setup Page, when opened for an owner who already has
  /// [UsersRecord.ownedBusiness] set ("Edit Business Profile" in the owner
  /// menu).
  ///
  /// Deliberately writes an explicit, hand-picked field map rather than
  /// reusing [registerBusiness]'s createBusinessesRecordData(...) call: that
  /// helper's map includes every one of its ~60 named parameters, and any
  /// left at their default null - everything registerBusiness itself
  /// doesn't set, like owner_ref, is_verified, subscription_tier,
  /// ticker_symbol, kindex_score - would come through as an explicit null.
  /// set() treats that as "not provided, fine for a new doc"; update()
  /// treats it as "clear this field," which would have wiped every one of
  /// those on the very first edit.
  static Future<ServiceResult<void>> updateBusinessProfile({
    required DocumentReference businessRef,
    String? category,
    required String businessType,
    required bool isBlackOwned,
    required FFPlace place,
    required String businessName,
    required String phoneNumber,
    required String email,
    required String website,
    required String description,
    String? heroImageUrl,
  }) async {
    try {
      // setBusinessGeohashOnCreate (business_geohash_on_create.js) only ever
      // fires once, on document creation - it never revisits a business
      // whose address changes afterward. Without recomputing here, editing
      // an address would leave the old geohash in place: business_location
      // shows the new pin correctly everywhere that reads lat/lng directly,
      // but GoogleMapPageModel's geohash-range query still finds the
      // business at its old spot (or not at all, once the viewport no
      // longer overlaps that stale range). Guarded the same way
      // adminCreateBusiness/businessCoords() treat (0,0): that's the
      // "no real location" sentinel, not a place on Earth worth geohashing.
      final hasRealLocation =
          !(place.latLng.latitude == 0 && place.latLng.longitude == 0);

      await businessRef.update({
        'business_name': businessName,
        'phone_number': phoneNumber,
        'email': email,
        'website': website,
        'description': description,
        'business_type': businessType,
        'is_black_owned': isBlackOwned,
        'address': place.address,
        'city': place.city,
        'state': place.state,
        'zip_code_postcode': place.zipCode,
        'business_location': place.latLng.toGeoPoint(),
        if (hasRealLocation)
          'geohash': encodeGeohash(place.latLng.latitude, place.latLng.longitude),
        if (category != null) 'category': category,
        if (heroImageUrl != null) 'hero_image': heroImageUrl,
      });
      return const ServiceResult.success();
    } catch (_) {
      return const ServiceResult.failure(
          'Could not save your changes. Please try again.');
    }
  }

  /// Files a claim on an existing (bulk-imported, unclaimed) business.
  /// Used by: Claim Business Page -> "Submit Claim".
  ///
  /// Deliberately writes *only* to `claim_requests` and never touches the
  /// business doc: firestore.rules gates business updates on
  /// `owner_ref == the signed-in user`, and an unclaimed business has a null
  /// owner_ref, so ownership can only be granted server-side after review.
  /// That's what stops anyone from claiming a business they don't run.
  ///
  /// [declaredBlackOwned] and [declaredVeteran] are recorded here as the
  /// claimant's own declaration - they are NOT copied onto the business until
  /// a reviewer approves the claim. We never ask for documentation of either.
  ///
  /// [openingTime] and [closingTime] are stored as free text (e.g. "9:00 AM")
  /// and copied to the business doc once a claim is approved.
  ///
  /// [isMobileVendor] marks this as a food truck / mobile vendor. Enables
  /// Location Beacon feature for owners with paid tiers.
  ///
  /// Note: `claim_requests` is write-only for clients (allow read: if false),
  /// so this can't check whether the same user already has a claim pending on
  /// this business. Duplicate submissions are expected and de-duped by the
  /// reviewer on business_id + applicant_user_id.
  static Future<ServiceResult<void>> submitClaimRequest({
    required DocumentReference businessRef,
    required String businessName,
    required String claimantName,
    required String claimantRole,
    required String contactEmail,
    required String contactPhone,
    required bool attested,
    required bool declaredBlackOwned,
    required bool declaredVeteran,
    String? verificationProofLink,
    String? openingTime,
    String? closingTime,
    bool? isMobileVendor,
  }) async {
    final userRef = currentUserReference;
    if (userRef == null) {
      return const ServiceResult.failure(
          'You need to be signed in to claim a business.');
    }
    if (!attested) {
      return const ServiceResult.failure(
          'Please confirm you are authorized to claim this business.');
    }
    if (claimantName.trim().isEmpty) {
      return const ServiceResult.failure('Please enter your name.');
    }
    if (contactEmail.trim().isEmpty && contactPhone.trim().isEmpty) {
      return const ServiceResult.failure(
          'Please give us an email or phone number so we can reach you.');
    }

    try {
      final now = getCurrentTimestamp;
      await ClaimRequestsRecord.collection
          .doc()
          .set(createClaimRequestsRecordData(
            businessId: businessRef.id,
            businessName: businessName,
            applicantUserId: userRef.id,
            claimantName: claimantName.trim(),
            claimantRole: claimantRole.trim(),
            contactEmail: contactEmail.trim(),
            contactPhone: contactPhone.trim(),
            verificationProofLink: verificationProofLink?.trim(),
            attested: true,
            attestedAt: now,
            declaredBlackOwned: declaredBlackOwned,
            declaredVeteran: declaredVeteran,
            openingTime: openingTime?.trim(),
            closingTime: closingTime?.trim(),
            isMobileVendor: isMobileVendor,
            status: 'pending',
            timestamp: now,
          ));
      return const ServiceResult.success();
    } catch (_) {
      return const ServiceResult.failure(
          'Could not submit your claim. Please try again.');
    }
  }

  /// Starts a location beacon for a mobile vendor (food truck, pop-up, etc).
  /// Owner enters their current location and expiration time. Location beacon
  /// is a paid-tier feature (Founding Local and above only).
  ///
  /// Returns success on write completion. Caller is responsible for tier check.
  static Future<ServiceResult<void>> startLocationBeacon({
    required DocumentReference businessRef,
    required String currentLocation,
    required DateTime expiresAt,
    bool autoPost = false,
  }) async {
    try {
      await businessRef.update(createBusinessesRecordData(
        mobileLocationActive: true,
        currentLocation: currentLocation,
        currentLocationExpiresAt: expiresAt,
      ));

      if (autoPost) {
        await createLocationPost(
          businessRef: businessRef,
          location: currentLocation,
        );
      }

      return const ServiceResult.success();
    } catch (_) {
      return const ServiceResult.failure(
          'Could not start location beacon. Please try again.');
    }
  }

  /// Stops the active location beacon.
  static Future<ServiceResult<void>> stopLocationBeacon({
    required DocumentReference businessRef,
  }) async {
    try {
      await businessRef.update(createBusinessesRecordData(
        mobileLocationActive: false,
      ));
      return const ServiceResult.success();
    } catch (_) {
      return const ServiceResult.failure(
          'Could not stop location beacon. Please try again.');
    }
  }

  /// Updates the current location while a beacon is active.
  static Future<ServiceResult<void>> updateLocationBeacon({
    required DocumentReference businessRef,
    required String newLocation,
  }) async {
    try {
      await businessRef.update(createBusinessesRecordData(
        currentLocation: newLocation,
      ));
      return const ServiceResult.success();
    } catch (_) {
      return const ServiceResult.failure(
          'Could not update location. Please try again.');
    }
  }

  /// Auto-generates a location beacon post in the Exchange feed. Called
  /// automatically by startLocationBeacon if autoPost is true, or can be
  /// called manually by the owner.
  static Future<ServiceResult<void>> createLocationPost({
    required DocumentReference businessRef,
    required String location,
  }) async {
    final userRef = currentUserReference;
    if (userRef == null) {
      return const ServiceResult.failure(
          'You need to be signed in to post a location beacon.');
    }

    try {
      final business = await BusinessesRecord.getDocumentOnce(businessRef);
      final postText = '🚨 We\'re live at $location! Come find us! 🚐';

      await FirebaseFirestore.instance.collection('exchange_posts').add({
        'user_ref': userRef,
        'business_ref': businessRef,
        'post_text': postText,
        'created_at': FieldValue.serverTimestamp(),
        'is_edited': false,
        'reaction_counts': {},
        'is_location_beacon_post': true,
        'beacon_location': location,
      });

      return const ServiceResult.success();
    } catch (_) {
      return const ServiceResult.failure(
          'Could not post location beacon. Please try again.');
    }
  }

  /// Purchases/activates a subscription tier for a business via RevenueCat,
  /// then updates the business record only on a confirmed purchase.
  /// [offeringId] is one of the 4 RevenueCat Offering identifiers
  /// (founder / founding_local / premium_local / elite); each holds a
  /// "monthly" and an "annual" package, selected by [isYearly].
  /// Used by: Merchant Pricing Suite -> each tier card's action button.
  static Future<ServiceResult<void>> upgradeBusinessTier({
    required DocumentReference businessRef,
    required String offeringId,
    required bool isYearly,
    required String tierName,
    required bool isPremium,
    bool isPriorityPinned = false,
    bool hasFlashBeacon = false,
  }) async {
    try {
      final purchased = await revenue_cat.purchasePackage(
        offeringId,
        isYearly ? 'annual' : 'monthly',
      );
      if (!purchased) {
        return const ServiceResult.failure(
            'Purchase could not be completed. Please try again.');
      }
      await businessRef.update(createBusinessesRecordData(
        subscriptionTier: tierName,
        isPremium: isPremium,
        isPriorityPinned: isPriorityPinned,
        hasFlashBeacon: hasFlashBeacon,
        // A paid purchase ends any trial in progress: 'converted' stops the
        // nightly sweep (founding_local_trial.js) from ever downgrading this
        // business at day 14, and clears the reminder banner. has_used_trial
        // is deliberately not touched - it stays true forever.
        trialStatus: 'converted',
        trialReminderStage: '',
      ));
      return const ServiceResult.success();
    } catch (_) {
      return const ServiceResult.failure('Could not update your subscription.');
    }
  }

  /// Starts the one-per-business 14-day Founding Local trial via the
  /// `startFoundingLocalTrial` callable, which validates ownership and the
  /// has_used_trial guard server-side (both trivially bypassable if left to
  /// the client) and grants the same entitlement fields a real Founding
  /// Local purchase would. No payment method is involved.
  /// Used by: Merchant Pricing Suite -> Founding Local card trial CTA.
  static Future<ServiceResult<DateTime>> startFoundingLocalTrial({
    required DocumentReference businessRef,
  }) async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable(
        'startFoundingLocalTrial',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      )
          .call<Map<String, dynamic>>({'businessRef': businessRef.id});
      final endsAtMillis = result.data['trialEndsAtMillis'] as int?;
      if (endsAtMillis == null) {
        return const ServiceResult.failure(
            'Could not start your trial. Please try again.');
      }
      return ServiceResult.success(
          DateTime.fromMillisecondsSinceEpoch(endsAtMillis));
    } on FirebaseFunctionsException catch (e) {
      return ServiceResult.failure(e.message ?? 'Could not start your trial.');
    } catch (_) {
      return const ServiceResult.failure(
          'Could not start your trial. Please try again.');
    }
  }

  /// Creates a live, unclaimed listing immediately. Admin only.
  ///
  /// The normal discovery flows queue a `business_submissions` row for
  /// review. An admin standing in front of the business with its card in
  /// hand IS the review, so this writes straight to `businesses` - the
  /// point is to add it while the owner is watching, then hand them the
  /// claim flow on the spot.
  ///
  /// Sets `geohash`, which is what actually makes a listing appear on the
  /// map: GoogleMapPageModel queries by geohash range, so a business
  /// without one is invisible there no matter how good its coordinates
  /// are. Nothing else in the app computes this at write time - it existed
  /// only as a one-off backfill script - so any listing created without it
  /// would silently never show up.
  ///
  /// `owner_ref` is deliberately left null: the business is unclaimed, so
  /// the owner can claim it through the normal claim flow and prove they
  /// own it. Admin-added is not the same as owner-verified.
  static Future<ServiceResult<DocumentReference>> adminCreateBusiness({
    required String businessName,
    required String address,
    required String category,
    required double latitude,
    required double longitude,
    String city = '',
  }) async {
    try {
      final ref =
          await FirebaseFirestore.instance.collection('businesses').add({
        'business_name': businessName,
        'address': address,
        'category': category,
        'city': city,
        'business_location': GeoPoint(latitude, longitude),
        'geohash': encodeGeohash(latitude, longitude),
        // Verified as Black-owned by the admin who added it - that is the
        // bar KIN lists against. Ownership is a separate question, settled
        // by the claim flow.
        'is_verified': true,
        'owner_ref': null,
        'subscription_tier': 'Community',
        'is_premium': false,
        'created_at': FieldValue.serverTimestamp(),
        'added_by_admin': true,
      });
      return ServiceResult.success(ref);
    } catch (_) {
      return const ServiceResult.failure(
          'Could not add that business. Please try again.');
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
        // Choosing the free tier during a trial ends it early, by the same
        // rules as expiry - the entitlement is already being dropped here,
        // so leaving trial_status 'active' would just leave the nightly
        // sweep to re-downgrade an already-downgraded business.
        trialStatus: 'expired',
        trialReminderStage: '',
      ));
      return const ServiceResult.success();
    } catch (_) {
      return const ServiceResult.failure('Could not update your plan.');
    }
  }

  /// The RevenueCat entitlement that backs each purchasable tier - matches
  /// the 4 Offering identifiers 1:1, per how they're configured in the
  /// RevenueCat dashboard. Deliberately does not include "Pro Growth" /
  /// "Elite Growth" (mystery-reward comp grants, a different mechanism -
  /// see mystery_reward_engine.js) or "Community" (free, nothing to check).
  static const _paidTierEntitlements = {
    'Founder': 'founder',
    'Founding Local': 'founding_local',
    'Premium Local': 'premium_local',
    'Elite': 'elite',
  };

  /// Re-checks a business's paid tier against RevenueCat's actual entitlement
  /// state and downgrades to Community if the store no longer shows it
  /// active - the case a lapsed, refunded, or cancelled-and-expired
  /// subscription would otherwise leave stuck at whatever tier the last
  /// successful purchase wrote, since nothing else re-verifies it.
  /// Used by: main.dart's auth-state listener, on every login/app load.
  ///
  /// Skips a business whose trial_status is 'active': that premium state
  /// came from startFoundingLocalTrial, a free trial with no RevenueCat
  /// purchase behind it, so there is no entitlement to check yet.
  static Future<void> reconcileSubscriptionEntitlement(
    DocumentReference businessRef,
  ) async {
    try {
      final business = await BusinessesRecord.getDocumentOnce(businessRef);
      if (business.trialStatus == 'active') {
        return;
      }
      final entitlementId = _paidTierEntitlements[business.subscriptionTier];
      if (entitlementId == null) {
        return;
      }
      final active = await revenue_cat.isEntitled(entitlementId);
      if (active == false) {
        await downgradeToCommunity(businessRef: businessRef);
      }
    } catch (_) {
      // Best-effort - a failed check should never block login/app startup.
    }
  }

  /// Opens a business's own outbound link (website, DoorDash/UberEats/
  /// Grubhub, social profile) with an explicit `utm_source=kin_app` /
  /// `utm_medium=business_directory` pair merged into its query string, so
  /// server logs on the business's end can attribute the click to KIN.
  ///
  /// This is plain UTM tagging, not link cloaking: the destination is
  /// exactly the URL the business gave us, unobscured, just with our
  /// attribution appended - the same thing any directory or marketplace
  /// app does to outbound links.
  ///
  /// Existing query parameters are preserved (merged via
  /// [Uri.queryParameters], then re-serialised through [Uri.replace] so the
  /// result always has exactly one `?` and properly `&`-joined pairs,
  /// however the business's stored URL was formatted). Non-http(s) URLs
  /// (tel:, mailto:) and empty strings pass through unchanged - a UTM
  /// parameter on a phone number is meaningless and would just break the
  /// dialer.
  /// Used by: Business Profile -> website/social/food-delivery links.
  static Future<void> launchBusinessLink(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.scheme.startsWith('http')) {
      await launchURL(url);
      return;
    }
    final attributedUri = uri.replace(queryParameters: {
      ...uri.queryParameters,
      'utm_source': 'kin_app',
      'utm_medium': 'business_directory',
    });
    await launchURL(attributedUri.toString());
  }

  /// Opens the native share sheet with [text], then records a
  /// `share_app` Kindex engagement event for the signed-in user - the
  /// event feeds the same processUserEngagementEvent pipeline as
  /// reactions/reviews (see kindex_engine.js), so a share raises the
  /// user's Kindex score and is denormalized onto their ticker the same
  /// way. Recording the event is best-effort: the share sheet has
  /// already done its job by the time this runs, so a failure here
  /// (e.g. signed out, or a transient Firestore error) doesn't undo or
  /// block the share itself.
  /// Used by: Owner Profile -> "Promote" button.
  static Future<void> shareApp({
    required String text,
    Rect? sharePositionOrigin,
    DocumentReference? businessRef,
  }) async {
    await Share.share(text, sharePositionOrigin: sharePositionOrigin);
    final userRef = currentUserReference;
    if (userRef == null) return;
    try {
      await UserEngagementEventsRecord.collection.doc().set(
            createUserEngagementEventsRecordData(
              userRef: userRef,
              businessRef: businessRef,
              targetRef: businessRef,
              eventType: 'share_app',
              createdAt: getCurrentTimestamp,
            ),
          );
    } catch (_) {
      // Best-effort - see doc comment above.
    }
  }

  /// Adds [displayName] to the shared business_categories vocabulary if
  /// it isn't already there. Doc ID is the normalized (lowercase,
  /// trimmed) name, so this is idempotent - a `.set()` against an
  /// existing ID is a same-content overwrite, never a duplicate, and no
  /// existence check is needed first. Best-effort: called right before
  /// submitting a business/discovery request, and a failure here
  /// shouldn't block that submission - the category still gets attached
  /// to the business either way, it just wouldn't be pre-selectable for
  /// the next person until this succeeds.
  /// Used by: Business Setup, Add Business / Add Traveler Discovery
  /// dialogs' "Don't see your category?" field.
  static Future<void> ensureBusinessCategoryExists(String displayName) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return;
    try {
      await BusinessCategoriesRecord.collection
          .doc(trimmed.toLowerCase())
          .set(createBusinessCategoriesRecordData(
            displayName: trimmed,
            createdAt: getCurrentTimestamp,
          ));
    } catch (_) {
      // Best-effort - see doc comment above.
    }
  }

  /// Creates a Marketplace item (Phase 1, discovery only - see memory
  /// `marketplace-feature-phased-commission`). `priceDisplay` is free text,
  /// not a real chargeable amount, since there's no checkout yet.
  /// `interestCount` always starts at 0 - firestore.rules enforces this on
  /// create, so passing anything else here would just fail server-side.
  static Future<ServiceResult<DocumentReference>> createBusinessItem({
    required DocumentReference businessRef,
    required String title,
    String? description,
    required String priceDisplay,
    String? photoUrl,
    required String category,
    bool isAvailable = true,
  }) async {
    try {
      final itemRef = BusinessItemsRecord.collection.doc();
      await itemRef.set(createBusinessItemsRecordData(
        businessRef: businessRef,
        title: title,
        description: description,
        priceDisplay: priceDisplay,
        photoUrl: photoUrl,
        category: category,
        isAvailable: isAvailable,
        interestCount: 0,
        createdAt: getCurrentTimestamp,
        updatedAt: getCurrentTimestamp,
      ));
      return ServiceResult.success(itemRef);
    } catch (_) {
      return const ServiceResult.failure(
          'Could not add this item. Please try again.');
    }
  }

  /// Edits a Marketplace item's owner-writable fields. Never touches
  /// `interestCount` or moves it to a different business - both are
  /// frozen by firestore.rules on update, so a client attempt to change
  /// either is rejected server-side; this signature simply never offers
  /// the option.
  static Future<ServiceResult<void>> updateBusinessItem({
    required DocumentReference itemRef,
    String? title,
    String? description,
    String? priceDisplay,
    String? photoUrl,
    String? category,
    bool? isAvailable,
  }) async {
    try {
      await itemRef.update(createBusinessItemsRecordData(
        title: title,
        description: description,
        priceDisplay: priceDisplay,
        photoUrl: photoUrl,
        category: category,
        isAvailable: isAvailable,
        updatedAt: getCurrentTimestamp,
      ));
      return const ServiceResult.success();
    } catch (_) {
      return const ServiceResult.failure(
          'Could not save your changes. Please try again.');
    }
  }

  /// Reacts to a Marketplace item with one of `kQuickReactions`
  /// (`lib/components/exchange_feed_item_widget.dart`) - same
  /// deterministic-doc-ID dedup pattern as Exchange post reactions, so a
  /// duplicate tap is a harmless no-op rejected by firestore.rules rather
  /// than a second point award. Best-effort: the UI already reflects the
  /// reaction optimistically, so a failure here (including the expected
  /// "already reacted" rejection) doesn't need to surface to the user.
  /// showcase_interest.js listens for these events (any target_ref
  /// pointing into business_items) and increments the item's
  /// interest_count - no kindex_config change needed, since these event
  /// types are already weighted for Exchange reactions.
  static Future<void> recordItemReaction({
    required DocumentReference itemRef,
    required DocumentReference businessRef,
    required String eventType,
  }) async {
    final userRef = currentUserReference;
    if (userRef == null) return;
    final reactionRef = UserEngagementEventsRecord.collection.doc(
      '${userRef.id}_${itemRef.id}_$eventType',
    );
    try {
      await reactionRef.set(createUserEngagementEventsRecordData(
        userRef: userRef,
        businessRef: businessRef,
        targetRef: itemRef,
        eventType: eventType,
        createdAt: getCurrentTimestamp,
      ));
    } catch (_) {
      // Duplicate reaction for this user+item+type - already counted.
    }
  }

  /// The five reaction event types (see [recordItemReaction] and
  /// `kQuickReactions` in `exchange_feed_item_widget.dart`), listed here
  /// rather than imported since this is the only other place they're
  /// needed as a bare list rather than paired with icon/label/color.
  static const _kReactionEventTypes = [
    'react_backed',
    'react_kin',
    'react_built',
    'react_spotlight',
    'react_proud',
  ];

  /// "Recommended for you" on Customer Profile: a lightweight, deterministic
  /// heuristic (not real collaborative-filtering ML - the marketplace has
  /// near-zero items/users right now, so that would be over-building for a
  /// feature nobody's used yet). Looks up which categories [userRef] has
  /// already reacted to Marketplace items in, then returns other available
  /// items in those same categories, ranked by interest_count, excluding
  /// anything already reacted to. Returns `[]` (not an error) when the
  /// user has no reaction history yet - the caller hides the carousel
  /// entirely rather than showing a loading/empty state for it.
  static Future<List<BusinessItemsRecord>> fetchRecommendedItems({
    required DocumentReference userRef,
    int limit = 10,
  }) async {
    try {
      final reactions = await queryUserEngagementEventsRecordOnce(
        queryBuilder: (q) => q
            .where('user_ref', isEqualTo: userRef)
            .where('event_type', whereIn: _kReactionEventTypes),
      );
      if (reactions.isEmpty) return [];

      final reactedItemRefs = reactions
          .map((r) => r.targetRef)
          .whereType<DocumentReference>()
          .toSet();
      if (reactedItemRefs.isEmpty) return [];

      final reactedItems = await Future.wait(
        reactedItemRefs.map((ref) =>
            BusinessItemsRecord.getDocumentOnce(ref).catchError((_) => null)),
      );
      final reactedItemIds = reactedItemRefs.map((r) => r.id).toSet();
      final categories = reactedItems
          .whereType<BusinessItemsRecord>()
          .map((i) => i.category)
          .where((c) => c.isNotEmpty)
          .toSet()
          .take(5)
          .toList();
      if (categories.isEmpty) return [];

      final candidates = await queryBusinessItemsRecordOnce(
        queryBuilder: (q) => q
            .where('category', whereIn: categories)
            .where('is_available', isEqualTo: true)
            .orderBy('interest_count', descending: true)
            .limit(15),
      );

      return candidates
          .where((item) => !reactedItemIds.contains(item.reference.id))
          .take(limit)
          .toList();
    } catch (_) {
      // Best-effort - an optional discovery shelf failing to load is not
      // worth surfacing an error over; the caller just hides it.
      return [];
    }
  }

  /// Starts a Power Hour flash-beacon promotion, gated by the business's
  /// subscription_tier: [durationMinutes] is capped, and a rolling 30-day
  /// usage count is checked against a per-tier monthly limit (see
  /// _powerHourLimitsByTier). Fetches the business fresh rather than
  /// trusting the caller's possibly-stale cached data, since this is
  /// enforcing a real limit, not just display. checkAndExpireBeacons (a
  /// scheduled Cloud Function that already exists, see
  /// firebase/custom_cloud_functions) flips has_flash_beacon back to
  /// false once flash_beacon_expires_at passes - no new backend logic
  /// needed for expiry itself.
  /// Used by: Owner Profile -> Power Hour panel "Start" button.
  static Future<ServiceResult<void>> startPowerHour({
    required DocumentReference businessRef,
    required int durationMinutes,
  }) async {
    try {
      final business = await BusinessesRecord.getDocumentOnce(businessRef);
      final limits = _powerHourLimitsByTier[business.subscriptionTier] ??
          _defaultPowerHourLimits;

      final now = DateTime.now();
      final windowExpired = business.powerHourLastReset == null ||
          now.difference(business.powerHourLastReset!).inDays >= 30;
      final currentUsage = windowExpired ? 0 : business.powerHourUsageCount;

      if (limits.monthlyLimit != null && currentUsage >= limits.monthlyLimit!) {
        return ServiceResult.failure(
            _powerHourLimitMessage(business.subscriptionTier));
      }

      final cappedDuration = durationMinutes > limits.durationCapMinutes
          ? limits.durationCapMinutes
          : durationMinutes;
      final expiresAt = now.add(Duration(minutes: cappedDuration));

      await businessRef.update(createBusinessesRecordData(
        hasFlashBeacon: true,
        flashBeaconExpiresAt: expiresAt,
        flashBeaconDurationMinutes: cappedDuration,
        powerHourUsageCount: currentUsage + 1,
        powerHourLastReset:
            windowExpired ? now : (business.powerHourLastReset ?? now),
      ));
      return const ServiceResult.success();
    } catch (_) {
      return const ServiceResult.failure('Could not start Power Hour.');
    }
  }

  /// Ends a Power Hour promotion early. Only clears has_flash_beacon -
  /// leaves flash_beacon_expires_at as-is, since it's harmless once
  /// has_flash_beacon is false and every read of it already checks that
  /// flag first.
  /// Used by: Owner Profile -> Power Hour panel "Stop" button.
  static Future<ServiceResult<void>> stopPowerHour({
    required DocumentReference businessRef,
  }) async {
    try {
      await businessRef.update(createBusinessesRecordData(
        hasFlashBeacon: false,
      ));
      return const ServiceResult.success();
    } catch (_) {
      return const ServiceResult.failure('Could not stop Power Hour.');
    }
  }

  /// The Exchange terms version currently in force.
  ///
  /// Kept in Firestore rather than as a constant in this file so revising
  /// the terms is a single write instead of an app release. `firestore.rules`
  /// reads this same document when a post is created, so an older app build
  /// is held to exactly the same bar as a current one - which would not be
  /// true if each build carried its own hardcoded version string.
  ///
  /// Returns null if the document is missing or unreadable. Callers treat
  /// that as "cannot establish the current terms" and fail open on *reading*
  /// while the rule continues to fail closed on *posting*.
  static Future<String?> currentExchangeTermsVersion() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('legal_config')
          .doc('exchange_terms')
          .get();
      final version = snap.data()?['current_version'];
      return version is String && version.isNotEmpty ? version : null;
    } catch (_) {
      return null;
    }
  }

  /// Whether [uid] has accepted the Exchange terms *as they stand now*.
  ///
  /// Acceptance lives in `exchange_profiles`, keyed by uid so
  /// firestore.rules can check it with a get() when a post is created. The
  /// client check here is a UX affordance only - the rule is what actually
  /// enforces it.
  ///
  /// A profile that agreed to a superseded version counts as not accepted,
  /// so a terms revision re-prompts rather than silently letting someone
  /// post under terms they never saw.
  static Future<bool> hasAcceptedExchangeConduct(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('exchange_profiles')
          .doc(uid)
          .get();
      if (!snap.exists || snap.data()?['agreed_to_conduct'] != true) {
        return false;
      }
      final required = await currentExchangeTermsVersion();
      // No version on file means nothing to enforce against - don't lock
      // people out on a misconfigured config doc.
      if (required == null) return true;
      return snap.data()?['terms_version'] == required;
    } catch (_) {
      // Treat an unreadable profile as "not accepted" - the worst case is
      // the user is asked to accept again, whereas assuming acceptance
      // would send them into a post that the rules then reject.
      return false;
    }
  }

  /// Records acceptance of the Exchange terms.
  ///
  /// Doc ID is the uid, matching the rule in firestore.rules. Uses set with
  /// merge so re-accepting is harmless and never clobbers display_name.
  ///
  /// Stamps the version accepted and the time it happened, so a later terms
  /// revision can tell who agreed to what - `agreed_to_conduct: true` alone
  /// records that someone agreed to *something*, which is not much use if
  /// the terms have since changed.
  static Future<ServiceResult<void>> acceptExchangeConduct({
    required String uid,
    String? displayName,
  }) async {
    try {
      final version = await currentExchangeTermsVersion();
      await FirebaseFirestore.instance
          .collection('exchange_profiles')
          .doc(uid)
          .set({
        'user_ref': FirebaseFirestore.instance.collection('users').doc(uid),
        'display_name': displayName ?? '',
        'agreed_to_conduct': true,
        if (version != null) 'terms_version': version,
        'accepted_at': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return const ServiceResult.success();
    } catch (_) {
      return const ServiceResult.failure(
          'Could not save your agreement. Please try again.');
    }
  }

  /// Files a report against an Exchange post.
  ///
  /// Reports are write-only from the client (see firestore.rules) - an
  /// operator reads them with the Admin SDK. Nothing here can take a post
  /// down; only its author can delete it from the app.
  static Future<ServiceResult<void>> reportExchangePost({
    required DocumentReference postRef,
    required DocumentReference reporterRef,
    String? reason,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('exchange_post_reports').add({
        'post_ref': postRef,
        'reporter_ref': reporterRef,
        'reason': reason ?? '',
        'created_at': FieldValue.serverTimestamp(),
      });
      return const ServiceResult.success();
    } catch (_) {
      return const ServiceResult.failure('Could not send the report.');
    }
  }

  /// Files a report that a listing doesn't belong on KIN - almost always
  /// "this isn't a Black-owned business".
  ///
  /// Queued, never immediate. A report changes nothing a customer can see:
  /// the business stays listed until an admin acts on it. That asymmetry is
  /// the point - one tap from one stranger must not be able to delist a
  /// real Black-owned business, and a competitor shouldn't be able to
  /// knock a rival off the map. Same posture as [reportExchangePost].
  ///
  /// Admins get [hideBusiness] instead, which does take effect immediately.
  static Future<ServiceResult<void>> reportBusinessListing({
    required DocumentReference businessRef,
    required DocumentReference reporterRef,
    required String reason,
    String? note,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('business_reports').add({
        'business_ref': businessRef,
        'reporter_ref': reporterRef,
        'reason': reason,
        'note': note ?? '',
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      });
      return const ServiceResult.success();
    } catch (_) {
      return const ServiceResult.failure('Could not send the report.');
    }
  }

  /// Delists a business from every customer-facing surface. Admin only.
  ///
  /// Soft hide, not a delete. Two reasons: the bulk import can re-add a
  /// deleted row on its next run, so the tombstone has to survive; and
  /// removing the wrong business is one field away from being undone
  /// ([restoreBusiness]) instead of unrecoverable.
  ///
  /// Enforced server-side too - firestore.rules only lets a user with
  /// is_admin write these fields, so this isn't a client-side-only gate.
  static Future<ServiceResult<void>> hideBusiness({
    required DocumentReference businessRef,
    required DocumentReference adminRef,
    required String reason,
  }) async {
    try {
      await businessRef.update({
        'is_hidden': true,
        'hidden_reason': reason,
        'hidden_at': FieldValue.serverTimestamp(),
        'hidden_by': adminRef,
      });
      return const ServiceResult.success();
    } catch (_) {
      return const ServiceResult.failure('Could not remove this business.');
    }
  }

  /// Puts a delisted business back. Admin only.
  static Future<ServiceResult<void>> restoreBusiness({
    required DocumentReference businessRef,
  }) async {
    try {
      await businessRef.update({
        'is_hidden': false,
        'hidden_reason': '',
        'hidden_at': null,
        'hidden_by': null,
      });
      return const ServiceResult.success();
    } catch (_) {
      return const ServiceResult.failure('Could not restore this business.');
    }
  }

  /// Generates one AI social media post concept (caption + 3 hashtags + CTA
  /// + image concept) for [businessRef], optionally guided by [theme] (e.g.
  /// "weekend brunch special").
  ///
  /// The entitlement check (does this business's subscription_tier qualify)
  /// and the actual Gemini call both happen server-side, in the
  /// generateMarketingContent Cloud Function - never here. This method
  /// can't bypass that check by construction: it has no code path that
  /// calls Gemini directly, only one that asks the Cloud Function to. A
  /// modified/decompiled client could still call the Cloud Function
  /// directly, but it would hit the exact same server-side entitlement
  /// check, so there's no client-side shortcut to gate around.
  ///
  /// Calls the Cloud Function directly (not the generic makeCloudCall
  /// helper in backend/cloud_functions/cloud_functions.dart) specifically
  /// to surface the server's real error message - e.g. the "requires Pro
  /// Growth or Elite Growth" upgrade prompt - rather than a generic
  /// failure, matching the specific-message pattern startPowerHour
  /// already uses for its own tier-limit failures.
  /// Used by: Owner Profile -> Manage Your Business -> AI Marketing.
  static Future<ServiceResult<MarketingContent>> generateMarketingContent({
    required DocumentReference businessRef,
    String? theme,
  }) async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable(
        'generateMarketingContent',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 30),
        ),
      )
          .call<Map<String, dynamic>>({
        'businessRefPath': businessRef.path,
        if (theme != null && theme.isNotEmpty) 'theme': theme,
      });
      final data = result.data;
      return ServiceResult.success(MarketingContent(
        caption: data['caption'] as String,
        hashtags: List<String>.from(data['hashtags'] as List),
        cta: data['cta'] as String,
        imageConcept: data['image_concept'] as String,
        generationLogId: data['generationLogId'] as String,
      ));
    } on FirebaseFunctionsException catch (e) {
      return ServiceResult.failure(
          e.message ?? 'Could not generate marketing content.');
    } catch (_) {
      return const ServiceResult.failure(
          'Could not generate marketing content.');
    }
  }

  /// Generates a few AI logo preview images for an App Studio request, via
  /// the `generateAppStudioLogos` callable. Unlike [generateMarketingContent]
  /// this needs no signed-in business - App Studio is deliberately reachable
  /// without an account - so [contactName]/[contactEmail]/[brief] travel
  /// with every call instead of being read off a business doc server-side.
  /// Rate limiting (per-IP, per-email, and a global daily cap) all happens
  /// server-side; a 'resource-exhausted' rejection surfaces here as an
  /// ordinary failure message, not a crash.
  static Future<ServiceResult<List<String>>> generateAppStudioLogos({
    required String contactName,
    required String contactEmail,
    required String brief,
    String? businessName,
    String? style,
    String? colorPreference,
  }) async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable(
        'generateAppStudioLogos',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 90)),
      )
          .call<Map<String, dynamic>>({
        'contactName': contactName,
        'contactEmail': contactEmail,
        'brief': brief,
        if (businessName != null && businessName.isNotEmpty)
          'businessName': businessName,
        if (style != null && style.isNotEmpty) 'style': style,
        if (colorPreference != null && colorPreference.isNotEmpty)
          'colorPreference': colorPreference,
      });
      final urls = List<String>.from(result.data['logoUrls'] as List);
      return ServiceResult.success(urls);
    } on FirebaseFunctionsException catch (e) {
      return ServiceResult.failure(
          e.message ?? 'Could not generate logo previews.');
    } catch (_) {
      return const ServiceResult.failure(
          'Could not generate logo previews. Please try again.');
    }
  }

  /// Records what the owner did with an AI suggestion (used it as written,
  /// used it after editing, asked for another, or dismissed it) - the
  /// "user engagement with suggested posts" side of the AI analytics,
  /// separate from generation latency.
  ///
  /// [finalCaption] carries the owner's rewritten caption when [action] is
  /// `edited`. The generated original is already stored on the parent
  /// generation log, so the pair is what makes the edit legible - what the
  /// model wrote next to what the owner actually wanted. That gap is the
  /// strongest available signal about a business's real voice, and it only
  /// exists if it's captured at the moment of editing.
  ///
  /// Best-effort: a logging failure shouldn't block the owner from
  /// continuing to use the suggestion.
  /// Used by: Owner Profile -> AI Marketing suggestion card actions.
  static Future<void> logAiSuggestionEngagement({
    required String generationLogId,
    required String action,
    String? finalCaption,
  }) async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('logAiSuggestionEngagement')
          .call<void>({
        'generationLogId': generationLogId,
        'action': action,
        if (finalCaption != null && finalCaption.isNotEmpty)
          'finalCaption': finalCaption,
      });
    } catch (_) {
      // Best-effort - see doc comment above.
    }
  }

  /// Signs the current user out of every service the app signed them in to.
  ///
  /// `authManager.signOut()` alone only clears Firebase Auth. Two other
  /// sessions outlive it and have to be closed explicitly:
  ///
  ///   - Google keeps its own session, so the next sign-in would silently
  ///     reuse the previous Google account instead of offering the picker -
  ///     which on a shared device means signing back in as someone else.
  ///   - RevenueCat keeps attributing purchases to the old uid until it is
  ///     told otherwise, so entitlements could follow the wrong account.
  ///
  /// Both are best-effort: neither failing should trap someone in a signed-in
  /// state they asked to leave, so only the Firebase step decides the result.
  /// `signOutWithGoogle` is safe to call on an email/password session - it's
  /// a no-op when there's no Google session to clear.
  ///
  /// Navigation is deliberately left to the caller. The router refreshes on
  /// auth change unless `prepareAuthEvent()` is called first, so the widget
  /// has to own that ordering.
  ///
  /// Used by: the map page's hamburger menu -> Sign Out.
  /// Aggregated AI Marketing usage for the Executive Dashboard.
  ///
  /// The counting happens server-side: `ai_generation_logs` is `read:
  /// false` in firestore.rules because it stores generated captions and
  /// prompts, and it grows one document per generation, so a client-side
  /// tally would both over-share and re-read the whole collection on every
  /// dashboard open. The callable re-checks `is_admin` itself rather than
  /// trusting the page's redirect, which guards a screen and not an
  /// endpoint.
  /// Used by: Executive Dashboard -> AI Marketing.
  static Future<ServiceResult<AiMarketingStats>> getAiMarketingStats() async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('getAiMarketingStats')
          .call<Map<String, dynamic>>();
      final data = result.data;
      Map<String, int> counts(String key) => {
            for (final entry
                in (data[key] as Map? ?? const {}).entries.cast<MapEntry>())
              entry.key as String: (entry.value as num).toInt(),
          };
      return ServiceResult.success(AiMarketingStats(
        total: (data['total'] as num).toInt(),
        byStatus: counts('byStatus'),
        byTier: counts('byTier'),
        byEngagement: counts('byEngagement'),
        unrecognisedStatus: (data['unrecognisedStatus'] as num?)?.toInt() ?? 0,
        engagementUnavailable: data['engagementUnavailable'] == true,
      ));
    } on FirebaseFunctionsException catch (e) {
      return ServiceResult.failure(
          e.message ?? 'Could not load AI marketing stats.');
    } catch (_) {
      return const ServiceResult.failure('Could not load AI marketing stats.');
    }
  }

  /// Sends one message in the in-app support chat via the
  /// `sendSupportChatMessage` callable and returns the assistant's reply.
  /// [history] is recent prior turns from this session only, used purely as
  /// prompt context - the server is the source of truth for what actually
  /// gets logged.
  static Future<ServiceResult<SupportChatTurn>> sendSupportChatMessage({
    required String message,
    String? conversationId,
    String? visitorName,
    List<SupportChatTurn> history = const [],
  }) async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable(
        'sendSupportChatMessage',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      )
          .call<Map<String, dynamic>>({
        'message': message,
        if (conversationId != null) 'conversationId': conversationId,
        if (visitorName != null) 'visitorName': visitorName,
        'history': history.map((t) => t.toJson()).toList(),
      });
      final reply = result.data['reply'] as String? ?? '';
      return ServiceResult.success(
          SupportChatTurn(role: 'assistant', text: reply));
    } on FirebaseFunctionsException catch (e) {
      return ServiceResult.failure(
          e.message ?? 'Could not get a response right now.');
    } catch (_) {
      return const ServiceResult.failure(
          'Could not get a response right now. Please try again.');
    }
  }

  /// Admin-only aggregation of `support_chat_logs` for the Executive
  /// Dashboard - see `getSupportChatStats` (support_chat_stats.js).
  static Future<ServiceResult<SupportChatStats>> getSupportChatStats() async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('getSupportChatStats')
          .call<Map<String, dynamic>>();
      final data = result.data;
      final byCategory = {
        for (final entry in (data['byCategory'] as Map? ?? const {})
            .entries
            .cast<MapEntry>())
          entry.key as String: (entry.value as num).toInt(),
      };
      final recent = (data['recent'] as List? ?? const [])
          .cast<Map>()
          .map((r) => SupportChatRecentEntry(
                category: r['category'] as String? ?? 'other',
                summary: r['summary'] as String?,
                createdAt: r['createdAt'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                        (r['createdAt'] as num).toInt())
                    : null,
              ))
          .toList();
      return ServiceResult.success(SupportChatStats(
        total: (data['total'] as num).toInt(),
        byCategory: byCategory,
        unrecognisedCategory:
            (data['unrecognisedCategory'] as num?)?.toInt() ?? 0,
        recent: recent,
      ));
    } on FirebaseFunctionsException catch (e) {
      return ServiceResult.failure(
          e.message ?? 'Could not load support chat stats.');
    } catch (_) {
      return const ServiceResult.failure('Could not load support chat stats.');
    }
  }

  static Future<ServiceResult<void>> signOut() async {
    try {
      await revenue_cat.login(null);
    } catch (_) {
      // Best-effort - see doc comment above.
    }
    try {
      await signOutWithGoogle();
    } catch (_) {
      // Best-effort - see doc comment above.
    }
    try {
      await authManager.signOut();
      return const ServiceResult.success();
    } catch (_) {
      return const ServiceResult.failure(
          'Could not sign out. Please try again.');
    }
  }
}
