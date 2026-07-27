// Tests for recordVerifiedVisit, run against the Firestore emulator
// (`npm test`).
//
// A verified visit is the prerequisite for a review to count toward a
// business's kindex_score, so this callable is the gate the whole
// anti-manipulation design rests on. What's covered here is accordingly
// the ways someone would try to get a visit recorded that shouldn't be:
// checking in to your own business, checking in from somewhere else, and
// tapping the button repeatedly to inflate the count.
//
// The pure-helper tests at the top need no Firestore and run without the
// emulator; the handler tests below need it.

const assert = require("node:assert/strict");
const { test, describe, beforeEach } = require("node:test");

const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp({ projectId: "demo-kin-test" });
}

const visitVerification = require("../visit_verification.js");
const { haversineMeters, businessCoords, isValidCoord } =
  visitVerification._internals;

const db = admin.firestore();

let counter = 0;
const uniq = (p) => `${p}_${++counter}`;

// --- Pure helpers ------------------------------------------------------

test("haversine: a point against itself is zero", () => {
  const p = { lat: 29.4241, lng: -98.4936 };
  assert.equal(haversineMeters(p, p), 0);
});

test("haversine: one degree of latitude is about 111km", () => {
  const d = haversineMeters({ lat: 29.0, lng: -98.0 }, { lat: 30.0, lng: -98.0 });
  // Great-circle, so this is ~111.19km rather than a round number.
  assert.ok(d > 111000 && d < 111400, `got ${d}`);
});

test("haversine: symmetric", () => {
  const a = { lat: 29.4241, lng: -98.4936 };
  const b = { lat: 29.4300, lng: -98.5000 };
  assert.equal(haversineMeters(a, b), haversineMeters(b, a));
});

test("isValidCoord: rejects null island, geolocator's no-fix value", () => {
  assert.equal(isValidCoord(0, 0), false);
});

test("isValidCoord: rejects non-finite and out-of-range values", () => {
  assert.equal(isValidCoord(NaN, 10), false);
  assert.equal(isValidCoord(10, NaN), false);
  assert.equal(isValidCoord(Infinity, 10), false);
  assert.equal(isValidCoord(91, 10), false);
  assert.equal(isValidCoord(-91, 10), false);
  assert.equal(isValidCoord(10, 181), false);
  assert.equal(isValidCoord(10, -181), false);
});

test("isValidCoord: rejects non-numbers, including numeric strings", () => {
  assert.equal(isValidCoord("29.4", "-98.5"), false);
  assert.equal(isValidCoord(null, null), false);
  assert.equal(isValidCoord(undefined, undefined), false);
});

test("isValidCoord: accepts real coordinates, including exact zero on one axis", () => {
  assert.equal(isValidCoord(29.4241, -98.4936), true);
  // Only the 0,0 pair is treated as no-fix; a genuine zero on one axis
  // (the equator or the prime meridian) is a real place.
  assert.equal(isValidCoord(0, -98.4936), true);
  assert.equal(isValidCoord(29.4241, 0), true);
});

test("businessCoords: prefers the business_location GeoPoint", () => {
  const got = businessCoords({
    business_location: { latitude: 29.4241, longitude: -98.4936 },
    latitude: 1,
    longitude: 2,
  });
  assert.deepEqual(got, { lat: 29.4241, lng: -98.4936 });
});

test("businessCoords: falls back to the coordinates variant", () => {
  const got = businessCoords({
    coordinates: { latitude: 29.4241, longitude: -98.4936 },
  });
  assert.deepEqual(got, { lat: 29.4241, lng: -98.4936 });
});

test("businessCoords: falls back to flat latitude/longitude numbers", () => {
  const got = businessCoords({ latitude: 29.4241, longitude: -98.4936 });
  assert.deepEqual(got, { lat: 29.4241, lng: -98.4936 });
});

test("businessCoords: treats flat 0,0 as absent rather than null island", () => {
  assert.equal(businessCoords({ latitude: 0, longitude: 0 }), null);
});

test("businessCoords: returns null when nothing usable is on file", () => {
  assert.equal(businessCoords({}), null);
  assert.equal(businessCoords({ business_location: null }), null);
  assert.equal(businessCoords({ latitude: "29.4", longitude: "-98.5" }), null);
});

// --- Handler (needs the emulator) --------------------------------------

const BIZ = { lat: 29.4241, lng: -98.4936 };
// ~44m north: comfortably inside the 100m default radius.
const NEARBY = { lat: BIZ.lat + 0.0004, lng: BIZ.lng };
// ~222m north: comfortably outside it.
const FAR = { lat: BIZ.lat + 0.002, lng: BIZ.lng };

async function clear(collection) {
  const snap = await db.collection(collection).get();
  await Promise.all(snap.docs.map((d) => d.ref.delete()));
}

// Grouped so the emulator-dependent beforeEach applies only to these, and
// the pure tests above stay runnable on their own (`node --test` with no
// emulator, hence no Java).
describe("recordVerifiedVisit", () => {

beforeEach(async () => {
  await Promise.all([
    clear("businesses"),
    clear("uservisits"),
    clear("kindex_config"),
  ]);
});

async function seedBusiness({ coords = BIZ, owner, shape = "geopoint" } = {}) {
  const ref = db.collection("businesses").doc(uniq("biz"));
  const location =
    coords === null
      ? {}
      : shape === "flat"
        ? { latitude: coords.lat, longitude: coords.lng }
        : { business_location: new admin.firestore.GeoPoint(coords.lat, coords.lng) };
  await ref.set({
    ...location,
    ...(owner ? { owner_ref: db.collection("users").doc(owner) } : {}),
  });
  return ref;
}

function call(fn, { uid, businessRefPath, lat, lng }) {
  return fn.run({
    auth: uid ? { uid } : undefined,
    data: {
      businessRefPath,
      ...(lat === undefined ? {} : { latitude: lat }),
      ...(lng === undefined ? {} : { longitude: lng }),
    },
  });
}

async function rejectsWith(code, fn) {
  let err;
  try {
    await fn();
  } catch (e) {
    err = e;
  }
  assert.ok(err, `expected HttpsError ${code}, but it resolved`);
  assert.equal(err.code, code, `expected ${code}, got ${err.code}: ${err.message}`);
  return err;
}

// The module caches its config for 5 minutes at module scope, so a test
// that tunes the radius would otherwise leak into every test after it.
// Re-requiring gives a fresh cache.
function freshHandler() {
  delete require.cache[require.resolve("../visit_verification.js")];
  return require("../visit_verification.js").recordVerifiedVisit;
}

const recordVerifiedVisit = visitVerification.recordVerifiedVisit;

test("handler: an unauthenticated caller is rejected", async () => {
  const biz = await seedBusiness();
  await rejectsWith("unauthenticated", () =>
    call(recordVerifiedVisit, {
      businessRefPath: biz.path,
      lat: NEARBY.lat,
      lng: NEARBY.lng,
    }),
  );
});

test("handler: a businessRefPath outside the businesses collection is rejected", async () => {
  // Guards against being pointed at an arbitrary document path.
  for (const path of ["users/abc", "", "not-a-path", "businesses"]) {
    await rejectsWith("invalid-argument", () =>
      call(recordVerifiedVisit, {
        uid: "customer_1",
        businessRefPath: path,
        lat: NEARBY.lat,
        lng: NEARBY.lng,
      }),
    );
  }
});

test("handler: missing or invalid coordinates are rejected", async () => {
  const biz = await seedBusiness();
  await rejectsWith("invalid-argument", () =>
    call(recordVerifiedVisit, { uid: "customer_1", businessRefPath: biz.path }),
  );
  await rejectsWith("invalid-argument", () =>
    call(recordVerifiedVisit, {
      uid: "customer_1",
      businessRefPath: biz.path,
      lat: 0,
      lng: 0,
    }),
  );
});

test("handler: a business that does not exist is rejected", async () => {
  await rejectsWith("not-found", () =>
    call(recordVerifiedVisit, {
      uid: "customer_1",
      businessRefPath: "businesses/does_not_exist",
      lat: NEARBY.lat,
      lng: NEARBY.lng,
    }),
  );
});

test("handler: an owner cannot check in to their own business", async () => {
  // Self-farming gate. An owner's own verified visit would make their own
  // review count toward their own score.
  const biz = await seedBusiness({ owner: "owner_1" });
  await rejectsWith("permission-denied", () =>
    call(recordVerifiedVisit, {
      uid: "owner_1",
      businessRefPath: biz.path,
      lat: BIZ.lat,
      lng: BIZ.lng,
    }),
  );
  assert.equal((await db.collection("uservisits").get()).size, 0);
});

test("handler: a non-owner can still check in to a business that has an owner", async () => {
  const biz = await seedBusiness({ owner: "owner_1" });
  const res = await call(recordVerifiedVisit, {
    uid: "customer_1",
    businessRefPath: biz.path,
    lat: NEARBY.lat,
    lng: NEARBY.lng,
  });
  assert.equal(res.alreadyCheckedIn, false);
});

test("handler: a business with no location on file fails closed", async () => {
  const biz = await seedBusiness({ coords: null });
  await rejectsWith("failed-precondition", () =>
    call(recordVerifiedVisit, {
      uid: "customer_1",
      businessRefPath: biz.path,
      lat: NEARBY.lat,
      lng: NEARBY.lng,
    }),
  );
  assert.equal((await db.collection("uservisits").get()).size, 0);
});

test("handler: a caller outside the radius is rejected and records nothing", async () => {
  const biz = await seedBusiness();
  const err = await rejectsWith("out-of-range", () =>
    call(recordVerifiedVisit, {
      uid: "customer_1",
      businessRefPath: biz.path,
      lat: FAR.lat,
      lng: FAR.lng,
    }),
  );
  assert.match(err.message, /\d+m away/);
  assert.equal((await db.collection("uservisits").get()).size, 0);
});

test("handler: a caller inside the radius records a visit", async () => {
  const biz = await seedBusiness();
  const res = await call(recordVerifiedVisit, {
    uid: "customer_1",
    businessRefPath: biz.path,
    lat: NEARBY.lat,
    lng: NEARBY.lng,
  });

  assert.equal(res.alreadyCheckedIn, false);
  assert.ok(res.visitId);
  assert.ok(res.distanceMeters >= 0 && res.distanceMeters < 100);

  const snap = await db.collection("uservisits").get();
  assert.equal(snap.size, 1);
  const visit = snap.docs[0].data();
  assert.equal(visit.business_ref.path, biz.path);
  assert.equal(visit.user_ref.path, "users/customer_1");
  assert.equal(visit.verified_radius_meters, 100);
  // Server-set, so it cannot be backdated by the caller.
  assert.ok(visit.visit_timestamp);
});

test("handler: a business storing flat latitude/longitude also works", async () => {
  // The bulk-imported records don't all share one coordinate shape.
  const biz = await seedBusiness({ shape: "flat" });
  const res = await call(recordVerifiedVisit, {
    uid: "customer_1",
    businessRefPath: biz.path,
    lat: NEARBY.lat,
    lng: NEARBY.lng,
  });
  assert.equal(res.alreadyCheckedIn, false);
});

test("handler: a repeat check-in inside the window reuses the same visit", async () => {
  // Anti-inflation: tapping the button repeatedly must not stack visits.
  const biz = await seedBusiness();
  const args = {
    uid: "customer_1",
    businessRefPath: biz.path,
    lat: NEARBY.lat,
    lng: NEARBY.lng,
  };

  const first = await call(recordVerifiedVisit, args);
  const second = await call(recordVerifiedVisit, args);

  assert.equal(first.alreadyCheckedIn, false);
  assert.equal(second.alreadyCheckedIn, true);
  assert.equal(second.visitId, first.visitId);
  assert.equal((await db.collection("uservisits").get()).size, 1);
});

test("handler: dedup is scoped per user and per business", async () => {
  const bizA = await seedBusiness();
  const bizB = await seedBusiness();

  await call(recordVerifiedVisit, {
    uid: "customer_1",
    businessRefPath: bizA.path,
    lat: NEARBY.lat,
    lng: NEARBY.lng,
  });
  // A different customer at the same business is a separate visit.
  const otherUser = await call(recordVerifiedVisit, {
    uid: "customer_2",
    businessRefPath: bizA.path,
    lat: NEARBY.lat,
    lng: NEARBY.lng,
  });
  // The same customer at a different business is also a separate visit.
  const otherBiz = await call(recordVerifiedVisit, {
    uid: "customer_1",
    businessRefPath: bizB.path,
    lat: NEARBY.lat,
    lng: NEARBY.lng,
  });

  assert.equal(otherUser.alreadyCheckedIn, false);
  assert.equal(otherBiz.alreadyCheckedIn, false);
  assert.equal((await db.collection("uservisits").get()).size, 3);
});

test("handler: a visit older than the dedup window does not suppress a new one", async () => {
  const biz = await seedBusiness();
  const args = {
    uid: "customer_1",
    businessRefPath: biz.path,
    lat: NEARBY.lat,
    lng: NEARBY.lng,
  };

  const first = await call(recordVerifiedVisit, args);
  // Backdate past the 1h default rather than waiting it out.
  await db
    .collection("uservisits")
    .doc(first.visitId)
    .update({
      visit_timestamp: admin.firestore.Timestamp.fromMillis(
        Date.now() - 2 * 60 * 60 * 1000,
      ),
    });

  const second = await call(recordVerifiedVisit, args);
  assert.equal(second.alreadyCheckedIn, false);
  assert.notEqual(second.visitId, first.visitId);
  assert.equal((await db.collection("uservisits").get()).size, 2);
});

test("config: a tightened radius from Firestore is honoured", async () => {
  await db
    .collection("kindex_config")
    .doc("visit_verification")
    .set({ radius_meters: 10 });

  const biz = await seedBusiness();
  const handler = freshHandler();
  // NEARBY is ~44m out: inside the 100m default, outside a 10m radius.
  await rejectsWith("out-of-range", () =>
    call(handler, {
      uid: "customer_1",
      businessRefPath: biz.path,
      lat: NEARBY.lat,
      lng: NEARBY.lng,
    }),
  );
});

test("config: a widened radius from Firestore is honoured", async () => {
  await db
    .collection("kindex_config")
    .doc("visit_verification")
    .set({ radius_meters: 500 });

  const biz = await seedBusiness();
  const handler = freshHandler();
  // FAR is ~222m out: outside the default, inside a 500m radius.
  const res = await call(handler, {
    uid: "customer_1",
    businessRefPath: biz.path,
    lat: FAR.lat,
    lng: FAR.lng,
  });
  assert.equal(res.alreadyCheckedIn, false);
  const snap = await db.collection("uservisits").get();
  assert.equal(snap.docs[0].data().verified_radius_meters, 500);
});

test("config: a zero dedup window records every check-in separately", async () => {
  await db
    .collection("kindex_config")
    .doc("visit_verification")
    .set({ dedup_window_ms: 0 });

  const biz = await seedBusiness();
  const handler = freshHandler();
  const args = {
    uid: "customer_1",
    businessRefPath: biz.path,
    lat: NEARBY.lat,
    lng: NEARBY.lng,
  };
  await call(handler, args);
  const second = await call(handler, args);
  assert.equal(second.alreadyCheckedIn, false);
});

test("config: nonsense config values fall back to the defaults", async () => {
  await db
    .collection("kindex_config")
    .doc("visit_verification")
    .set({ radius_meters: -5, dedup_window_ms: "an hour" });

  const biz = await seedBusiness();
  const handler = freshHandler();
  const res = await call(handler, {
    uid: "customer_1",
    businessRefPath: biz.path,
    lat: NEARBY.lat,
    lng: NEARBY.lng,
  });
  assert.equal(res.alreadyCheckedIn, false);
  const snap = await db.collection("uservisits").get();
  assert.equal(snap.docs[0].data().verified_radius_meters, 100);
});

});
