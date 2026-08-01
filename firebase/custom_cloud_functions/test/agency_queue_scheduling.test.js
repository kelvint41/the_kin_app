// Tests for computeTargetDeliveryDate, the pure logic behind
// scheduleAgencyQueueTarget (`npm test`). Pure helper, no emulator needed -
// same split as visit_verification.test.js.

const assert = require("node:assert/strict");
const { test } = require("node:test");

const agencyQueueScheduling = require("../agency_queue_scheduling.js");
const { DELIVERY_WINDOW_DAYS, computeTargetDeliveryDate } =
  agencyQueueScheduling._internals;

const DAY_MS = 24 * 60 * 60 * 1000;
const NOW = Date.parse("2026-07-28T12:00:00Z");

test("known tier: target is now plus that tier's window", () => {
  const target = computeTargetDeliveryDate("Single page", NOW);
  assert.equal(target.toMillis(), NOW + 14 * DAY_MS);
});

test("every bounded tier resolves to a timestamp in the future", () => {
  for (const tier of Object.keys(DELIVERY_WINDOW_DAYS)) {
    const target = computeTargetDeliveryDate(tier, NOW);
    assert.ok(target.toMillis() > NOW, `${tier} did not move forward`);
  }
});

test("Advanced is deliberately not auto-scheduled - stays open-ended", () => {
  assert.equal(computeTargetDeliveryDate("Advanced", NOW), null);
});

test("unrecognized or unset tier yields no target", () => {
  assert.equal(computeTargetDeliveryDate("Not sure yet", NOW), null);
  assert.equal(computeTargetDeliveryDate(undefined, NOW), null);
  assert.equal(computeTargetDeliveryDate("", NOW), null);
});
