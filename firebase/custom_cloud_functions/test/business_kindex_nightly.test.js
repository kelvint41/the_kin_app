// Tests for the nightly Kindex recompute, run against the Firestore
// emulator (`npm test`).
//
// The anti-manipulation rules are the point of this job, so they're what
// these cover: unverified reviews must not score, and one customer must not
// be able to move a score more than once per window no matter how many
// reviews they leave.

const assert = require("node:assert/strict");
const { test, beforeEach } = require("node:test");

const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp({ projectId: "demo-kin-test" });
}

const nightly = require("../business_kindex_nightly.js");
const {
  computeScore,
  highestRatingPerVerifiedCustomer,
  distinctPostDaysByAuthor,
  applyActivePosterBonus,
  recomputeAll,
} = nightly._internals;

const db = admin.firestore();

let counter = 0;
const uniq = (p) => `${p}_${++counter}`;

async function clear(collection) {
  const snap = await db.collection(collection).get();
  await Promise.all(snap.docs.map((d) => d.ref.delete()));
}

beforeEach(async () => {
  await Promise.all([
    clear("businesses"),
    clear("reviews"),
    clear("uservisits"),
    clear("exchange_posts"),
    clear("kindex_score_history"),
  ]);
});

const daysAgo = (n) =>
  admin.firestore.Timestamp.fromMillis(Date.now() - n * 24 * 60 * 60 * 1000);

async function seed({
  isPremium = false,
  reviews = [],
  visits = [],
  posts = [],
  owner,
  score,
  lastActivityDaysAgo,
  decayedThroughWeek,
}) {
  const businessRef = db.collection("businesses").doc(uniq("biz"));
  await businessRef.set({
    is_premium: isPremium,
    kindex_score: score === undefined ? 0 : score,
    ...(owner ? { owner_ref: db.collection("users").doc(owner) } : {}),
    ...(lastActivityDaysAgo === undefined
      ? {}
      : { kindex_last_activity_at: daysAgo(lastActivityDaysAgo) }),
    ...(decayedThroughWeek === undefined
      ? {}
      : { kindex_decayed_through_week: decayedThroughWeek }),
  });

  for (const r of reviews) {
    await db.collection("reviews").doc(uniq("review")).set({
      business_ref: businessRef,
      user_ref: db.collection("users").doc(r.user),
      rating: r.rating,
      timestamp: daysAgo(r.daysAgo ?? 1),
    });
  }
  for (const v of visits) {
    await db.collection("uservisits").doc(uniq("visit")).set({
      business_ref: businessRef,
      user_ref: db.collection("users").doc(v.user),
      visit_timestamp: daysAgo(v.daysAgo ?? 1),
    });
  }
  // Author defaults to the business owner - the active-poster bonus only
  // counts the owner's own posts (see business_kindex_nightly.js), so a
  // caller only needs to override `user` for the "someone else posted"
  // case.
  for (const p of posts) {
    await db.collection("exchange_posts").doc(uniq("post")).set({
      user_ref: db.collection("users").doc(p.user ?? owner),
      business_ref: businessRef,
      timestamp: daysAgo(p.daysAgo ?? 1),
    });
  }
  return businessRef;
}

async function scoreAfterRecompute(businessRef) {
  await recomputeAll(db, Date.now());
  return (await businessRef.get()).data().kindex_score;
}

// --- Pure formula ------------------------------------------------------

test("no qualifying reviews leaves a business at its tier baseline", () => {
  assert.equal(computeScore([], false), 500);
  assert.equal(computeScore([], true), 850);
});

test("qualifying ratings accumulate from the baseline", () => {
  assert.equal(computeScore([5], false), 515);
  assert.equal(computeScore([5, 5], false), 530);
  assert.equal(computeScore([5, 1], false), 500); // +15 -15
  assert.equal(computeScore([3, 3, 3], false), 500); // neutral
});

