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
const { computeScore, highestRatingPerVerifiedCustomer, recomputeAll } =
  nightly._internals;

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
  ]);
});

const daysAgo = (n) =>
  admin.firestore.Timestamp.fromMillis(Date.now() - n * 24 * 60 * 60 * 1000);

async function seed({ isPremium = false, reviews = [], visits = [] }) {
  const businessRef = db.collection("businesses").doc(uniq("biz"));
  await businessRef.set({ is_premium: isPremium, kindex_score: 0 });

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

test("distinct verified customers each count", async () => {
  const biz = await seed({
    reviews: [
      { user: "alice", rating: 5 },
      { user: "bob", rating: 5 },
      { user: "carol", rating: 4 },
    ],
    visits: [{ user: "alice" }, { user: "bob" }, { user: "carol" }],
  });
  assert.equal(await scoreAfterRecompute(biz), 535); // 500 +15 +15 +5
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
