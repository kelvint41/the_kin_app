import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/firebase_auth/auth_util.dart';

import '../flutter_flow/flutter_flow_util.dart';
import '../flutter_flow/kindex_ticker_util.dart';
import 'schema/util/firestore_util.dart';

import 'schema/businesses_record.dart';
import 'schema/users_record.dart';
import 'schema/bug_reports_record.dart';
import 'schema/analytics_events_record.dart';
import 'schema/claim_requests_record.dart';
import 'schema/marketing_requests_record.dart';
import 'schema/orders_record.dart';
import 'schema/agency_queue_record.dart';
import 'schema/exchange_posts_record.dart';
import 'schema/exchange_profiles_record.dart';
import 'schema/activity_logs_record.dart';
import 'schema/analytics_daily_record.dart';
import 'schema/legal_metadata_record.dart';
import 'schema/exchange_promotions_record.dart';
import 'schema/exchange_prompts_record.dart';
import 'schema/connections_record.dart';
import 'schema/tier_privileges_record.dart';
import 'schema/entitlements_record.dart';
import 'schema/uservisits_record.dart';
import 'schema/reviews_record.dart';
import 'schema/user_engagement_events_record.dart';
import 'schema/kindex_scores_record.dart';
import 'schema/signup_feed_record.dart';
import 'schema/unlocked_rewards_record.dart';
import 'schema/kin_feed_events_record.dart';
import 'schema/notifications_record.dart';
import 'schema/business_categories_record.dart';
import 'schema/business_items_record.dart';

export 'dart:async' show StreamSubscription;
export 'package:cloud_firestore/cloud_firestore.dart' hide Order;
export 'package:firebase_core/firebase_core.dart';
export 'schema/index.dart';
export 'schema/util/firestore_util.dart';
export 'schema/util/schema_util.dart';

export 'schema/businesses_record.dart';
export 'schema/users_record.dart';
export 'schema/bug_reports_record.dart';
export 'schema/analytics_events_record.dart';
export 'schema/claim_requests_record.dart';
export 'schema/marketing_requests_record.dart';
export 'schema/orders_record.dart';
export 'schema/agency_queue_record.dart';
export 'schema/exchange_posts_record.dart';
export 'schema/activity_logs_record.dart';
export 'schema/analytics_daily_record.dart';
export 'schema/legal_metadata_record.dart';
export 'schema/exchange_promotions_record.dart';
export 'schema/exchange_prompts_record.dart';
export 'schema/connections_record.dart';
export 'schema/tier_privileges_record.dart';
export 'schema/entitlements_record.dart';
export 'schema/uservisits_record.dart';
export 'schema/reviews_record.dart';
export 'schema/user_engagement_events_record.dart';
export 'schema/kindex_scores_record.dart';
export 'schema/signup_feed_record.dart';
export 'schema/exchange_profiles_record.dart';
export 'schema/unlocked_rewards_record.dart';
export 'schema/kin_feed_events_record.dart';
export 'schema/business_submissions_record.dart';
export 'schema/system_counters_record.dart';
export 'schema/notifications_record.dart';
export 'schema/business_categories_record.dart';
export 'schema/business_items_record.dart';

/// Functions to query BusinessesRecords (as a Stream and as a Future).
Future<int> queryBusinessesRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      BusinessesRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<BusinessesRecord>> queryBusinessesRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      BusinessesRecord.collection,
      BusinessesRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<BusinessesRecord>> queryBusinessesRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      BusinessesRecord.collection,
      BusinessesRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );


/// Functions to query ExchangeProfilesRecords (as a Stream and as a Future).
Future<int> queryExchangeProfilesRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      ExchangeProfilesRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<ExchangeProfilesRecord>> queryExchangeProfilesRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      ExchangeProfilesRecord.collection,
      ExchangeProfilesRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<ExchangeProfilesRecord>> queryExchangeProfilesRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      ExchangeProfilesRecord.collection,
      ExchangeProfilesRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query UsersRecords (as a Stream and as a Future).