test("score stays inside the tier ceiling and floor", () => {
  assert.equal(computeScore(Array(100).fill(5), false), 750);
  assert.equal(computeScore(Array(100).fill(5), true), 900);
  assert.equal(computeScore(Array(100).fill(1), false), 0);
});

test("only the highest rating per verified customer is kept", () => {
  const verified = new Set(["alice"]);
  const reviews = [
    { user_ref: { id: "alice" }, rating: 2 },
    { user_ref: { id: "alice" }, rating: 5 },
    { user_ref: { id: "alice" }, rating: 1 },
  ];
  assert.deepEqual(highestRatingPerVerifiedCustomer(reviews, verified), [5]);
});

test("unverified customers are dropped entirely", () => {
  const reviews = [
    { user_ref: { id: "alice" }, rating: 5 },
    { user_ref: { id: "mallory" }, rating: 1 },
  ];
  assert.deepEqual(
    highestRatingPerVerifiedCustomer(reviews, new Set(["alice"])),
    [5],
  );
});

// --- End-to-end against the emulator -----------------------------------

test("a verified 5-star review moves the score", async () => {
  const biz = await seed({
    reviews: [{ user: "alice", rating: 5 }],
    visits: [{ user: "alice" }],
  });
  assert.equal(await scoreAfterRecompute(biz), 515);
});

test("a review with no check-in does not move the score", async () => {
  const biz = await seed({
    reviews: [{ user: "alice", rating: 5 }],
    visits: [],
  });
  assert.equal(await scoreAfterRecompute(biz), 500, "unverified review scored");
});

test("one customer cannot stack multiple reviews in the window", async () => {
  // The core manipulation case: five 5-star reviews from one verified
  // account must count once, not five times.
  const biz = await seed({
    reviews: [
      { user: "alice", rating: 5 },
      { user: "alice", rating: 5 },
      { user: "alice", rating: 5 },
      { user: "alice", rating: 5 },
      { user: "alice", rating: 5 },
    ],
    visits: [{ user: "alice" }],
  });
  assert.equal(await scoreAfterRecompute(biz), 515);
});

test("a competitor cannot tank a score with repeat 1-star reviews", async () => {
  const biz = await seed({
    reviews: [
      { user: "mallory", rating: 1 },
      { user: "mallory", rating: 1 },
      { user: "mallory", rating: 1 },
    ],
    visits: [{ user: "mallory" }],
  });
  assert.equal(await scoreAfterRecompute(biz), 485); // one -15, not three
});

test("a customer's highest rating in the window is the one that counts", async () => {
  const biz = await seed({
    reviews: [
      { user: "alice", rating: 1, daysAgo: 3 },
      { user: "alice", rating: 5, daysAgo: 2 },
    ],
    visits: [{ user: "alice" }],
  });
  assert.equal(await scoreAfterRecompute(biz), 515);
});

test("distinct verified customers each count, but movement is capped", async () => {
  const biz = await seed({
    reviews: [
      { user: "alice", rating: 5 },
      { user: "bob", rating: 5 },
      { user: "carol", rating: 4 },
    ],
    visits: [{ user: "alice" }, { user: "bob" }, { user: "carol" }],
  });
  // Target is 535 (500 +15 +15 +5) but the nightly cap is 20, so the score
  // only reaches 520 tonight and closes the rest on subsequent nights.
  assert.equal(await scoreAfterRecompute(biz), 520);
});

test("reviews outside the 7-day window are excluded", async () => {
  const biz = await seed({
    reviews: [{ user: "alice", rating: 5, daysAgo: 10 }],
    visits: [{ user: "alice", daysAgo: 10 }],
  });
  assert.equal(await scoreAfterRecompute(biz), 500);
});

test("a visit outside the window does not verify a review inside it", async () => {
  const biz = await seed({
    reviews: [{ user: "alice", rating: 5, daysAgo: 1 }],
    visits: [{ user: "alice", daysAgo: 30 }],
  });
  assert.equal(await scoreAfterRecompute(biz), 500);
});

