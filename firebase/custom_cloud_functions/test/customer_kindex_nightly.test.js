// Tests for the customer-side nightly Kindex recompute.
//
// Mirrors the business-side rules: capped nightly movement toward a
// windowed target, escalating inactivity decay with a floor, and a dedup
// rule so repeat engagement with one business can't be farmed. Baseline is
// 300 and the cap is 850 (business_kindex_nightly.js's Standard/Premium
// tier numbers), matching the tier-baseline model rather than the old
// no-baseline-at-all customer behavior.
//
// customer_scoring_frozen defaults to true pre-launch (see
// kindex_scoring_dynamics.js), so every test below that exercises real
// target-seeking/decay explicitly sets it to false in beforeEach - the
// frozen tests near the bottom are the only ones that rely on the default.

const assert = require("node:assert/strict");
const { test, beforeEach } = require("node:test");

const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp({ projectId: "demo-kin-test" });
}

const customerNightly = require("../customer_kindex_nightly.js");
const { qualifyingPointsForCustomer, recomputeAll, resetWeightsCache } =
  customerNightly._internals;
const { resetConfigCache } = require("../kindex_scoring_dynamics.js");

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

async function setFrozen(frozen) {
  await db
    .collection("kindex_config")
    .doc("scoring_dynamics")
    .set({ customer_scoring_frozen: frozen }, { merge: true });
  resetConfigCache();
}

