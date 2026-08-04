// Tests for recordExchangeReactionCounts (exchange_reaction_counts.js), run
// against the Firestore emulator (`npm test`).
//
// A third independent onCreate trigger on UserEngagementEvents, alongside
// kindex_engine.js (generic scoring) and showcase_interest.js (Showcase
// item interest_count) - the five react_* event types are shared across
// all three, so what's covered here is: the reaction_counts increment
// itself, aggregation across reaction types, idempotency against
// redelivery, that a reaction aimed at something other than an
// exchange_posts doc is left alone, and the notable_reaction
// amplification path (threshold, name resolution/fallback, and that it
// only fires for the two amplifying event types).

const assert = require("node:assert/strict");
const { test, beforeEach } = require("node:test");

const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp({ projectId: "demo-kin-test" });
}

const { processEvent, lookupNotableReactor } =
  require("../exchange_reaction_counts.js")._internals;

const db = admin.firestore();

let counter = 0;
const uniq = (p) => `${p}_${++counter}`;

async function clear(collection) {
  const snap = await db.collection(collection).get();
  await Promise.all(snap.docs.map((d) => d.ref.delete()));
}

beforeEach(async () => {
  await Promise.all([
    clear("exchange_posts"),
    clear("business_items"),
    clear("UserEngagementEvents"),
    clear("KindexScores"),
    clear("users"),
    clear("exchange_profiles"),
  ]);
});

async function seedPost() {
  const ref = db.collection("exchange_posts").doc(uniq("post"));
  await ref.set({ post_text: "Test post" });
  return ref;
}

async function seedEvent(overrides) {
  const ref = db.collection("UserEngagementEvents").doc(uniq("event"));
  await ref.set({
    event_type: "react_kin",
    ...overrides,
  });
  return ref;
}

/** Seeds users/{uid} + KindexScores/{uid} for a would-be reactor. */
async function seedReactor({ score, displayName, exchangeProfileName }) {
  const userId = uniq("user");
  const userRef = db.collection("users").doc(userId);
  await userRef.set(displayName === undefined ? {} : { display_name: displayName });
  if (score !== undefined) {
    await db
      .collection("KindexScores")
      .doc(userId)
      .set({ user_ref: userRef, score });
  }
  if (exchangeProfileName !== undefined) {
    await db
      .collection("exchange_profiles")
      .doc(userId)
      .set({ display_name: exchangeProfileName });
  }
  return userRef;
}

test("processEvent: a reaction on an Exchange post increments reaction_counts 0 -> 1", async () => {
  const postRef = await seedPost();
  const eventRef = await seedEvent({
    target_ref: postRef,
    event_type: "react_kin",
  });

  await processEvent(eventRef);

  const postSnap = await postRef.get();
  assert.equal(postSnap.data().reaction_counts.react_kin, 1);
  const eventSnap = await eventRef.get();
  assert.equal(eventSnap.data().reaction_counted, true);
});

test("processEvent: different reaction types on the same post aggregate independently", async () => {
  const postRef = await seedPost();
  const eventA = await seedEvent({ target_ref: postRef, event_type: "react_kin" });
  const eventB = await seedEvent({ target_ref: postRef, event_type: "react_built" });
  const eventC = await seedEvent({ target_ref: postRef, event_type: "react_built" });

  await processEvent(eventA);
  await processEvent(eventB);
  await processEvent(eventC);

  const counts = (await postRef.get()).data().reaction_counts;
  assert.equal(counts.react_kin, 1);
  assert.equal(counts.react_built, 2);
});

test("processEvent: redelivering the same event doesn't double-count", async () => {
  const postRef = await seedPost();
  const eventRef = await seedEvent({ target_ref: postRef, event_type: "react_proud" });

  await processEvent(eventRef);
  await processEvent(eventRef);

  const postSnap = await postRef.get();
  assert.equal(postSnap.data().reaction_counts.react_proud, 1);
});

test("processEvent: a reaction on a Showcase item (not an Exchange post) is ignored", async () => {
  const itemRef = db.collection("business_items").doc(uniq("item"));
  await itemRef.set({ title: "Test item", interest_count: 0 });
  const eventRef = await seedEvent({ target_ref: itemRef, event_type: "react_kin" });

  await processEvent(eventRef);

  const itemSnap = await itemRef.get();
  assert.equal(itemSnap.data().reaction_counts, undefined);
  const eventSnap = await eventRef.get();
  assert.equal(eventSnap.data().reaction_counted, true);
});

test("processEvent: a non-reaction event_type on an Exchange post is ignored", async () => {
  const postRef = await seedPost();
  const eventRef = await seedEvent({ target_ref: postRef, event_type: "post" });

  await processEvent(eventRef);

  const postSnap = await postRef.get();
  assert.equal(postSnap.data().reaction_counts, undefined);
  const eventSnap = await eventRef.get();
  assert.equal(eventSnap.data().reaction_counted, true);
});