test("premium businesses recompute from the premium baseline", async () => {
  const biz = await seed({
    isPremium: true,
    reviews: [{ user: "alice", rating: 5 }],
    visits: [{ user: "alice" }],
  });
  assert.equal(await scoreAfterRecompute(biz), 865);
});

test("duplicate review docs for one customer still count once", async () => {
  // Legacy auto-id reviews coexist with the new composite-id scheme, so a
  // customer may transiently have two documents for one business.
  const biz = await seed({
    reviews: [
      { user: "alice", rating: 5 },
      { user: "alice", rating: 5 },
    ],
    visits: [{ user: "alice" }],
  });
  assert.equal(await scoreAfterRecompute(biz), 515);
});

test("recompute is idempotent", async () => {
  const biz = await seed({
    reviews: [{ user: "alice", rating: 5 }],
    visits: [{ user: "alice" }],
  });
  await recomputeAll(db, Date.now());
  await recomputeAll(db, Date.now());
  await recomputeAll(db, Date.now());
  assert.equal((await biz.get()).data().kindex_score, 515);
});

// --- Owner self-farming ------------------------------------------------

test("an owner's own review never counts, even with a verified visit", async () => {
  // The visit is present on purpose: it models a check-in recorded before
  // recordVerifiedVisit refused owner check-ins, or written directly back
  // when uservisits was still client-writable. The nightly job must still
  // refuse to score it.
  const biz = await seed({
    owner: "owner1",
    reviews: [{ user: "owner1", rating: 5 }],
    visits: [{ user: "owner1" }],
  });
  assert.equal(await scoreAfterRecompute(biz), 500, "owner farmed own score");
});

test("an owner cannot tank a competitor by owning it - only their own review is dropped", async () => {
  const biz = await seed({
    owner: "owner1",
    reviews: [
      { user: "owner1", rating: 5 },
      { user: "alice", rating: 5 },
    ],
    visits: [{ user: "owner1" }, { user: "alice" }],
  });
  // Only alice's +15 lands.
  assert.equal(await scoreAfterRecompute(biz), 515);
});

test("owner exclusion is keyed to the owning business only", async () => {
  // Someone who owns business A is an ordinary customer at business B.
  const other = await seed({
    owner: "owner2",
    reviews: [{ user: "owner1", rating: 5 }],
    visits: [{ user: "owner1" }],
  });
  assert.equal(await scoreAfterRecompute(other), 515);
});

test("a business with no owner_ref still scores normally", async () => {
  const biz = await seed({
    reviews: [{ user: "alice", rating: 5 }],
    visits: [{ user: "alice" }],
  });
  assert.equal(await scoreAfterRecompute(biz), 515);
});

test("kindex_velocity is never written", async () => {
  const businessRef = db.collection("businesses").doc(uniq("biz"));
  await businessRef.set({
    is_premium: false,
    kindex_score: 0,
    kindex_velocity: 42,
  });
  await db.collection("reviews").doc(uniq("review")).set({
    business_ref: businessRef,
    user_ref: db.collection("users").doc("alice"),
    rating: 5,
    timestamp: daysAgo(1),
  });
  await db.collection("uservisits").doc(uniq("visit")).set({
    business_ref: businessRef,
    user_ref: db.collection("users").doc("alice"),
    visit_timestamp: daysAgo(1),
  });
  await recomputeAll(db, Date.now());
  assert.equal((await businessRef.get()).data().kindex_velocity, 42);
});

// --- Active Poster Bonus -------------------------------------------------

