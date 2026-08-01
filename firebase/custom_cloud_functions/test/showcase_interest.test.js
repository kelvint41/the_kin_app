// Tests for recordItemInterest (showcase_interest.js), run against the
// Firestore emulator (`npm test`).
//
// This function's only job is incrementing a Showcase item's
// interest_count when a reaction event targets it - it shares
// UserEngagementEvents with kindex_engine.js (which scores every event
// type generically) and Exchange post reactions (which use the same five
// react_* event types but a different target_ref collection), so what's
// covered here is: the increment itself, aggregation across different
// reaction types, idempotency against redelivery, and that a reaction
// aimed at something other than a business_items doc is left alone.

const assert = require("node:assert/strict");
const { test, beforeEach } = require("node:test");

const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp({ projectId: "demo-kin-test" });
}

const { processEvent } = require("../showcase_interest.js")._internals;

const db = admin.firestore();

let counter = 0;
const uniq = (p) => `${p}_${++counter}`;

async function clear(collection) {
  const snap = await db.collection(collection).get();
  await Promise.all(snap.docs.map((d) => d.ref.delete()));
}

beforeEach(async () => {
  await Promise.all([
    clear("business_items"),
    clear("UserEngagementEvents"),
    clear("exchange_posts"),
  ]);
});

async function seedItem() {
  const ref = db.collection("business_items").doc(uniq("item"));
  await ref.set({
    business_ref: db.collection("businesses").doc(uniq("business")),
    title: "Test item",
    price_display: "$10",
    category: "Retail",
    is_available: true,
    interest_count: 0,
  });
  return ref;
}

async function seedEvent(overrides) {
  const ref = db.collection("UserEngagementEvents").doc(uniq("event"));
  await ref.set({
    event_type: "react_kin",
    status: "pending",
    ...overrides,
  });
  return ref;
}

test("processEvent: a reaction targeting an item increments interest_count 0 -> 1", async () => {
  const itemRef = await seedItem();
  const eventRef = await seedEvent({ target_ref: itemRef });

  await processEvent(eventRef);

  const itemSnap = await itemRef.get();
  assert.equal(itemSnap.data().interest_count, 1);
  const eventSnap = await eventRef.get();
  assert.equal(eventSnap.data().interest_counted, true);
});

test("processEvent: different reaction types on the same item aggregate", async () => {
  const itemRef = await seedItem();
  const eventA = await seedEvent({ target_ref: itemRef, event_type: "react_kin" });
  const eventB = await seedEvent({ target_ref: itemRef, event_type: "react_backed" });

  await processEvent(eventA);
  await processEvent(eventB);

  const itemSnap = await itemRef.get();
  assert.equal(itemSnap.data().interest_count, 2);
});

test("processEvent: redelivering the same event doesn't double-count", async () => {
  const itemRef = await seedItem();
  const eventRef = await seedEvent({ target_ref: itemRef });

  await processEvent(eventRef);
  await processEvent(eventRef);

  const itemSnap = await itemRef.get();
  assert.equal(itemSnap.data().interest_count, 1);
});

test("processEvent: a reaction on an Exchange post (not a Showcase item) is ignored", async () => {
  const postRef = db.collection("exchange_posts").doc(uniq("post"));
  await postRef.set({ post_text: "hello" });
  const eventRef = await seedEvent({ target_ref: postRef });

  await processEvent(eventRef);

  const postSnap = await postRef.get();
  assert.equal(postSnap.data().interest_count, undefined);
  const eventSnap = await eventRef.get();
  assert.equal(eventSnap.data().interest_counted, true);
});

test("processEvent: an event with no target_ref doesn't throw", async () => {
  const eventRef = await seedEvent({});

  await assert.doesNotReject(() => processEvent(eventRef));

  const eventSnap = await eventRef.get();
  assert.equal(eventSnap.data().interest_counted, true);
});

test("processEvent: a deleted/missing event doc doesn't throw", async () => {
  const eventRef = db.collection("UserEngagementEvents").doc(uniq("missing"));
  await assert.doesNotReject(() => processEvent(eventRef));
});