beforeEach(async () => {
  await Promise.all([
    clear("KindexScores"),
    clear("UserEngagementEvents"),
    clear("kindex_score_history"),
  ]);
  await db.collection("kindex_config").doc("scoring_weights").set(WEIGHTS);
  resetWeightsCache();
  // Unfrozen by default in this suite - the frozen behavior itself gets
  // its own tests further down, which override this explicitly.
  await setFrozen(false);
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

// --- Smoothing -----------------------------------------------------------
// Targets below the 300 baseline clamp up to 300 (Math.max(baseline,
// qualifying.total)), so a customer starting at 0 always has a large gap
// to close regardless of how few points their events are worth - these
// cases are indistinguishable from "far from target" and move by the
// capped amount rather than reaching a small target exactly.

test("customer score moves toward its target, capped per night", async () => {
  // 10 businesses x call_tap = 50 qualifying points, clamped up to the
  // 300 baseline as the target - either way the gap from 0 exceeds the
  // cap, so this moves by exactly max_nightly_change.
  const events = [];
  for (let i = 0; i < 10; i += 1) {
    events.push({ type: "call_tap", business: `biz${i}` });
  }
  const ref = await seedCustomer({ score: 0, events });
  assert.equal(await scoreAfter(ref), 20);
});

test("a small gap closes exactly, without overshooting", async () => {
  // Seeded near the target rather than at 0, so the gap itself (5) is
  // what's under test, not the baseline clamp.
  const ref = await seedCustomer({
    score: 295,
    events: [{ type: "call_tap", business: "bizA" }],
  });
  assert.equal(await scoreAfter(ref), 300);
});

test("qualifying points above the cap still target 850, not higher", async () => {
  // A local weight override rather than piling up hundreds of events to
  // organically clear 850 - one call_tap worth 900 points is well past
  // the cap either way, and isolated to this test via its own doc write.
  await db
    .collection("kindex_config")
    .doc("scoring_weights")
    .set({ call_tap: 900 });
  resetWeightsCache();

  const ref = await seedCustomer({
    score: 840,
    events: [{ type: "call_tap", business: "bizA" }],
  });
  // Target clamps to 850 (900 points -> min(850, max(300,900))=850), a
  // 10-point gap from 840 that closes exactly, under the 20-point cap.
  assert.equal(await scoreAfter(ref), 850);

  // A second run confirms it holds at the cap rather than creeping past
  // it - target stays 850, current is already there, no movement.
  assert.equal(await scoreAfter(ref), 850);
});

test("only events already marked processed are counted", async () => {
  const ref = await seedCustomer({
    score: 0,
    events: [
      { type: "post", status: "pending" },
      { type: "post", status: "rejected" },
    ],
  });
  // No qualifying activity -> decay branch -> floors at the 300 baseline.
  assert.equal(await scoreAfter(ref), 300);
});

test("events outside the 7-day window are excluded", async () => {
  const ref = await seedCustomer({
    score: 0,
    events: [{ type: "post", daysAgo: 10 }],
  });
  assert.equal(await scoreAfter(ref), 300);
});

// --- Decay -------------------------------------------------------------
// Seeded well above the 300 floor so decay is observable rather than
// immediately swallowed by the floor clamp.

test("customer decay escalates across consecutive inactive weeks", async () => {
  const w1 = await seedCustomer({ score: 600, lastActivityDaysAgo: 7 });
  assert.equal(await scoreAfter(w1), 590);

  const w2 = await seedCustomer({
    score: 590,
    lastActivityDaysAgo: 14,
    decayedThroughWeek: 1,
  });
  assert.equal(await scoreAfter(w2), 570);

  const w3 = await seedCustomer({
    score: 570,
    lastActivityDaysAgo: 21,
    decayedThroughWeek: 2,
  });
  assert.equal(await scoreAfter(w3), 545);
});

test("customer decay floors at 300, matching the business tier-baseline model", async () => {
  const ref = await seedCustomer({
    score: 305,
    lastActivityDaysAgo: 21,
    decayedThroughWeek: 2,
  });
  // Decay owed (25 for week 3) would take this to 280, but the 300
  // baseline floor holds it there instead.
  assert.equal(await scoreAfter(ref), 300);
});

test("customer decay is not charged twice for the same week", async () => {
  const ref = await seedCustomer({ score: 500, lastActivityDaysAgo: 7 });
  await recomputeAll(db, Date.now());
  await recomputeAll(db, Date.now());
  assert.equal((await ref.get()).data().score, 490);
});

test("new activity resets a customer's inactivity streak", async () => {
  const ref = await seedCustomer({
    score: 500,
    lastActivityDaysAgo: 21,
    decayedThroughWeek: 2,
    events: [{ type: "call_tap", business: "bizA" }],
  });
  await recomputeAll(db, Date.now());
  const data = (await ref.get()).data();
  assert.equal(data.inactivity_weeks, 0);
  assert.equal(data.decayed_through_week, 0);
  // Target clamps to 300 (5 points -> max(300,5)=300) from 500, capped at
  // 20 -> 480. No decay charged.
  assert.equal(data.score, 480);
});

test("a customer never seen active is not decayed on first run", async () => {
  const ref = await seedCustomer({ score: 500 });
  assert.equal(await scoreAfter(ref), 500);
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

  const down = await seedCustomer({ score: 500, lastActivityDaysAgo: 7 });
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
  // Target clamps to 300 (10 points -> max(300,10)=300), gap from 0
  // exceeds the 20-point cap, so this moves by exactly 20 rather than
  // reaching 10.
  assert.equal(row.score_after, 20);
  assert.equal(row.distinct_businesses_engaged, 2);
  assert.ok(ref);
});

// --- Frozen (pre-launch) -------------------------------------------------

test("frozen holds every customer at exactly the baseline, real activity included", async () => {
  await setFrozen(true);
  const ref = await seedCustomer({
    score: 12,
    events: [{ type: "call_tap", business: "bizA" }],
  });
  assert.equal(await scoreAfter(ref), 300);
});

test("frozen does not decay an inactive customer below the baseline", async () => {
  await setFrozen(true);
  const ref = await seedCustomer({
    score: 300,
    lastActivityDaysAgo: 21,
    decayedThroughWeek: 2,
  });
  assert.equal(await scoreAfter(ref), 300);
});

test("frozen leaves is_trending_up null rather than implying movement", async () => {
  await setFrozen(true);
  const ref = await seedCustomer({ score: 12 });
  await recomputeAll(db, Date.now());
  assert.equal((await ref.get()).data().is_trending_up, null);
});

test("frozen writes no history row for a plain reset to baseline", async () => {
  await setFrozen(true);
  const ref = await seedCustomer({ score: 12 });
  await recomputeAll(db, Date.now());
  const rows = await db
    .collection("kindex_score_history")
    .where("entity_type", "==", "customer")
    .get();
  assert.equal(rows.size, 0);
  assert.ok(ref);
});

test("frozen is a no-op for a customer already at baseline", async () => {
  await setFrozen(true);
  const ref = await seedCustomer({ score: 300 });
  const before = (await ref.get()).data();
  await recomputeAll(db, Date.now());
  const after = (await ref.get()).data();
  assert.equal(after.score, 300);
  // last_recomputed_at should be untouched - proves the update was
  // skipped entirely, not just a same-value write.
  assert.equal(after.last_recomputed_at, before.last_recomputed_at);
});