Future<int> queryUsersRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      UsersRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<UsersRecord>> queryUsersRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      UsersRecord.collection,
      UsersRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<UsersRecord>> queryUsersRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      UsersRecord.collection,
      UsersRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query BugReportsRecords (as a Stream and as a Future).
Future<int> queryBugReportsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      BugReportsRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<BugReportsRecord>> queryBugReportsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      BugReportsRecord.collection,
      BugReportsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<BugReportsRecord>> queryBugReportsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      BugReportsRecord.collection,
      BugReportsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query AnalyticsEventsRecords (as a Stream and as a Future).
Future<int> queryAnalyticsEventsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      AnalyticsEventsRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<AnalyticsEventsRecord>> queryAnalyticsEventsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      AnalyticsEventsRecord.collection,
      AnalyticsEventsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<AnalyticsEventsRecord>> queryAnalyticsEventsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      AnalyticsEventsRecord.collection,
      AnalyticsEventsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query ClaimRequestsRecords (as a Stream and as a Future).
Future<int> queryClaimRequestsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      ClaimRequestsRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<ClaimRequestsRecord>> queryClaimRequestsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      ClaimRequestsRecord.collection,
      ClaimRequestsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<ClaimRequestsRecord>> queryClaimRequestsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      ClaimRequestsRecord.collection,
      ClaimRequestsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query MarketingRequestsRecords (as a Stream and as a Future).
Future<int> queryMarketingRequestsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      MarketingRequestsRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<MarketingRequestsRecord>> queryMarketingRequestsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      MarketingRequestsRecord.collection,
      MarketingRequestsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<MarketingRequestsRecord>> queryMarketingRequestsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      MarketingRequestsRecord.collection,
      MarketingRequestsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query OrdersRecords (as a Stream and as a Future).
Future<int> queryOrdersRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      OrdersRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<OrdersRecord>> queryOrdersRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      OrdersRecord.collection,
      OrdersRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<OrdersRecord>> queryOrdersRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      OrdersRecord.collection,
      OrdersRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query AgencyQueueRecords (as a Stream and as a Future).
Future<int> queryAgencyQueueRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      AgencyQueueRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<AgencyQueueRecord>> queryAgencyQueueRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      AgencyQueueRecord.collection,
      AgencyQueueRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<AgencyQueueRecord>> queryAgencyQueueRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      AgencyQueueRecord.collection,
      AgencyQueueRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query ExchangePostsRecords (as a Stream and as a Future).
Future<int> queryExchangePostsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      ExchangePostsRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<ExchangePostsRecord>> queryExchangePostsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      ExchangePostsRecord.collection,
      ExchangePostsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<ExchangePostsRecord>> queryExchangePostsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      ExchangePostsRecord.collection,
      ExchangePostsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query ActivityLogsRecords (as a Stream and as a Future).
Future<int> queryActivityLogsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      ActivityLogsRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<ActivityLogsRecord>> queryActivityLogsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      ActivityLogsRecord.collection,
      ActivityLogsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<ActivityLogsRecord>> queryActivityLogsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      ActivityLogsRecord.collection,
      ActivityLogsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query AnalyticsDailyRecords (as a Stream and as a Future).
Future<int> queryAnalyticsDailyRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      AnalyticsDailyRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<AnalyticsDailyRecord>> queryAnalyticsDailyRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      AnalyticsDailyRecord.collection,
      AnalyticsDailyRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<AnalyticsDailyRecord>> queryAnalyticsDailyRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      AnalyticsDailyRecord.collection,
      AnalyticsDailyRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query LegalMetadataRecords (as a Stream and as a Future).
Future<int> queryLegalMetadataRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      LegalMetadataRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<LegalMetadataRecord>> queryLegalMetadataRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      LegalMetadataRecord.collection,
      LegalMetadataRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<LegalMetadataRecord>> queryLegalMetadataRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      LegalMetadataRecord.collection,
      LegalMetadataRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query ExchangePromotionsRecords (as a Stream and as a Future).