test("distinctPostDaysByAuthor dedups same-day posts", () => {
  const day1 = { toDate: () => new Date("2026-01-01T09:00:00Z") };
  const day1Later = { toDate: () => new Date("2026-01-01T21:00:00Z") };
  const day2 = { toDate: () => new Date("2026-01-02T09:00:00Z") };
  const posts = [
    { user_ref: { id: "owner1" }, timestamp: day1 },
    { user_ref: { id: "owner1" }, timestamp: day1Later },
    { user_ref: { id: "owner1" }, timestamp: day2 },
    { user_ref: { id: "owner2" }, timestamp: day1 },
  ];
  const byAuthor = distinctPostDaysByAuthor(posts);
  assert.equal(byAuthor.get("owner1").size, 2, "same-day posts double-counted");
  assert.equal(byAuthor.get("owner2").size, 1);
});

test("applyActivePosterBonus adds and clamps to the ceiling", () => {
  assert.equal(applyActivePosterBonus(500, false, 10, 750), 500, "bonus applied when not an active poster");
  assert.equal(applyActivePosterBonus(500, true, 10, 750), 510);
  assert.equal(applyActivePosterBonus(745, true, 10, 750), 750, "bonus overshot the ceiling");
});

test("a business with no reviews still gets no bonus below 3 distinct posting days", async () => {
  const biz = await seed({
    owner: "owner1",
    posts: [{ daysAgo: 1 }, { daysAgo: 2 }],
  });
  assert.equal(await scoreAfterRecompute(biz), 500);
});

test("reaching 3 distinct posting days grants the active-poster bonus", async () => {
  const biz = await seed({
    owner: "owner1",
    posts: [{ daysAgo: 1 }, { daysAgo: 2 }, { daysAgo: 3 }],
  });
  assert.equal(await scoreAfterRecompute(biz), 510); // 500 baseline + 10 bonus
});

test("five posts in one day count as one distinct day, not five", async () => {
  const biz = await seed({
    owner: "owner1",
    posts: [
      { daysAgo: 1 },
      { daysAgo: 1 },
      { daysAgo: 1 },
      { daysAgo: 1 },
      { daysAgo: 1 },
    ],
  });
  assert.equal(await scoreAfterRecompute(biz), 500, "one busy day granted the bonus");
});

test("posts outside the 7-day window are excluded from the streak", async () => {
  const biz = await seed({
    owner: "owner1",
    posts: [{ daysAgo: 1 }, { daysAgo: 2 }, { daysAgo: 10 }],
  });
  assert.equal(await scoreAfterRecompute(biz), 500, "stale post counted toward the streak");
});

test("a post authored by someone other than the owner does not count", async () => {
  const biz = await seed({
    owner: "owner1",
    posts: [
      { daysAgo: 1, user: "customer1" },
      { daysAgo: 2, user: "customer1" },
      { daysAgo: 3, user: "customer1" },
    ],
  });
  assert.equal(await scoreAfterRecompute(biz), 500, "a non-owner's posts granted the bonus");
});

test("posting alone, with no reviews, still counts as activity and blocks decay", async () => {
  const biz = await seed({
    owner: "owner1",
    score: 600,
    lastActivityDaysAgo: 21,
    decayedThroughWeek: 2,
    posts: [{ daysAgo: 1 }, { daysAgo: 2 }, { daysAgo: 3 }],
  });
  await recomputeAll(db, Date.now());
  const data = (await biz.get()).data();
  // Target is baseline+bonus (510) from 600 - a 90pt gap capped at 20, so
  // the score moves down toward it rather than decaying for inactivity.
  assert.equal(data.kindex_score, 580);
  assert.equal(data.kindex_inactivity_weeks, 0, "streak not reset by posting");
  assert.equal(data.kindex_decayed_through_week, 0, "decay ledger not cleared");
  assert.equal(data.kindex_active_poster_bonus_applied, true);
  assert.equal(data.kindex_active_poster_days, 3);

  const rows = await db
    .collection("kindex_score_history")
    .where("business_ref", "==", biz)
    .get();
  assert.equal(rows.docs[0].data().decay_applied, 0, "decay charged despite active posting");
});

