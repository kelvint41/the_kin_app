// Tests for the customer-side nightly Kindex recompute.
//
// Mirrors the business-side rules: capped nightly movement toward a
// windowed target, escalating inactivity decay with a floor, and a dedup
// rule so repeat engagement with one business can't be farmed.

const assert = require("node:assert/strict");
const { test, beforeEach } = require("node:test");

const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp({ projectId: "demo-kin-test" });
}

const customerNightly = require("../customer_kindex_nightly.js");
const { qualifyingPointsForCustomer, recomputeAll, resetWeightsCache } =
  customerNightly._internals;

const db = admin.firestore();

let counter = 0;
const uniq = (p) => `${p}_${++counter}`;

const WEIGHTS = {
  post: 10,
  share_app: 10,
  call_tap: 5,
  share: 5,
  comment: 2,
  map_tap: 2,
  like: 1,
  page_view: 1,
};

async function clear(collection) {
  const snap = await db.collection(collection).get();
  await Promise.all(snap.docs.map((d) => d.ref.delete()));
}

beforeEach(async () => {
  await Promise.all([
    clear("KindexScores"),
    clear("UserEngagementEvents"),
    clear("kindex_score_history"),
  ]);
  await db.collection("kindex_config").doc("scoring_weights").set(WEIGHTS);
  resetWeightsCache();
});

const daysAgo = (n) =>
  admin.firestore.Timestamp.fromMillis(Date.now() - n * 24 * 60 * 60 * 1000);

async function seedCustomer({
  score = 0,
  events = [],
  lastActivityDaysAgo,
  decayedThroughWeek,
}) {
  const userId = uniq("user");
  const userRef = db.collection("users").doc(userId);
  await db
    .collection("KindexScores")
    .doc(userId)
    .set({
      user_ref: userRef,
      score,
      ...(lastActivityDaysAgo === undefined
        ? {}
        : { last_activity_at: daysAgo(lastActivityDaysAgo) }),
      ...(decayedThroughWeek === undefined
        ? {}
        : { decayed_through_week: decayedThroughWeek }),
    });

  for (const e of events) {
    await db
      .collection("UserEngagementEvents")
      .doc(uniq("event"))
      .set({
        user_ref: userRef,
        ...(e.business
          ? { business_ref: db.collection("businesses").doc(e.business) }
          : {}),
        event_type: e.type,
        status: e.status ?? "processed",
        created_at: daysAgo(e.daysAgo ?? 1),
      });
  }
  return db.collection("KindexScores").doc(userId);
}

async function scoreAfter(scoreRef) {
  await recomputeAll(db, Date.now());
  return (await scoreRef.get()).data().score;
}

// --- Dedup rule --------------------------------------------------------

test("repeat engagement with one business counts once, at its best event", () => {
  const events = [
    { business_ref: { id: "bizA" }, event_type: "like" }, // 1
    { business_ref: { id: "bizA" }, event_type: "call_tap" }, // 5
    { business_ref: { id: "bizA" }, event_type: "like" }, // 1
  ];
  const result = qualifyingPointsForCustomer(events, WEIGHTS);
  assert.equal(result.total, 5);
  assert.equal(result.distinctBusinesses, 1);
});

test("engaging with several businesses is worth more than repeating one", () => {
  const spread = qualifyingPointsForCustomer(
    [
      { business_ref: { id: "bizA" }, event_type: "call_tap" },
      { business_ref: { id: "bizB" }, event_type: "call_tap" },
      { business_ref: { id: "bizC" }, event_type: "call_tap" },
    ],
    WEIGHTS,
  );
  const repeated = qualifyingPointsForCustomer(
    [
      { business_ref: { id: "bizA" }, event_type: "call_tap" },
      { business_ref: { id: "bizA" }, event_type: "call_tap" },
      { business_ref: { id: "bizA" }, event_type: "call_tap" },
    ],
    WEIGHTS,
  );
  assert.equal(spread.total, 15);
  assert.equal(repeated.total, 5);
  assert.ok(spread.total > repeated.total, "breadth must beat repetition");
});

test("untargeted events are deduped per type so posting can't be farmed", () => {
  const result = qualifyingPointsForCustomer(
    [
      { event_type: "post" },
      { event_type: "post" },
      { event_type: "post" },
      { event_type: "share_app" },
    ],
    WEIGHTS,
  );
  assert.equal(result.total, 20, "post 10 + share_app 10, each once");
});

test("unknown event types score nothing", () => {
  const result = qualifyingPointsForCustomer(
    [{ event_type: "not_a_real_type" }],
    WEIGHTS,
  );
  assert.equal(result.total, 0);
  assert.equal(result.countedEvents, 0);
});

