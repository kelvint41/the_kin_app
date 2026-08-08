// Tests for recordSpendLogAggregate/removeSpendLogAggregate
// (spend_log_aggregate.js), run against the Firestore emulator (`npm
// test`).
//
// Covers: total_spend/total_entries increment on create and decrement on
// delete, city_totals/category_totals rolling up correctly under the
// nested-object merge (not clobbering sibling cities/categories), the
// slugify normalization that lets differently-cased city names roll up
// together, the "unspecified" fallback, and that an entry with no
// city/category still counts toward the community-wide total without
// touching the per-city/per-category maps.

const assert = require("node:assert/strict");
const { test, beforeEach } = require("node:test");

const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp({ projectId: "demo-kin-test" });
}

const { applyDelta, slugify } = require("../spend_log_aggregate.js")._internals;

const db = admin.firestore();
const AGGREGATE_REF = db.collection("community_impact_stats").doc("aggregate");

async function clear(collection) {
  const snap = await db.collection(collection).get();
  await Promise.all(snap.docs.map((d) => d.ref.delete()));
}

beforeEach(async () => {
  await clear("community_impact_stats");
});

test("slugify: normalizes case and punctuation, falls back to 'unspecified'", () => {
  assert.equal(slugify("San Antonio"), "san_antonio");
  assert.equal(slugify("san antonio"), "san_antonio");
  assert.equal(slugify("Restaurant & Food"), "restaurant_food");
  assert.equal(slugify("   "), "unspecified");
  assert.equal(slugify("!!!"), "unspecified");
});

test("applyDelta(+1): a first entry seeds total_spend, total_entries, city_totals, category_totals", async () => {
  await applyDelta(
    { amount: 42, business_city: "San Antonio", business_category: "Restaurant & Food" },
    1,
  );

  const snap = await AGGREGATE_REF.get();
  const data = snap.data();
  assert.equal(data.total_spend, 42);
  assert.equal(data.total_entries, 1);
  assert.equal(data.city_totals.san_antonio, 42);
  assert.equal(data.city_labels.san_antonio, "San Antonio");
  assert.equal(data.category_totals.restaurant_food, 42);
  assert.equal(data.category_labels.restaurant_food, "Restaurant & Food");
});

test("applyDelta(+1): differently-cased city names roll up onto the same key without clobbering other cities", async () => {
  await applyDelta({ amount: 20, business_city: "San Antonio" }, 1);
  await applyDelta({ amount: 30, business_city: "san antonio" }, 1);
  await applyDelta({ amount: 15, business_city: "Chicago" }, 1);

  const data = (await AGGREGATE_REF.get()).data();
  assert.equal(data.total_spend, 65);
  assert.equal(data.total_entries, 3);
  assert.equal(data.city_totals.san_antonio, 50);
  assert.equal(data.city_totals.chicago, 15);
});

test("applyDelta(+1): an entry with no city/category still counts toward the total without adding map keys", async () => {
  await applyDelta({ amount: 25 }, 1);

  const data = (await AGGREGATE_REF.get()).data();
  assert.equal(data.total_spend, 25);
  assert.equal(data.total_entries, 1);
  assert.equal(data.city_totals, undefined);
  assert.equal(data.category_totals, undefined);
});

test("applyDelta(-1): deleting an entry decrements the same buckets it created, leaving siblings untouched", async () => {
  await applyDelta({ amount: 40, business_city: "Atlanta", business_category: "Retail" }, 1);
  await applyDelta({ amount: 60, business_city: "Dallas", business_category: "Retail" }, 1);

  await applyDelta({ amount: 40, business_city: "Atlanta", business_category: "Retail" }, -1);

  const data = (await AGGREGATE_REF.get()).data();
  assert.equal(data.total_spend, 60);
  assert.equal(data.total_entries, 1);
  assert.equal(data.city_totals.atlanta, 0);
  assert.equal(data.city_totals.dallas, 60);
  // Retail category total reflects both entries netted together, since
  // both cities shared it.
  assert.equal(data.category_totals.retail, 60);
});

test("applyDelta(-1): a deleted entry's label is not erased - the slug->name mapping only ever grows", async () => {
  await applyDelta({ amount: 10, business_city: "Houston" }, 1);
  await applyDelta({ amount: 10, business_city: "Houston" }, -1);

  const data = (await AGGREGATE_REF.get()).data();
  assert.equal(data.city_totals.houston, 0);
  assert.equal(data.city_labels.houston, "Houston");
});

test("applyDelta: an entry with a non-numeric amount is ignored rather than writing NaN into the aggregate", async () => {
  await applyDelta({ amount: "not a number", business_city: "Miami" }, 1);
  const snap = await AGGREGATE_REF.get();
  assert.equal(snap.exists, false);
});