test("the active-poster bonus is clamped to the tier ceiling, not stacked past it", async () => {
  // 50 verified 5-star reviews already push the raw target to the tier
  // ceiling (750) before any bonus is considered.
  const reviews = [];
  const visits = [];
  for (let i = 0; i < 50; i += 1) {
    reviews.push({ user: `cust${i}`, rating: 5 });
    visits.push({ user: `cust${i}` });
  }
  const biz = await seed({
    owner: "owner1",
    reviews,
    visits,
    posts: [{ daysAgo: 1 }, { daysAgo: 2 }, { daysAgo: 3 }],
  });
  await recomputeAll(db, Date.now());
  const rows = await db
    .collection("kindex_score_history")
    .where("business_ref", "==", biz)
    .get();
  assert.equal(rows.docs[0].data().target_score, 750, "bonus pushed the target past the ceiling");
});

test("each run writes active-poster fields on the history row", async () => {
  const biz = await seed({
    owner: "owner1",
    posts: [{ daysAgo: 1 }, { daysAgo: 2 }, { daysAgo: 3 }],
  });
  await recomputeAll(db, Date.now());
  const rows = await db
    .collection("kindex_score_history")
    .where("business_ref", "==", biz)
    .get();
  const row = rows.docs[0].data();
  assert.equal(row.active_poster_bonus_applied, true);
  assert.equal(row.active_poster_days, 3);
  assert.equal(row.active_poster_bonus_points, 10);
});

// --- Smoothing (capped nightly movement) --------------------------------

test("a huge single-day spike does NOT jump straight to the maximum", async () => {
  // 50 verified 5-star check-ins - a grand opening, not manipulation. The
  // raw target is the tier ceiling (750); the score must climb toward it.
  const reviews = [];
  const visits = [];
  for (let i = 0; i < 50; i += 1) {
    reviews.push({ user: `cust${i}`, rating: 5 });
    visits.push({ user: `cust${i}` });
  }
  const biz = await seed({ reviews, visits });
  assert.equal(await scoreAfterRecompute(biz), 520, "score jumped past the cap");
});

test("repeated nights close the gap toward the target", async () => {
  const reviews = [];
  const visits = [];
  for (let i = 0; i < 50; i += 1) {
    reviews.push({ user: `cust${i}`, rating: 5 });
    visits.push({ user: `cust${i}` });
  }
  const biz = await seed({ reviews, visits });
  const seen = [];
  for (let night = 0; night < 5; night += 1) {
    await recomputeAll(db, Date.now());
    seen.push((await biz.get()).data().kindex_score);
  }
  assert.deepEqual(seen, [520, 540, 560, 580, 600]);
});

test("a downward target is also capped", async () => {
  // Sitting at 700, but this window's verified reviews only justify 485.
  const biz = await seed({
    score: 700,
    reviews: [{ user: "alice", rating: 1 }],
    visits: [{ user: "alice" }],
  });
  assert.equal(await scoreAfterRecompute(biz), 680);
});

test("movement stops exactly at the target, never overshooting", async () => {
  // Target 515, current 500 - a 15-point gap, under the 20-point cap.
  const biz = await seed({
    score: 500,
    reviews: [{ user: "alice", rating: 5 }],
    visits: [{ user: "alice" }],
  });
  assert.equal(await scoreAfterRecompute(biz), 515);
});

// --- Inactivity decay ---------------------------------------------------

test("no decay before a full week of inactivity has passed", async () => {
  const biz = await seed({ score: 600, lastActivityDaysAgo: 6 });
  assert.equal(await scoreAfterRecompute(biz), 600);
});