// --- Smoothing ---------------------------------------------------------

test("customer score moves toward its target, capped per night", async () => {
  // Target 50 (5 businesses x call_tap), from 0 - capped at 20.
  const events = [];
  for (let i = 0; i < 10; i += 1) {
    events.push({ type: "call_tap", business: `biz${i}` });
  }
  const ref = await seedCustomer({ score: 0, events });
  assert.equal(await scoreAfter(ref), 20);
});

test("a small gap closes exactly, without overshooting", async () => {
  const ref = await seedCustomer({
    score: 0,
    events: [{ type: "call_tap", business: "bizA" }],
  });
  assert.equal(await scoreAfter(ref), 5);
});

test("only events already marked processed are counted", async () => {
  const ref = await seedCustomer({
    score: 0,
    events: [
      { type: "post", status: "pending" },
      { type: "post", status: "rejected" },
    ],
  });
  assert.equal(await scoreAfter(ref), 0);
});

test("events outside the 7-day window are excluded", async () => {
  const ref = await seedCustomer({
    score: 0,
    events: [{ type: "post", daysAgo: 10 }],
  });
  assert.equal(await scoreAfter(ref), 0);
});

// --- Decay -------------------------------------------------------------

test("customer decay escalates across consecutive inactive weeks", async () => {
  const w1 = await seedCustomer({ score: 100, lastActivityDaysAgo: 7 });
  assert.equal(await scoreAfter(w1), 90);

  const w2 = await seedCustomer({
    score: 90,
    lastActivityDaysAgo: 14,
    decayedThroughWeek: 1,
  });
  assert.equal(await scoreAfter(w2), 70);

  const w3 = await seedCustomer({
    score: 70,
    lastActivityDaysAgo: 21,
    decayedThroughWeek: 2,
  });
  assert.equal(await scoreAfter(w3), 45);
});

test("customer decay floors at 0, not at a business baseline", async () => {
  // Customers have no tier baseline - kindex_engine has always started them
  // at 0 - so 0 is the floor.
  const ref = await seedCustomer({
    score: 5,
    lastActivityDaysAgo: 21,
    decayedThroughWeek: 2,
  });
  assert.equal(await scoreAfter(ref), 0);
});

test("customer decay is not charged twice for the same week", async () => {
  const ref = await seedCustomer({ score: 100, lastActivityDaysAgo: 7 });
  await recomputeAll(db, Date.now());
  await recomputeAll(db, Date.now());
  assert.equal((await ref.get()).data().score, 90);
});

test("new activity resets a customer's inactivity streak", async () => {
  const ref = await seedCustomer({
    score: 100,
    lastActivityDaysAgo: 21,
    decayedThroughWeek: 2,
    events: [{ type: "call_tap", business: "bizA" }],
  });
  await recomputeAll(db, Date.now());
  const data = (await ref.get()).data();
  assert.equal(data.inactivity_weeks, 0);
  assert.equal(data.decayed_through_week, 0);
  // Target 5 from 100, capped at 20 -> 80. No decay charged.
  assert.equal(data.score, 80);
});

test("a customer never seen active is not decayed on first run", async () => {
  const ref = await seedCustomer({ score: 100 });
  assert.equal(await scoreAfter(ref), 100);
  assert.ok((await ref.get()).data().last_activity_at);
});

// --- Trend + history ---------------------------------------------------

test("is_trending_up reflects real score movement", async () => {
  const up = await seedCustomer({
    score: 0,
    events: [{ type: "call_tap", business: "bizA" }],
  });
  await recomputeAll(db, Date.now());
  assert.equal((await up.get()).data().is_trending_up, true);

  const down = await seedCustomer({ score: 100, lastActivityDaysAgo: 7 });
  await recomputeAll(db, Date.now());
  assert.equal((await down.get()).data().is_trending_up, false);
});

test("a history row is written per customer per run", async () => {
  const ref = await seedCustomer({
    score: 0,
    events: [
      { type: "call_tap", business: "bizA" },
      { type: "call_tap", business: "bizB" },
    ],
  });
  await recomputeAll(db, Date.now());
  const rows = await db
    .collection("kindex_score_history")
    .where("entity_type", "==", "customer")
    .get();
  assert.equal(rows.size, 1);
  const row = rows.docs[0].data();
  assert.equal(row.score_before, 0);
  assert.equal(row.score_after, 10);
  assert.equal(row.distinct_businesses_engaged, 2);
  assert.ok(ref);
});