test("processEvent: an event with no target_ref doesn't throw", async () => {
  const eventRef = await seedEvent({});

  await assert.doesNotReject(() => processEvent(eventRef));

  const eventSnap = await eventRef.get();
  assert.equal(eventSnap.data().reaction_counted, true);
});

test("processEvent: a deleted/missing event doc doesn't throw", async () => {
  const eventRef = db.collection("UserEngagementEvents").doc(uniq("missing"));
  await assert.doesNotReject(() => processEvent(eventRef));
});

test("processEvent: react_backed from a reactor at/above threshold stamps notable_reaction", async () => {
  const postRef = await seedPost();
  const reactorRef = await seedReactor({ score: 720, displayName: "Jordan" });
  const eventRef = await seedEvent({
    target_ref: postRef,
    event_type: "react_backed",
    user_ref: reactorRef,
  });

  await processEvent(eventRef);

  const notable = (await postRef.get()).data().notable_reaction;
  assert.deepEqual(notable, { name: "Jordan", event_type: "react_backed" });
});

test("processEvent: a reactor below threshold does not stamp notable_reaction", async () => {
  const postRef = await seedPost();
  const reactorRef = await seedReactor({ score: 719, displayName: "Jordan" });
  const eventRef = await seedEvent({
    target_ref: postRef,
    event_type: "react_backed",
    user_ref: reactorRef,
  });

  await processEvent(eventRef);

  assert.equal((await postRef.get()).data().notable_reaction, undefined);
});

test("processEvent: react_kin from a high-scoring reactor does not amplify (not react_backed/react_spotlight)", async () => {
  const postRef = await seedPost();
  const reactorRef = await seedReactor({ score: 850, displayName: "Jordan" });
  const eventRef = await seedEvent({
    target_ref: postRef,
    event_type: "react_kin",
    user_ref: reactorRef,
  });

  await processEvent(eventRef);

  const postSnap = await postRef.get();
  assert.equal(postSnap.data().reaction_counts.react_kin, 1);
  assert.equal(postSnap.data().notable_reaction, undefined);
});

test("processEvent: react_spotlight amplifies the same as react_backed", async () => {
  const postRef = await seedPost();
  const reactorRef = await seedReactor({ score: 810, displayName: "Alex" });
  const eventRef = await seedEvent({
    target_ref: postRef,
    event_type: "react_spotlight",
    user_ref: reactorRef,
  });

  await processEvent(eventRef);

  const notable = (await postRef.get()).data().notable_reaction;
  assert.deepEqual(notable, { name: "Alex", event_type: "react_spotlight" });
});

test("processEvent: falls back to exchange_profiles display_name when users/{uid} has none", async () => {
  const postRef = await seedPost();
  const reactorRef = await seedReactor({
    score: 800,
    exchangeProfileName: "ExchangeName",
  });
  const eventRef = await seedEvent({
    target_ref: postRef,
    event_type: "react_backed",
    user_ref: reactorRef,
  });

  await processEvent(eventRef);

  const notable = (await postRef.get()).data().notable_reaction;
  assert.deepEqual(notable, { name: "ExchangeName", event_type: "react_backed" });
});

test("processEvent: no resolvable name anywhere means no notable_reaction, but the reaction still counts", async () => {
  const postRef = await seedPost();
  const reactorRef = await seedReactor({ score: 800 });
  const eventRef = await seedEvent({
    target_ref: postRef,
    event_type: "react_backed",
    user_ref: reactorRef,
  });

  await processEvent(eventRef);

  const postSnap = await postRef.get();
  assert.equal(postSnap.data().reaction_counts.react_backed, 1);
  assert.equal(postSnap.data().notable_reaction, undefined);
});

test("processEvent: a reactor with no KindexScores doc at all does not amplify", async () => {
  const postRef = await seedPost();
  const reactorRef = db.collection("users").doc(uniq("user"));
  await reactorRef.set({ display_name: "NoScore" });
  const eventRef = await seedEvent({
    target_ref: postRef,
    event_type: "react_backed",
    user_ref: reactorRef,
  });

  await processEvent(eventRef);

  assert.equal((await postRef.get()).data().notable_reaction, undefined);
});

test("lookupNotableReactor: returns null below threshold, the reactor's name at/above it", async () => {
  const below = await seedReactor({ score: 100, displayName: "Low" });
  assert.equal(await lookupNotableReactor(db, below, "react_backed"), null);

  const above = await seedReactor({ score: 720, displayName: "High" });
  assert.deepEqual(await lookupNotableReactor(db, above, "react_backed"), {
    name: "High",
    event_type: "react_backed",
  });
});
