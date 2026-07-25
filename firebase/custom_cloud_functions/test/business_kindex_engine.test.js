// Integration tests for processBusinessReview, run against the Firestore
// emulator (see `npm test` in package.json).
//
// These exercise the real transaction against real Firestore semantics -
// the scoring formula, the tier baselines/ceilings, and crucially the
// idempotency guard, which is the part that can't be verified by reading
// the code alone.
//
// Note the Admin SDK bypasses firestore.rules entirely, which is exactly
// how this function behaves in production - so these tests say nothing
// about client-side rule enforcement.

const assert = require("node:assert/strict");
const { test, before, after } = require("node:test");

const admin = require("firebase-admin");
admin.initializeApp({ projectId: "demo-kin-test" });

// The projectId must match the one the emulator runs under: snapshots
// built by makeDocumentSnapshot come from firebase-functions-test's own
// internal Firebase app, and without this it resolves to a different
// project namespace - so snapshot.ref would point at a doc that doesn't
// exist and every handler run would silently no-op.
const functionsTest = require("firebase-functions-test")({
  projectId: "demo-kin-test",
});
const engine = require("../business_kindex_engine.js");

const db = admin.firestore();
const wrapped = functionsTest.wrap(engine.processBusinessReview);

after(() => functionsTest.cleanup());

let counter = 0;
function uniqueId(prefix) {
  counter += 1;
  return `${prefix}_${counter}`;
}

/**
 * Seeds a business + review, then invokes the function the way the
 * trigger would. Only `snapshot.ref` is read by the handler (all data
 * comes from the transactional re-read), so the snapshot payload itself
 * is intentionally empty.
 */
async function processReview({ business, review }) {
  const businessId = uniqueId("biz");
  const reviewId = uniqueId("review");
  const businessRef = db.collection("businesses").doc(businessId);
  const reviewRef = db.collection("reviews").doc(reviewId);

  if (business !== null) {
    await businessRef.set(business);
  }
  await reviewRef.set({
    // `business_ref: null` models a review missing the field entirely.
    ...(review.business_ref === undefined
      ? { business_ref: businessRef }
      : review.business_ref === null
        ? {}
        : { business_ref: review.business_ref }),
    ...(review.rating === undefined ? {} : { rating: review.rating }),
    user_ref: db.collection("users").doc("someone"),
    review_text: "test review",
  });

  await wrapped(functionsTest.firestore.makeDocumentSnapshot({}, `reviews/${reviewId}`));

  return {
    businessRef,
    reviewRef,
    business: (await businessRef.get()).data(),
    review: (await reviewRef.get()).data(),
  };
}

// --- Scoring formula: parity with calculate_real_time_kindex.dart -------

test("standard business with no score yet starts from the 500 baseline", async () => {
  const { business, review } = await processReview({
    business: { kindex_score: 0, is_premium: false },
    review: { rating: 5 },
  });
  assert.equal(business.kindex_score, 515);
  assert.equal(review.status, "processed");
  assert.ok(review.processed_at, "processed_at should be stamped");
});

test("premium business with no score yet starts from the 850 baseline", async () => {
  const { business } = await processReview({
    business: { kindex_score: 0, is_premium: true },
    review: { rating: 5 },
  });
  assert.equal(business.kindex_score, 865);
});

test("a missing kindex_score field is treated as no score yet", async () => {
  const { business } = await processReview({
    business: { is_premium: false },
    review: { rating: 4 },
  });
  assert.equal(business.kindex_score, 505);
});

test("star ratings apply the documented deltas", async () => {
  const cases = [
    { rating: 5, expected: 615 },
    { rating: 4, expected: 605 },
    { rating: 3, expected: 600 }, // neutral
    { rating: 2, expected: 595 },
    { rating: 1, expected: 585 },
  ];
  for (const { rating, expected } of cases) {
    const { business } = await processReview({
      business: { kindex_score: 600, is_premium: false },
      review: { rating },
    });
    assert.equal(business.kindex_score, expected, `rating ${rating}`);
  }
});

test("fractional ratings are rounded to the nearest star", async () => {
  const { business } = await processReview({
    business: { kindex_score: 600, is_premium: false },
    review: { rating: 4.6 }, // rounds to 5 -> +15
  });
  assert.equal(business.kindex_score, 615);
});

test("score is clamped to the standard tier ceiling of 750", async () => {
  const { business } = await processReview({
    business: { kindex_score: 745, is_premium: false },
    review: { rating: 5 },
  });
  assert.equal(business.kindex_score, 750);
});

