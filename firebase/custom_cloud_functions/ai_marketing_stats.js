const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

// Aggregates ai_generation_logs for the Executive Dashboard.
//
// Server-side rather than a client query, for two reasons. First,
// firestore.rules keeps ai_generation_logs at `read: false` - the logs hold
// the generated captions and the prompts that produced them, and the
// dashboard only needs counts, so opening the whole collection to satisfy a
// tile would hand the client far more than it asked for. Second, this
// collection grows by one document per generation forever: a client-side
// count would re-read every row ever written on each page open, which is
// the same unbounded-read shape that was just removed from GoogleMapPage.
//
// Uses count() aggregation queries, which bill at a fraction of a document
// read each and return no document data at all - so a dashboard open costs
// roughly the same whether there is one log or a hundred thousand.

// The statuses generateMarketingContent writes. Listed explicitly so a new
// status added there shows up here as a missing bucket rather than being
// silently folded into a total nobody questions.
const STATUSES = ["success", "rejected_not_entitled", "rejected_quota_exceeded", "error"];

// Mirrors ENTITLED_TIERS plus the tiers that can only ever be rejected -
// the rejected-by-tier split is the point of the panel, so the unentitled
// tiers matter as much as the entitled ones.
const TIERS = ["Community", "Founding Local", "Pro Growth", "Elite Growth"];

// From logAiSuggestionEngagement's validActions.
const ACTIONS = ["used", "edited", "regenerated", "dismissed"];

async function countWhere(query) {
  const snap = await query.count().get();
  return snap.data().count;
}

exports.getAiMarketingStats = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const db = admin.firestore();

  // Admin is checked here rather than trusted from the client. The
  // dashboard page already redirects non-admins on load, but that is a UX
  // guard on a screen, not an access control - the callable is reachable
  // directly.
  const caller = await db.collection("users").doc(request.auth.uid).get();
  if (!caller.exists || caller.data().is_admin !== true) {
    throw new HttpsError("permission-denied", "Admin access required.");
  }

  const logs = db.collection("ai_generation_logs");

  const [total, byStatus, byTier, byAction] = await Promise.all([
    countWhere(logs),
    Promise.all(
      STATUSES.map(async (s) => [s, await countWhere(logs.where("status", "==", s))]),
    ),
    Promise.all(
      TIERS.map(async (t) => [t, await countWhere(logs.where("subscription_tier", "==", t))]),
    ),
    // collectionGroup, because engagement lives in a subcollection under
    // each log. Counting it per-parent would be one query per log.
    //
    // Degrades on its own rather than taking the panel down with it. This
    // query needs a COLLECTION_GROUP_ASC exemption on engagement.action
    // (see firestore.indexes.json); before that index existed the whole
    // callable returned INTERNAL and the panel showed nothing, when the
    // request/status/tier counts beside it were all perfectly readable.
    // A missing index on one row of a dashboard should cost that row.
    Promise.all(
      ACTIONS.map(async (a) => {
        try {
          return [
            a,
            await countWhere(
              db.collectionGroup("engagement").where("action", "==", a),
            ),
          ];
        } catch (_) {
          return [a, null];
        }
      }),
    ),
  ]);

  const statusCounts = Object.fromEntries(byStatus);

  // Anything whose status isn't one of STATUSES. Surfaced rather than
  // dropped: a non-zero value here means this function is out of date with
  // the orchestrator, and a dashboard that quietly under-reports is worse
  // than one that admits it doesn't recognise a row.
  const accountedFor = Object.values(statusCounts).reduce((a, b) => a + b, 0);

  return {
    total,
    byStatus: statusCounts,
    unrecognisedStatus: total - accountedFor,
    byTier: Object.fromEntries(byTier),
    // Nulls (a failed count) are dropped rather than sent as zero: "we
    // couldn't read this" and "this happened zero times" are different
    // claims, and the second one is the kind a dashboard should never
    // make up.
    byEngagement: Object.fromEntries(byAction.filter(([, n]) => n !== null)),
    engagementUnavailable: byAction.some(([, n]) => n === null),
  };
});
