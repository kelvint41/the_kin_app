const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

// Everything else the app records, aggregated for the Executive Dashboard.
//
// Server-side for the same reasons as getAiMarketingStats, plus one more:
// claim_requests is `read: false` in firestore.rules and holds applicant
// email addresses and phone numbers. Counts of it can be safely shown to
// an admin; the documents cannot be handed to a client just to count them.
//
// Every figure here is a count() aggregation. That matters because
// activity_logs and kindex_score_history are the two collections that grow
// without bound - kindex_score_history gains one row per business per
// night, so it outgrows everything else in the project by design - and
// reading them to count them would get slower every day the app runs.
//
// The cost of count()-only is that grouped totals need one query per key,
// so the keys have to be known in advance. They're listed below, and
// anything outside the list shows up in the `other` remainder rather than
// vanishing from the total.

// activity_logs.event_type, as written by the pages that log it.
const ACTIVITY_EVENTS = ["page_view", "map_tap", "call_tap", "directions_tap", "share_tap"];

// The subset of ACTIVITY_EVENTS that represents a user doing something
// with a business rather than merely arriving somewhere. This split is the
// point of the panel: page views measure reach, these measure whether
// reach turns into anything.
const ACTIVITY_INTERACTIONS = ["map_tap", "call_tap", "directions_tap", "share_tap"];

// UserEngagementEvents.event_type - the actions the Kindex engine scores.
const ENGAGEMENT_EVENTS = ["post", "review", "share_app", "check_in", "referral"];

const CLAIM_STATUSES = ["pending", "approved", "rejected"];

// business_submissions.review_status - the "unlisted business" discovery
// pipeline (submit -> admin review -> discovery bonus). Absent means
// "pending" (see admin_submissions_page.dart's own null-matching comment
// for why that's checked separately rather than as a query key here).
const SUBMISSION_STATUSES = ["approved", "dismissed"];

// Businesses seeded from the Georgia/Illinois directory-pull test batch
// (seed_directory_test_batch.js) - tracked by name here rather than a
// generic "businesses added today" figure, since imports are occasional
// batches, not a steady daily trickle worth a rolling window for.
const DIRECTORY_IMPORT_BATCHES = ["ga_il_test_2026_08"];

async function countWhere(query) {
  try {
    const snap = await query.count().get();
    return snap.data().count;
  } catch (_) {
    // One missing index shouldn't cost the whole dashboard - same rule as
    // getAiMarketingStats. Null means "couldn't read", not zero.
    return null;
  }
}

async function groupCounts(col, field, keys) {
  const pairs = await Promise.all(
    keys.map(async (k) => [k, await countWhere(col.where(field, "==", k))]),
  );
  return Object.fromEntries(pairs.filter(([, n]) => n !== null && n > 0));
}

