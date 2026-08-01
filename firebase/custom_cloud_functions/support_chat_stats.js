const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

// Aggregates support_chat_logs for the Executive Dashboard, same reasoning
// as ai_marketing_stats.js: firestore.rules denies all client reads on the
// collection (it's the closest thing this app has to a raw user-feedback
// inbox), so a dashboard tile has to go through a server aggregation rather
// than a client query, and count() queries keep that aggregation cheap
// regardless of how large the log grows.
const CATEGORIES = ["question", "bug_report", "suggestion", "praise", "other"];

// How many recent summaries the panel shows for an admin to skim themes at
// a glance. Summaries only - never `message` or `user_ref` - so the panel
// can show what people are asking about without becoming a place a user's
// literal words (or identity) show up in an admin's dashboard glance.
const RECENT_LIMIT = 15;

async function countWhere(query) {
  const snap = await query.count().get();
  return snap.data().count;
}

exports.getSupportChatStats = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const db = admin.firestore();
  const caller = await db.collection("users").doc(request.auth.uid).get();
  if (!caller.exists || caller.data().is_admin !== true) {
    throw new HttpsError("permission-denied", "Admin access required.");
  }

  const logs = db.collection("support_chat_logs");

  const [total, byCategory, recentSnap] = await Promise.all([
    countWhere(logs),
    Promise.all(
      CATEGORIES.map(async (c) => [c, await countWhere(logs.where("category", "==", c))]),
    ),
    logs.orderBy("created_at", "desc").limit(RECENT_LIMIT).get(),
  ]);

  const categoryCounts = Object.fromEntries(byCategory);
  const accountedFor = Object.values(categoryCounts).reduce((a, b) => a + b, 0);

  return {
    total,
    byCategory: categoryCounts,
    unrecognisedCategory: total - accountedFor,
    recent: recentSnap.docs.map((doc) => {
      const data = doc.data();
      return {
        category: data.category || "other",
        summary: data.summary || null,
        createdAt: data.created_at ? data.created_at.toMillis() : null,
      };
    }),
  };
});