Future<int> queryExchangePromotionsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      ExchangePromotionsRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<ExchangePromotionsRecord>> queryExchangePromotionsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      ExchangePromotionsRecord.collection,
      ExchangePromotionsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<ExchangePromotionsRecord>> queryExchangePromotionsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      ExchangePromotionsRecord.collection,
      ExchangePromotionsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query ExchangePromptsRecords (as a Stream and as a Future).
Future<int> queryExchangePromptsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      ExchangePromptsRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<ExchangePromptsRecord>> queryExchangePromptsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      ExchangePromptsRecord.collection,
      ExchangePromptsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<ExchangePromptsRecord>> queryExchangePromptsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      ExchangePromptsRecord.collection,
      ExchangePromptsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query ConnectionsRecords (as a Stream and as a Future).
Future<int> queryConnectionsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      ConnectionsRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<ConnectionsRecord>> queryConnectionsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      ConnectionsRecord.collection,
      ConnectionsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<ConnectionsRecord>> queryConnectionsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      ConnectionsRecord.collection,
      ConnectionsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query TierPrivilegesRecords (as a Stream and as a Future).
Future<int> queryTierPrivilegesRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      TierPrivilegesRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<TierPrivilegesRecord>> queryTierPrivilegesRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      TierPrivilegesRecord.collection,
      TierPrivilegesRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<TierPrivilegesRecord>> queryTierPrivilegesRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      TierPrivilegesRecord.collection,
      TierPrivilegesRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query EntitlementsRecords (as a Stream and as a Future).
Future<int> queryEntitlementsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      EntitlementsRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<EntitlementsRecord>> queryEntitlementsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      EntitlementsRecord.collection,
      EntitlementsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<EntitlementsRecord>> queryEntitlementsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      EntitlementsRecord.collection,
      EntitlementsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query UservisitsRecords (as a Stream and as a Future).
Future<int> queryUservisitsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      UservisitsRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<UservisitsRecord>> queryUservisitsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      UservisitsRecord.collection,
      UservisitsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<UservisitsRecord>> queryUservisitsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      UservisitsRecord.collection,
      UservisitsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query NotificationsRecords (as a Stream and as a Future).
Future<int> queryNotificationsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      NotificationsRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<NotificationsRecord>> queryNotificationsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      NotificationsRecord.collection,
      NotificationsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<NotificationsRecord>> queryNotificationsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      NotificationsRecord.collection,
      NotificationsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query BusinessCategoriesRecords (as a Stream and as a Future).
Stream<List<BusinessCategoriesRecord>> queryBusinessCategoriesRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      BusinessCategoriesRecord.collection,
      BusinessCategoriesRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<BusinessCategoriesRecord>> queryBusinessCategoriesRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      BusinessCategoriesRecord.collection,
      BusinessCategoriesRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query BusinessItemsRecords (as a Stream and as a Future).
Stream<List<BusinessItemsRecord>> queryBusinessItemsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      BusinessItemsRecord.collection,
      BusinessItemsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<BusinessItemsRecord>> queryBusinessItemsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      BusinessItemsRecord.collection,
      BusinessItemsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query ReviewsRecords (as a Stream and as a Future).
Future<int> queryReviewsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      ReviewsRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<ReviewsRecord>> queryReviewsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      ReviewsRecord.collection,
      ReviewsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<ReviewsRecord>> queryReviewsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      ReviewsRecord.collection,
      ReviewsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query UserEngagementEventsRecords (as a Stream and as a Future).
Future<int> queryUserEngagementEventsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      UserEngagementEventsRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<UserEngagementEventsRecord>> queryUserEngagementEventsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      UserEngagementEventsRecord.collection,
      UserEngagementEventsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<UserEngagementEventsRecord>> queryUserEngagementEventsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      UserEngagementEventsRecord.collection,
      UserEngagementEventsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query KindexScoresRecords (as a Stream and as a Future).
