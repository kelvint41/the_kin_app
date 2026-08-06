// Tests for the pure override-resolution helper behind resolveClaimRequest
// (claim_review.js). No emulator needed - same reasoning as
// business_discovery.test.js: this piece never calls Firestore itself, the
// rest of the file does and is covered by the plan's manual/emulator
// verification steps instead.

const assert = require("node:assert/strict");
const { test } = require("node:test");

const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp({ projectId: "demo-kin-test" });
}

const { resolveBlackOwnedAndVeteran } =
  require("../claim_review.js")._internals;

test("no overrides: falls back to the claimant's declared values", () => {
  const claim = { declared_black_owned: true, declared_veteran: false };
  assert.deepEqual(resolveBlackOwnedAndVeteran(claim, {}), {
    blackOwned: true,
    veteran: false,
  });
});

test("admin override to false is respected, not treated as 'no override'", () => {
  // The whole point of the override - if `false` were mistaken for
  // "not provided", an admin could never turn OFF a declared true.
  const claim = { declared_black_owned: true, declared_veteran: true };
  assert.deepEqual(
    resolveBlackOwnedAndVeteran(claim, { blackOwned: false, veteran: false }),
    { blackOwned: false, veteran: false },
  );
});

test("admin override to true works when the claimant declared false", () => {
  const claim = { declared_black_owned: false, declared_veteran: false };
  assert.deepEqual(
    resolveBlackOwnedAndVeteran(claim, { blackOwned: true, veteran: true }),
    { blackOwned: true, veteran: true },
  );
});

test("missing declared_* fields default to false, not undefined", () => {
  assert.deepEqual(resolveBlackOwnedAndVeteran({}, {}), {
    blackOwned: false,
    veteran: false,
  });
});

test("non-boolean override (e.g. omitted key) is ignored in favor of the declaration", () => {
  const claim = { declared_black_owned: true, declared_veteran: true };
  assert.deepEqual(
    resolveBlackOwnedAndVeteran(claim, { blackOwned: undefined, veteran: null }),
    { blackOwned: true, veteran: true },
  );
});
