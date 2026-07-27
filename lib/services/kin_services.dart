import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/kindex_ticker_util.dart';
import '/flutter_flow/place.dart';
import '/flutter_flow/revenue_cat_util.dart' as revenue_cat;
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:share_plus/share_plus.dart';

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
  const _PowerHourLimits({required this.durationCapMinutes, this.weeklyLimit});

  final int durationCapMinutes;

  /// Max Power Hours per rolling 7-day window. Null means unlimited -
  /// skip the frequency check entirely.
  final int? weeklyLimit;
}

/// Real subscription_tier values, as written by the live upgrade flow in
/// merchant_pricing_suite_widget.dart - not the generic 'Community' /
/// 'Pro' / 'Elite' names a first pass might assume. Any business whose
/// subscription_tier isn't one of these keys (a typo, or an ad-hoc value
/// like 'Founder'/'unlimited' set outside the normal upgrade flow) falls
/// through to [_defaultPowerHourLimits] rather than risk granting
/// broader access than intended.
const _powerHourLimitsByTier = <String, _PowerHourLimits>{
  'Community': _PowerHourLimits(durationCapMinutes: 30, weeklyLimit: 1),
  'Founding Local': _PowerHourLimits(durationCapMinutes: 45, weeklyLimit: 2),
  'Pro Growth': _PowerHourLimits(durationCapMinutes: 60, weeklyLimit: 3),
  'Elite Growth': _PowerHourLimits(durationCapMinutes: 90, weeklyLimit: null),
};
const _defaultPowerHourLimits =
    _PowerHourLimits(durationCapMinutes: 30, weeklyLimit: 1);

String _powerHourLimitMessage(String tier) {
  switch (tier) {
    case 'Community':
      return "You've reached your weekly Power Hour limit. Upgrade to "
          'Founding Local or Pro Growth for more!';
    case 'Founding Local':
      return "You've reached your weekly Power Hour limit for Founding "
          'Local. Upgrade to Pro Growth for more!';
    case 'Pro Growth':
      return "You've reached your weekly Power Hour limit for Pro Growth. "
          'Upgrade to Elite Growth for unlimited Power Hours!';
    default:
      return "You've reached your weekly Power Hour limit. Upgrade your "
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
            status: 'pending',
            timestamp: now,
          ));
      return const ServiceResult.success();
    } catch (_) {
      return const ServiceResult.failure(
          'Could not submit your claim. Please try again.');
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

  /// Starts a Power Hour flash-beacon promotion, gated by the business's
  /// subscription_tier: [durationMinutes] is capped, and a rolling
  /// 7-day usage count is checked against a per-tier weekly limit (see
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
          now.difference(business.powerHourLastReset!).inDays >= 7;
      final currentUsage = windowExpired ? 0 : business.powerHourUsageCount;

      if (limits.weeklyLimit != null && currentUsage >= limits.weeklyLimit!) {
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

  /// Whether [userRef]'s owner has accepted the Exchange code of conduct.
  ///
  /// Acceptance lives in `exchange_profiles`, keyed by uid so
  /// firestore.rules can check it in a single get() when a post is created.
  /// The client check here is a UX affordance only - the rule is what
  /// actually enforces it.
  static Future<bool> hasAcceptedExchangeConduct(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('exchange_profiles')
          .doc(uid)
          .get();
      return snap.exists && snap.data()?['agreed_to_conduct'] == true;
    } catch (_) {
      // Treat an unreadable profile as "not accepted" - the worst case is
      // the user is asked to accept again, whereas assuming acceptance
      // would send them into a post that the rules then reject.
      return false;
    }
  }

  /// Records acceptance of the Exchange code of conduct.
  ///
  /// Doc ID is the uid, matching the rule in firestore.rules. Uses set with
  /// merge so re-accepting is harmless and never clobbers display_name.
  static Future<ServiceResult<void>> acceptExchangeConduct({
    required String uid,
    String? displayName,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('exchange_profiles')
          .doc(uid)
          .set({
        'user_ref': FirebaseFirestore.instance.collection('users').doc(uid),
        'display_name': displayName ?? '',
        'agreed_to_conduct': true,
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

  /// Records what the owner did with an AI suggestion (used it, asked for
  /// another, or dismissed it) - the "user engagement with suggested
  /// posts" side of the AI analytics, separate from generation latency.
  /// Best-effort: a logging failure shouldn't block the owner from
  /// continuing to use the suggestion.
  /// Used by: Owner Profile -> AI Marketing suggestion card actions.
  static Future<void> logAiSuggestionEngagement({
    required String generationLogId,
    required String action,
  }) async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('logAiSuggestionEngagement')
          .call<void>({
        'generationLogId': generationLogId,
        'action': action,
      });
    } catch (_) {
      // Best-effort - see doc comment above.
    }
  }
}