Future<int> queryKindexScoresRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      KindexScoresRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<KindexScoresRecord>> queryKindexScoresRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      KindexScoresRecord.collection,
      KindexScoresRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<KindexScoresRecord>> queryKindexScoresRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      KindexScoresRecord.collection,
      KindexScoresRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<int> queryCollectionCount(
  Query collection, {
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(collection);
  if (limit > 0) {
    query = query.limit(limit);
  }

  return query.count().get().catchError((err) {
    print('Error querying $collection: $err');
  }).then((value) => value.count!);
}

Stream<List<T>> queryCollection<T>(
  Query collection,
  RecordBuilder<T> recordBuilder, {
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(collection);
  if (limit > 0 || singleRecord) {
    query = query.limit(singleRecord ? 1 : limit);
  }
  return query.snapshots().handleError((err) {
    print('Error querying $collection: $err');
  }).map((s) => s.docs
      .map(
        (d) => safeGet(
          () => recordBuilder(d),
          (e) => print('Error serializing doc ${d.reference.path}:\n$e'),
        ),
      )
      .where((d) => d != null)
      .map((d) => d!)
      .toList());
}

Future<List<T>> queryCollectionOnce<T>(
  Query collection,
  RecordBuilder<T> recordBuilder, {
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(collection);
  if (limit > 0 || singleRecord) {
    query = query.limit(singleRecord ? 1 : limit);
  }
  return query.get().then((s) => s.docs
      .map(
        (d) => safeGet(
          () => recordBuilder(d),
          (e) => print('Error serializing doc ${d.reference.path}:\n$e'),
        ),
      )
      .where((d) => d != null)
      .map((d) => d!)
      .toList());
}

Filter filterIn(String field, List? list) => (list?.isEmpty ?? true)
    ? Filter(field, whereIn: null)
    : Filter(field, whereIn: list);

Filter filterArrayContainsAny(String field, List? list) =>
    (list?.isEmpty ?? true)
        ? Filter(field, arrayContainsAny: null)
        : Filter(field, arrayContainsAny: list);

extension QueryExtension on Query {
  Query whereIn(String field, List? list) => (list?.isEmpty ?? true)
      ? where(field, whereIn: null)
      : where(field, whereIn: list);

  Query whereNotIn(String field, List? list) => (list?.isEmpty ?? true)
      ? where(field, whereNotIn: null)
      : where(field, whereNotIn: list);

  Query whereArrayContainsAny(String field, List? list) =>
      (list?.isEmpty ?? true)
          ? where(field, arrayContainsAny: null)
          : where(field, arrayContainsAny: list);
}

class FFFirestorePage<T> {
  final List<T> data;
  final Stream<List<T>>? dataStream;
  final QueryDocumentSnapshot? nextPageMarker;

  FFFirestorePage(this.data, this.dataStream, this.nextPageMarker);
}

Future<FFFirestorePage<T>> queryCollectionPage<T>(
  Query collection,
  RecordBuilder<T> recordBuilder, {
  Query Function(Query)? queryBuilder,
  DocumentSnapshot? nextPageMarker,
  required int pageSize,
  required bool isStream,
}) async {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(collection).limit(pageSize);
  if (nextPageMarker != null) {
    query = query.startAfterDocument(nextPageMarker);
  }
  Stream<QuerySnapshot>? docSnapshotStream;
  QuerySnapshot docSnapshot;
  if (isStream) {
    docSnapshotStream = query.snapshots();
    docSnapshot = await docSnapshotStream.first;
  } else {
    docSnapshot = await query.get();
  }
  final getDocs = (QuerySnapshot s) => s.docs
      .map(
        (d) => safeGet(
          () => recordBuilder(d),
          (e) => print('Error serializing doc ${d.reference.path}:\n$e'),
        ),
      )
      .where((d) => d != null)
      .map((d) => d!)
      .toList();
  final data = getDocs(docSnapshot);
  final dataStream = docSnapshotStream?.map(getDocs);
  final nextPageToken = docSnapshot.docs.isEmpty ? null : docSnapshot.docs.last;
  return FFFirestorePage(data, dataStream, nextPageToken);
}

// Creates a Firestore document representing the logged in user if it doesn't yet exist
Future maybeCreateUser(User user) async {
  final userRecord = UsersRecord.collection.doc(user.uid);
  final userExists = await userRecord.get().then((u) => u.exists);
  if (userExists) {
    currentUserDocument = await UsersRecord.getDocumentOnce(userRecord);
    return;
  }

  final displayName =
      user.displayName ?? FirebaseAuth.instance.currentUser?.displayName;

  // Best-effort Kindex ticker symbol for the onboarding ticker's customer
  // row. Reserved against `ticker_registry` (see KindexTickerUtil) since
  // the self-only `users` collection can't be queried for a uniqueness
  // check. A failure here should never block account creation, so this
  // just leaves ticker_symbol unset rather than surfacing an error.
  String? tickerSymbol;
  if (displayName != null) {
    final semantic = KindexTickerUtil.semanticCandidate(displayName);
    if (semantic != null &&
        await KindexTickerUtil.reserve(semantic, userRecord)) {
      tickerSymbol = semantic;
    }
  }
  for (var attempt = 0; tickerSymbol == null && attempt < 3; attempt++) {
    final candidate = KindexTickerUtil.randomCandidate();
    if (await KindexTickerUtil.reserve(candidate, userRecord)) {
      tickerSymbol = candidate;
    }
  }

  final userData = createUsersRecordData(
    email: user.email ??
        FirebaseAuth.instance.currentUser?.email ??
        user.providerData.firstOrNull?.email,
    displayName: displayName,
    tickerSymbol: tickerSymbol,
    photoUrl: user.photoURL,
    uid: user.uid,
    phoneNumber: user.phoneNumber,
    createdTime: getCurrentTimestamp,
  );

  await userRecord.set(userData);
  currentUserDocument = UsersRecord.getDocumentFromData(userData, userRecord);

  // Denormalized admin-facing feed of new signups. The `users` collection
  // itself can't be listed by admins (rules only allow reading your own
  // doc), so this is written once here, at the single point every new
  // account is created regardless of sign-in method.
  await SignupFeedRecord.collection.add(createSignupFeedRecordData(
    userRef: userRecord,
    displayName: currentUserDocument?.displayName,
    subscriptionStatus: currentUserDocument?.subscriptionStatus,
    timestamp: getCurrentTimestamp,
  ));
}

Future updateUserDocument({String? email}) async {
  await currentUserDocument?.reference
      .update(createUsersRecordData(email: email));
}

/// Functions to query SignupFeedRecords (as a Stream and as a Future).
Future<int> querySignupFeedRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      SignupFeedRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<SignupFeedRecord>> querySignupFeedRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      SignupFeedRecord.collection,
      SignupFeedRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query UnlockedRewardsRecords (as a Stream and as a Future).
Future<int> queryUnlockedRewardsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      UnlockedRewardsRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<UnlockedRewardsRecord>> queryUnlockedRewardsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      UnlockedRewardsRecord.collection,
      UnlockedRewardsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<UnlockedRewardsRecord>> queryUnlockedRewardsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      UnlockedRewardsRecord.collection,
      UnlockedRewardsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query KinFeedEventsRecords (as a Stream and as a Future).
Future<int> queryKinFeedEventsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      KinFeedEventsRecord.collection,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<KinFeedEventsRecord>> queryKinFeedEventsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      KinFeedEventsRecord.collection,
      KinFeedEventsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<KinFeedEventsRecord>> queryKinFeedEventsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      KinFeedEventsRecord.collection,
      KinFeedEventsRecord.fromSnapshot,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );
