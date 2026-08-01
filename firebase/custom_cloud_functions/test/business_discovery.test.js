// Tests for the pure duplicate-detection helpers behind
// submitCustomerBusinessDiscovery (business_discovery.js). No emulator
// needed - findsDuplicate/normalizeName take a Firestore-shaped snapshot
// object but never call Firestore themselves.

const assert = require("node:assert/strict");
const { test } = require("node:test");

const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp({ projectId: "demo-kin-test" });
}

const { findsDuplicate, normalizeName } =
  require("../business_discovery.js")._internals;

const fakeSnapshot = (docs) => ({
  docs: docs.map((data) => ({ data: () => data })),
});

test("normalizeName: case/whitespace-insensitive", () => {
  assert.equal(normalizeName("  Soul  Food   Kitchen "), "soul food kitchen");
  assert.equal(normalizeName("Soul Food Kitchen"), "soul food kitchen");
});

test("findsDuplicate: same name and close coords is a duplicate", () => {
  const snap = fakeSnapshot([
    {
      business_name: "Soul Food Kitchen",
      business_location: { latitude: 41.8781, longitude: -87.6298 },
    },
  ]);
  assert.equal(
    findsDuplicate(snap, "soul food kitchen", { lat: 41.8782, lng: -87.6299 }),
    true,
  );
});

test("findsDuplicate: same name but far away is not a duplicate", () => {
  const snap = fakeSnapshot([
    {
      business_name: "Soul Food Kitchen",
      business_location: { latitude: 41.8781, longitude: -87.6298 },
    },
  ]);
  // San Antonio vs Chicago - a same-named business a thousand miles away
  // is a different business, not a re-submission.
  assert.equal(
    findsDuplicate(snap, "Soul Food Kitchen", { lat: 29.4241, lng: -98.4936 }),
    false,
  );
});

test("findsDuplicate: different name, same coords is not a duplicate", () => {
  const snap = fakeSnapshot([
    {
      business_name: "Soul Food Kitchen",
      business_location: { latitude: 41.8781, longitude: -87.6298 },
    },
  ]);
  assert.equal(
    findsDuplicate(snap, "Uptown Barbers", { lat: 41.8781, lng: -87.6298 }),
    false,
  );
});

test("findsDuplicate: same name with no location on either side still matches", () => {
  const snap = fakeSnapshot([{ business_name: "Soul Food Kitchen" }]);
  assert.equal(findsDuplicate(snap, "Soul Food Kitchen", null), true);
});

test("findsDuplicate: same name, candidate has coords but existing doc has none", () => {
  const snap = fakeSnapshot([{ business_name: "Soul Food Kitchen" }]);
  assert.equal(
    findsDuplicate(snap, "Soul Food Kitchen", { lat: 41.8781, lng: -87.6298 }),
    true,
  );
});

test("findsDuplicate: empty snapshot never matches", () => {
  assert.equal(findsDuplicate(fakeSnapshot([]), "Anything", null), false);
});

test("findsDuplicate: docs missing business_name are skipped, not thrown on", () => {
  const snap = fakeSnapshot([{ business_location: { latitude: 1, longitude: 2 } }]);
  assert.equal(findsDuplicate(snap, "Soul Food Kitchen", null), false);
});