test("decay escalates across consecutive inactive weeks", async () => {
  const week1 = await seed({ score: 600, lastActivityDaysAgo: 7 });
  assert.equal(await scoreAfterRecompute(week1), 590); // -10

  // Week 2, having already been charged for week 1.
  const week2 = await seed({
    score: 590,
    lastActivityDaysAgo: 14,
    decayedThroughWeek: 1,
  });
  assert.equal(await scoreAfterRecompute(week2), 570); // -20

  const week3 = await seed({
    score: 570,
    lastActivityDaysAgo: 21,
    decayedThroughWeek: 2,
  });
  assert.equal(await scoreAfterRecompute(week3), 545); // -25
});

test("decay holds at the week-3 rate by default rather than escalating", async () => {
  const week5 = await seed({
    score: 600,
    lastActivityDaysAgo: 35,
    decayedThroughWeek: 4,
  });
  assert.equal(await scoreAfterRecompute(week5), 575); // still -25
});

test("decay never takes a score below its tier baseline", async () => {
  const biz = await seed({
    score: 505,
    lastActivityDaysAgo: 21,
    decayedThroughWeek: 2,
  });
  assert.equal(await scoreAfterRecompute(biz), 500, "decayed through the floor");
});

test("a premium business decays only to the premium baseline", async () => {
  const biz = await seed({
    isPremium: true,
    score: 855,
    lastActivityDaysAgo: 21,
    decayedThroughWeek: 2,
  });
  assert.equal(await scoreAfterRecompute(biz), 850);
});

test("decay is not charged twice for the same week on a re-run", async () => {
  const biz = await seed({ score: 600, lastActivityDaysAgo: 7 });
  await recomputeAll(db, Date.now());
  await recomputeAll(db, Date.now());
  await recomputeAll(db, Date.now());
  assert.equal((await biz.get()).data().kindex_score, 590, "double-charged");
});

test("new activity resets the inactivity streak immediately", async () => {
  const biz = await seed({
    score: 560,
    lastActivityDaysAgo: 21,
    decayedThroughWeek: 2,
    reviews: [{ user: "alice", rating: 5 }],
    visits: [{ user: "alice" }],
  });
  await recomputeAll(db, Date.now());
  const data = (await biz.get()).data();
  assert.equal(data.kindex_inactivity_weeks, 0, "streak not reset");
  assert.equal(data.kindex_decayed_through_week, 0, "decay ledger not cleared");
  // Target 515 from 560, capped at 20 -> moves down to 540, no decay charged.
  assert.equal(data.kindex_score, 540);
});

test("a business never seen active is not decayed on first run", async () => {
  // Pre-existing businesses have no kindex_last_activity_at. Treating that
  // as infinite inactivity would decay the whole collection on deploy.
  const biz = await seed({ score: 600 });
  assert.equal(await scoreAfterRecompute(biz), 600);
  const data = (await biz.get()).data();
  assert.ok(data.kindex_last_activity_at, "activity clock not started");
});

// --- Dashboard history --------------------------------------------------

test("each run writes a history row with before/after and context", async () => {
  const biz = await seed({
    reviews: [{ user: "alice", rating: 5 }],
    visits: [{ user: "alice" }],
  });
  await recomputeAll(db, Date.now());
  const rows = await db
    .collection("kindex_score_history")
    .where("business_ref", "==", biz)
    .get();
  assert.equal(rows.size, 1);
  const row = rows.docs[0].data();
  assert.equal(row.entity_type, "business");
  assert.equal(row.score_before, 500);
  assert.equal(row.score_after, 515);
  assert.equal(row.target_score, 515);
  assert.equal(row.qualifying_review_count, 1);
  assert.equal(row.verified_visit_count, 1);
});

test("re-running the same day updates that day's row instead of duplicating", async () => {
  const biz = await seed({
    reviews: [{ user: "alice", rating: 5 }],
    visits: [{ user: "alice" }],
  });
  await recomputeAll(db, Date.now());
  await recomputeAll(db, Date.now());
  const rows = await db
    .collection("kindex_score_history")
    .where("business_ref", "==", biz)
    .get();
  assert.equal(rows.size, 1, "history duplicated within a single day");
});
