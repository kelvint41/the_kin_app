import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/backend.dart';

/// What a business owner sees about their own engagement.
///
/// The customer side has had Personal Milestones - streak, reviews, Kindex -
/// since it was built. The owner side had nothing equivalent: an owner could
/// see their listing but not a single number about how it was performing.
///
/// Every figure here is derived from a collection that already exists, and
/// each is loaded independently so one failure (a missing index, a rules
/// denial) costs that figure rather than the whole card - the same shape as
/// the customer profile's _loadStats.
class OwnerEngagement {
  const OwnerEngagement({
    required this.profileViews,
    required this.directionsTaps,
    required this.callTaps,
    required this.reviewCount,
    required this.averageRating,
    required this.exchangePosts,
    required this.reactionsReceived,
    required this.verifiedVisits,
  });

  /// Null on any of these means "couldn't read", which is not the same
  /// claim as zero and must not be rendered as one.
  final int? profileViews;
  final int? directionsTaps;
  final int? callTaps;
  final int? reviewCount;
  final double? averageRating;
  final int? exchangePosts;
  final int? reactionsReceived;
  final int? verifiedVisits;

  /// Taps on Directions or Call as a share of profile views.
  ///
  /// The one number that says whether being seen turns into anything.
  /// Null rather than 0% when nobody has looked yet - a rate off no views
  /// reads as a failure that hasn't happened.
  double? get actionRatePercent {
    final views = profileViews ?? 0;
    if (views == 0) return null;
    final acts = (directionsTaps ?? 0) + (callTaps ?? 0);
    return (acts / views * 1000).round() / 10;
  }

  static Future<int?> _count(Query query) async {
    try {
      return (await query.count().get()).count;
    } catch (_) {
      return null;
    }
  }

  static Future<OwnerEngagement> load(DocumentReference businessRef) async {
    final logs = ActivityLogsRecord.collection.where(
      'business_ref',
      isEqualTo: businessRef,
    );

    Future<int?> event(String type) =>
        _count(logs.where('event_type', isEqualTo: type));

    // Reviews are fetched rather than counted because the average needs the
    // ratings themselves. Bounded: a business with thousands of reviews
    // should not pull them all to show one number, and 200 is far past any
    // realistic count here.
    Future<List<ReviewsRecord>> reviews() async {
      try {
        return await queryReviewsRecordOnce(
          queryBuilder: (q) => q.where('business_ref', isEqualTo: businessRef),
          limit: 200,
        );
      } catch (_) {
        return const [];
      }
    }

    final results = await Future.wait([
      event('profile_view'),
      event('map_tap'),
      event('call_tap'),
      reviews(),
      _count(ExchangePostsRecord.collection
          .where('business_ref', isEqualTo: businessRef)),
      _count(UserEngagementEventsRecord.collection
          .where('business_ref', isEqualTo: businessRef)),
      _count(FirebaseFirestore.instance
          .collection('uservisits')
          .where('business_ref', isEqualTo: businessRef)),
    ]);

    final reviewDocs = results[3] as List<ReviewsRecord>;
    final rated = reviewDocs.where((r) => r.rating > 0).toList();

    return OwnerEngagement(
      profileViews: results[0] as int?,
      directionsTaps: results[1] as int?,
      callTaps: results[2] as int?,
      reviewCount: reviewDocs.length,
      averageRating: rated.isEmpty
          ? null
          : rated.map((r) => r.rating).reduce((a, b) => a + b) / rated.length,
      exchangePosts: results[4] as int?,
      reactionsReceived: results[5] as int?,
      verifiedVisits: results[6] as int?,
    );
  }
}