exports.getOperationsStats = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const db = admin.firestore();
  const caller = await db.collection("users").doc(request.auth.uid).get();
  if (!caller.exists || caller.data().is_admin !== true) {
    throw new HttpsError("permission-denied", "Admin access required.");
  }

  const activity = db.collection("activity_logs");
  const engagement = db.collection("UserEngagementEvents");
  const history = db.collection("kindex_score_history");
  const claims = db.collection("claim_requests");
  const visits = db.collection("uservisits");
  const ownershipReports = db.collection("business_ownership_reports");
  const submissions = db.collection("business_submissions");
  const businesses = db.collection("businesses");

  const [
    activityTotal,
    activityByEvent,
    engagementTotal,
    engagementByEvent,
    engagementPending,
    historyTotal,
    withDecay,
    withQualifyingReviews,
    withVerifiedVisits,
    claimsByStatus,
    claimsTotal,
    reviewsTotal,
    entitlementsTotal,
    visitsTotal,
    visitsWithPoints,
    mysteryFindsTotal,
    ownershipReportsBlackOwned,
    ownershipReportsNotBlackOwned,
    ownershipReportsTotal,
    questStatsSnap,
    submissionsByStatus,
    submissionsTotal,
    directoryImportedByBatch,
  ] = await Promise.all([
    countWhere(activity),
    groupCounts(activity, "event_type", ACTIVITY_EVENTS),
    countWhere(engagement),
    groupCounts(engagement, "event_type", ENGAGEMENT_EVENTS),
    // Events the Kindex engine hasn't consumed. A number that climbs here
    // means the trigger has stopped firing, which is otherwise silent.
    countWhere(engagement.where("status", "==", "pending")),
    countWhere(history),
    // Single-field inequalities, because Firestore can't compare
    // score_before to score_after in a query. These three answer the same
    // question from the other side: is the scoring engine being fed
    // anything at all, or is it recomputing 500 into 500 every night?
    countWhere(history.where("decay_applied", ">", 0)),
    countWhere(history.where("qualifying_review_count", ">", 0)),
    countWhere(history.where("verified_visit_count", ">", 0)),
    groupCounts(claims, "status", CLAIM_STATUSES),
    countWhere(claims),
    countWhere(db.collection("reviews")),
    countWhere(db.collection("entitlements")),
    countWhere(visits),
    // Real payouts only - excludes the 0-point duplicate/repeat-visit
    // rows recordVerifiedVisit still logs (see that file's dedup and
    // one-time-per-business rules).
    countWhere(visits.where("points_awarded", ">", 0)),
    countWhere(visits.where("was_mystery_find", "==", true)),
    countWhere(ownershipReports.where("is_black_owned", "==", true)),
    countWhere(ownershipReports.where("is_black_owned", "==", false)),
    countWhere(ownershipReports),
    db.collection("quest_stats").doc("totals").get(),
    groupCounts(submissions, "review_status", SUBMISSION_STATUSES),
    countWhere(submissions),
    groupCounts(businesses, "directory_import_batch", DIRECTORY_IMPORT_BATCHES),
  ]);

  const questStats = questStatsSnap.exists ? questStatsSnap.data() : {};
  const submissionsAccounted = Object.values(submissionsByStatus).reduce((a, b) => a + b, 0);
  // Not accounted for by the named statuses above - absent review_status
  // reads as "pending", same reasoning admin_submissions_page.dart's own
  // client-side filter gives for treating a missing field as pending
  // rather than querying for it directly (a Firestore equality clause
  // can't match "field is absent").
  const submissionsPending =
    submissionsTotal === null ? null : submissionsTotal - submissionsAccounted;

  const interactions = ACTIVITY_INTERACTIONS.reduce(
    (sum, k) => sum + (activityByEvent[k] || 0),
    0,
  );
  const pageViews = activityByEvent.page_view || 0;

  const accountedActivity = Object.values(activityByEvent).reduce((a, b) => a + b, 0);
  const claimsAccounted = Object.values(claimsByStatus).reduce((a, b) => a + b, 0);

  return {
    activity: {
      total: activityTotal,
      byEvent: activityByEvent,
      other: activityTotal === null ? null : activityTotal - accountedActivity,
      pageViews,
      interactions,
      // Null rather than 0/0 when there's nothing to divide - a rate of
      // "0%" off no page views reads as a failure that hasn't happened.
      interactionRatePercent:
        pageViews > 0 ? Math.round((interactions / pageViews) * 1000) / 10 : null,
    },
    engagement: {
      total: engagementTotal,
      byEvent: engagementByEvent,
      pending: engagementPending,
    },
    kindex: {
      historyRows: historyTotal,
      withDecay,
      withQualifyingReviews,
      withVerifiedVisits,
    },
    claims: {
      total: claimsTotal,
      byStatus: claimsByStatus,
      other: claimsTotal === null ? null : claimsTotal - claimsAccounted,
    },
    reviews: reviewsTotal,
    entitlements: entitlementsTotal,
    // Everything added this session for the new KIN Quest map/scoring
    // system - see KinQuestMapDemoWidget, visit_verification.js's
    // pointsForCheckIn/isSmallBusinessSaturday, business_discovery.js's
    // discovery bonus, and business_ownership_reports.
    questActivity: {
      checkins: {
        total: visitsTotal,
        withPoints: visitsWithPoints,
        mysteryFinds: mysteryFindsTotal,
        pointsTotal: questStats.checkin_points_total || 0,
      },
      unlistedDiscoveries: {
        approvedCount: questStats.discovery_bonus_count || 0,
        pointsTotal: questStats.discovery_bonus_points_total || 0,
      },
      smallBusinessSaturday: {
        pointsTotal: questStats.small_business_saturday_points_total || 0,
      },
      ownershipReports: {
        total: ownershipReportsTotal,
        blackOwned: ownershipReportsBlackOwned,
        notBlackOwned: ownershipReportsNotBlackOwned,
      },
      submissions: {
        total: submissionsTotal,
        pending: submissionsPending,
        byStatus: submissionsByStatus,
      },
      directoryImports: directoryImportedByBatch,
    },
  };
});