test("score is clamped to the premium tier ceiling of 900", async () => {
  const { business } = await processReview({
    business: { kindex_score: 895, is_premium: true },
    review: { rating: 5 },
  });
  assert.equal(business.kindex_score, 900);
});

test("score is clamped to a floor of 0", async () => {
  const { business } = await processReview({
    business: { kindex_score: 10, is_premium: false },
    review: { rating: 1 },
  });
  assert.equal(business.kindex_score, 0);
});

test("a standard business above its own ceiling is pulled down to it", async () => {
  // Premium business that lapsed to standard, or a stale manual write.
  const { business } = await processReview({
    business: { kindex_score: 880, is_premium: false },
    review: { rating: 3 },
  });
  assert.equal(business.kindex_score, 750);
});

// --- Idempotency -------------------------------------------------------

test("reprocessing the same review does not double-count", async () => {
  const businessRef = db.collection("businesses").doc(uniqueId("biz"));
  const reviewId = uniqueId("review");
  const reviewRef = db.collection("reviews").doc(reviewId);

  await businessRef.set({ kindex_score: 600, is_premium: false });
  await reviewRef.set({ business_ref: businessRef, rating: 5 });

  const snapshot = functionsTest.firestore.makeDocumentSnapshot(
    {},
    `reviews/${reviewId}`,
  );

  await wrapped(snapshot);
  assert.equal((await businessRef.get()).data().kindex_score, 615);

  // Simulates an at-least-once redelivery of the same create event.
  await wrapped(snapshot);
  await wrapped(snapshot);
  assert.equal(
    (await businessRef.get()).data().kindex_score,
    615,
    "score moved more than once",
  );
});

test("a review already marked rejected is not reprocessed", async () => {
  const businessRef = db.collection("businesses").doc(uniqueId("biz"));
  const reviewId = uniqueId("review");
  const reviewRef = db.collection("reviews").doc(reviewId);

  await businessRef.set({ kindex_score: 600, is_premium: false });
  await reviewRef.set({
    business_ref: businessRef,
    rating: 5,
    status: "rejected",
    error: "some earlier failure",
  });

  await wrapped(
    functionsTest.firestore.makeDocumentSnapshot({}, `reviews/${reviewId}`),
  );

  assert.equal((await businessRef.get()).data().kindex_score, 600);
  assert.equal((await reviewRef.get()).data().error, "some earlier failure");
});

// --- Rejection paths ---------------------------------------------------

test("a review with no business_ref is rejected", async () => {
  const { review } = await processReview({
    business: { kindex_score: 600, is_premium: false },
    review: { rating: 5, business_ref: null },
  });
  assert.equal(review.status, "rejected");
  assert.equal(review.error, "missing business_ref");
});

test("a review with a non-numeric rating is rejected", async () => {
  const { business, review } = await processReview({
    business: { kindex_score: 600, is_premium: false },
    review: { rating: "five" },
  });
  assert.equal(review.status, "rejected");
  assert.match(review.error, /invalid rating/);
  assert.equal(business.kindex_score, 600, "score must not move");
});

test("a review with no rating at all is rejected", async () => {
  const { review } = await processReview({
    business: { kindex_score: 600, is_premium: false },
    review: {},
  });
  assert.equal(review.status, "rejected");
});

test("a review pointing at a deleted business is rejected", async () => {
  const { review } = await processReview({
    business: null, // never created
    review: { rating: 5 },
  });
  assert.equal(review.status, "rejected");
  assert.equal(review.error, "business not found");
});

// --- Fields we deliberately do not write -------------------------------

test("kindex_velocity is left untouched", async () => {
  const { business } = await processReview({
    business: { kindex_score: 600, is_premium: false, kindex_velocity: 42 },
    review: { rating: 5 },
  });
  assert.equal(
    business.kindex_velocity,
    42,
    "velocity is deferred work - the function must not write a placeholder",
  );
});

test("the originating review id is recorded on the business", async () => {
  const { business, reviewRef } = await processReview({
    business: { kindex_score: 600, is_premium: false },
    review: { rating: 5 },
  });
  assert.equal(business.last_kindex_review_id, reviewRef.id);
});

test("unrelated business fields are preserved", async () => {
  const { business } = await processReview({
    business: {
      kindex_score: 600,
      is_premium: false,
      business_name: "Test Co",
      ticker_symbol: "TCO",
    },
    review: { rating: 5 },
  });
  assert.equal(business.business_name, "Test Co");
  assert.equal(business.ticker_symbol, "TCO");
});
