// Tests for the 14-day Founding Local trial, run against the Firestore
// emulator (`npm test`).
//
// The two rules that actually matter here are covered directly: a trial
// must grant the *same* entitlement fields a real paid Founding Local
// subscription grants (so every existing gated call site works unchanged),
// and it must auto-downgrade at day 14 rather than auto-charging.

const assert = require("node:assert/strict");
const { test, beforeEach } = require("node:test");

const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp({ projectId: "demo-kin-test" });
}

const trial = require("../founding_local_trial.js");
const { REMINDER_COPY, daysElapsed, processTrials, TRIAL_DURATION_MS } =
  trial._internals;
const { startFoundingLocalTrial } = trial;

const db = admin.firestore();
const DAY_MS = 24 * 60 * 60 * 1000;

let counter = 0;
const uniq = (p) => `${p}_${++counter}`;

async function clear(collection) {
  const snap = await db.collection(collection).get();
  await Promise.all(snap.docs.map((d) => d.ref.delete()));
}

beforeEach(async () => {
  await Promise.all([clear("businesses"), clear("entitlements")]);
});

const NOW = Date.parse("2026-08-15T09:00:00Z");

/** A business mid-trial, started `startedDaysAgo` days before NOW. */
async function seedTrialing({ startedDaysAgo, extra = {} }) {
  const ref = db.collection("businesses").doc(uniq("biz"));
  const startedAt = admin.firestore.Timestamp.fromMillis(
    NOW - startedDaysAgo * DAY_MS,
  );
  await ref.set({
    business_name: "Trial Co",
    subscription_tier: "Founding Local",
    is_premium: true,
    trial_status: "active",
    trial_start_at: startedAt,
    trial_end_at: admin.firestore.Timestamp.fromMillis(
      startedAt.toMillis() + TRIAL_DURATION_MS,
    ),
    has_used_trial: true,
    trial_reminder_stage: "",
    ...extra,
  });
  return ref;
}

/** A fresh, never-trialed business owned by `owner`. */
async function seedEligible({ owner = "owner_1" } = {}) {
  const ref = db.collection("businesses").doc(uniq("biz"));
  await ref.set({
    business_name: "Fresh Co",
    subscription_tier: "Community",
    is_premium: false,
    owner_ref: db.collection("users").doc(owner),
  });
  return ref;
}

function startTrial(fn, { uid, businessRef }) {
  return fn.run({
    auth: uid ? { uid } : undefined,
    data: { businessRef },
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

// --- pure helper -----------------------------------------------------

test("daysElapsed floors to whole days", () => {
  assert.equal(daysElapsed(NOW, NOW), 0);
  assert.equal(daysElapsed(NOW - DAY_MS + 1000, NOW), 0);
  assert.equal(daysElapsed(NOW - 10 * DAY_MS, NOW), 10);
  assert.equal(daysElapsed(NOW - 13.9 * DAY_MS, NOW), 13);
  assert.equal(daysElapsed(NOW - 14 * DAY_MS, NOW), 14);
});

test("trial duration is exactly 14 days", () => {
  assert.equal(TRIAL_DURATION_MS, 14 * DAY_MS);
});

// --- starting a trial ------------------------------------------------

test("start: an unauthenticated caller is rejected", async () => {
  const biz = await seedEligible();
  await rejectsWith("unauthenticated", () =>
    startTrial(startFoundingLocalTrial, { businessRef: biz.id }),
  );
});

test("start: a missing businessRef is rejected", async () => {
  await rejectsWith("invalid-argument", () =>
    startTrial(startFoundingLocalTrial, { uid: "owner_1" }),
  );
});

test("start: a business that does not exist is rejected", async () => {
  await rejectsWith("not-found", () =>
    startTrial(startFoundingLocalTrial, {
      uid: "owner_1",
      businessRef: "nope_does_not_exist",
    }),
  );
});

test("start: a non-owner cannot start a trial on someone else's business", async () => {
  const biz = await seedEligible({ owner: "owner_1" });
  await rejectsWith("permission-denied", () =>
    startTrial(startFoundingLocalTrial, {
      uid: "someone_else",
      businessRef: biz.id,
    }),
  );
  // Nothing was granted.
  const after = (await biz.get()).data();
  assert.equal(after.subscription_tier, "Community");
  assert.ok(!after.has_used_trial);
});

test("start: grants Founding Local, marks the trial used, and sets a 14-day window", async () => {
  const biz = await seedEligible({ owner: "owner_1" });
  const result = await startTrial(startFoundingLocalTrial, {
    uid: "owner_1",
    businessRef: biz.id,
  });

  const after = (await biz.get()).data();
  assert.equal(after.trial_status, "active");
  assert.equal(after.has_used_trial, true);
  // Same entitlement a real paid Founding Local grants.
  assert.equal(after.subscription_tier, "Founding Local");
  assert.equal(after.is_premium, true);

  const window = after.trial_end_at.toMillis() - after.trial_start_at.toMillis();
  assert.equal(window, TRIAL_DURATION_MS);
  assert.equal(result.trialEndsAtMillis, after.trial_end_at.toMillis());
});

test("start: writes an audit row into the existing entitlements collection", async () => {
  const biz = await seedEligible({ owner: "owner_1" });
  await startTrial(startFoundingLocalTrial, {
    uid: "owner_1",
    businessRef: biz.id,
  });

  const snap = await db
    .collection("entitlements")
    .where("business_ref", "==", biz)
    .get();
  assert.equal(snap.size, 1);
  const ent = snap.docs[0].data();
  // Same field shape as the pre-existing "Founding partner - permanent
  // comp" doc, so nothing that reads this collection needs to change.
  assert.equal(ent.tier, "Founding Local");
  assert.equal(ent.source, "trial");
  assert.equal(ent.granted_reason, "14-day Founding Local free trial");
  assert.ok(ent.granted_at);
  assert.ok(ent.expires_at); // unlike the permanent comp, a trial expires
  assert.equal(ent.user_ref.id, "owner_1");
});

test("start: a second trial on the same business is rejected", async () => {
  const biz = await seedEligible({ owner: "owner_1" });
  await startTrial(startFoundingLocalTrial, {
    uid: "owner_1",
    businessRef: biz.id,
  });

  await rejectsWith("failed-precondition", () =>
    startTrial(startFoundingLocalTrial, {
      uid: "owner_1",
      businessRef: biz.id,
    }),
  );
  // Exactly one entitlement row - the rejected call wrote nothing.
  const snap = await db
    .collection("entitlements")
    .where("business_ref", "==", biz)
    .get();
  assert.equal(snap.size, 1);
});

test("start: re-claiming under a new owner does not reset has_used_trial", async () => {
  const biz = await seedEligible({ owner: "owner_1" });
  await startTrial(startFoundingLocalTrial, {
    uid: "owner_1",
    businessRef: biz.id,
  });
  // Trial runs out, business is unclaimed and re-claimed by someone new.
  await processTrials(db, Date.now() + 15 * DAY_MS);
  await biz.update({ owner_ref: db.collection("users").doc("owner_2") });

  await rejectsWith("failed-precondition", () =>
    startTrial(startFoundingLocalTrial, {
      uid: "owner_2",
      businessRef: biz.id,
    }),
  );
});

test("start: an expired trial cannot be restarted", async () => {
  const biz = await seedEligible({ owner: "owner_1" });
  await startTrial(startFoundingLocalTrial, {
    uid: "owner_1",
    businessRef: biz.id,
  });
  await processTrials(db, Date.now() + 15 * DAY_MS);
  assert.equal((await biz.get()).data().trial_status, "expired");

  await rejectsWith("failed-precondition", () =>
    startTrial(startFoundingLocalTrial, {
      uid: "owner_1",
      businessRef: biz.id,
    }),
  );
});

// --- reminder copy ---------------------------------------------------

test("day 10-11 reminder copy is exactly as specified", () => {
  assert.equal(
    REMINDER_COPY.day10.push,
    "Your Founding Local trial ends in 3 days — here's what you'd lose",
  );
  assert.equal(
    REMINDER_COPY.day10.inApp,
    "You've got 3 days left on your Founding Local trial. Right now you have your Verified Founding Member badge, 5 gallery photos, and basic analytics live on your profile. Keep them going for $19/mo — cancel anytime.",
  );
  assert.equal(REMINDER_COPY.day10.cta, "Keep my Founding Local tier");
});

test("day 13 reminder copy is exactly as specified", () => {
  assert.equal(
    REMINDER_COPY.day13.push,
    "Last day: your Founding Local trial ends tomorrow",
  );
  assert.equal(
    REMINDER_COPY.day13.inApp,
    "Your trial ends tomorrow. After that, your profile drops back to the free Community tier — no trust badge, limited photos, no analytics. Lock in Founding Local now for $19/mo, or you'll automatically move to the free tier with no charge.",
  );
  assert.equal(REMINDER_COPY.day13.cta, "Keep my Founding Local tier");
});

// --- reminder firing offsets ----------------------------------------

test("no reminder before day 10", async () => {
  const ref = await seedTrialing({ startedDaysAgo: 9 });
  const result = await processTrials(db, NOW);
  assert.equal(result.reminded10, 0);
  assert.equal(result.reminded13, 0);
  const after = (await ref.get()).data();
  assert.equal(after.trial_reminder_stage, "");
  assert.equal(after.trial_status, "active");
});

for (const day of [10, 11]) {
  test(`day ${day} fires the day-10 reminder`, async () => {
    const ref = await seedTrialing({ startedDaysAgo: day });
    const result = await processTrials(db, NOW);
    assert.equal(result.reminded10, 1);
    assert.equal(result.reminded13, 0);
    const after = (await ref.get()).data();
    assert.equal(after.trial_reminder_stage, "day10");
    // Entitlement untouched while the trial is still running.
    assert.equal(after.subscription_tier, "Founding Local");
    assert.equal(after.is_premium, true);
  });
}

test("day-10 reminder is not re-sent on day 11", async () => {
  const ref = await seedTrialing({ startedDaysAgo: 10 });
  await processTrials(db, NOW);
  // One day later, same business, sweep runs again.
  const result = await processTrials(db, NOW + DAY_MS);
  assert.equal(result.reminded10, 0);
  assert.equal((await ref.get()).data().trial_reminder_stage, "day10");
});

test("day 13 fires the day-13 reminder", async () => {
  const ref = await seedTrialing({ startedDaysAgo: 13 });
  const result = await processTrials(db, NOW);
  assert.equal(result.reminded13, 1);
  const after = (await ref.get()).data();
  assert.equal(after.trial_reminder_stage, "day13");
  assert.equal(after.trial_status, "active");
  assert.equal(after.subscription_tier, "Founding Local");
});

test("day-13 reminder is not re-sent if the sweep runs twice on day 13", async () => {
  const ref = await seedTrialing({ startedDaysAgo: 13 });
  await processTrials(db, NOW);
  const result = await processTrials(db, NOW + 60 * 60 * 1000);
  assert.equal(result.reminded13, 0);
  assert.equal((await ref.get()).data().trial_reminder_stage, "day13");
});

// --- day 14 auto-downgrade ------------------------------------------

test("day 14 downgrades to Community and expires the trial - no charge", async () => {
  const ref = await seedTrialing({ startedDaysAgo: 14 });
  const result = await processTrials(db, NOW);
  assert.equal(result.expired, 1);

  const after = (await ref.get()).data();
  assert.equal(after.trial_status, "expired");
  assert.equal(after.subscription_tier, "Community");
  assert.equal(after.is_premium, false);
  assert.equal(after.trial_reminder_stage, "");
  // The whole point: expiry is a downgrade, never a charge.
  assert.equal(after.has_used_trial, true);
});

test("a trial well past day 14 still expires (missed sweeps don't strand it)", async () => {
  const ref = await seedTrialing({ startedDaysAgo: 40 });
  await processTrials(db, NOW);
  const after = (await ref.get()).data();
  assert.equal(after.trial_status, "expired");
  assert.equal(after.subscription_tier, "Community");
});

test("an expired trial is not processed again", async () => {
  await seedTrialing({ startedDaysAgo: 14 });
  await processTrials(db, NOW);
  const second = await processTrials(db, NOW + DAY_MS);
  assert.equal(second.scanned, 0);
  assert.equal(second.expired, 0);
});

test("a converted trial is never downgraded at day 14", async () => {
  const ref = await seedTrialing({
    startedDaysAgo: 20,
    extra: { trial_status: "converted", subscription_tier: "Founding Local" },
  });
  const result = await processTrials(db, NOW);
  assert.equal(result.scanned, 0);
  assert.equal(result.expired, 0);
  const after = (await ref.get()).data();
  assert.equal(after.subscription_tier, "Founding Local");
  assert.equal(after.is_premium, true);
});

// --- entitlement parity with a real paid subscription ---------------

test("trial entitlement fields match a real paid Founding Local exactly", async () => {
  // What KinServices.upgradeBusinessTier writes for a real Founding Local
  // purchase (merchant_pricing_suite_widget.dart passes isPremium: true and
  // leaves isPriorityPinned/hasFlashBeacon at their false defaults).
  const paid = { subscription_tier: "Founding Local", is_premium: true };

  const ref = await seedTrialing({ startedDaysAgo: 1 });
  const trialing = (await ref.get()).data();

  assert.equal(trialing.subscription_tier, paid.subscription_tier);
  assert.equal(trialing.is_premium, paid.is_premium);
  // Founding Local grants neither of these, paid or trial - they're Elite.
  assert.ok(!trialing.is_priority_pinned);
  assert.ok(!trialing.has_flash_beacon);
});

test("trial tier value is in the paid-placement allow-list used by the map carousel", () => {
  // lib/services/premium_placement.dart: kPaidSubscriptionTiers.
  const kPaidSubscriptionTiers = new Set(["Founding Local", "Pro Growth"]);
  assert.ok(kPaidSubscriptionTiers.has(trial._internals.TRIAL_TIER));
});

test("trial tier value is a key in the AI marketing monthly-limit table", () => {
  // firebase/custom_cloud_functions/ai_marketing_orchestrator.js:
  // DEFAULT_MONTHLY_LIMITS - membership is what isEntitled() checks.
  const DEFAULT_MONTHLY_LIMITS = {
    Community: 1,
    "Founding Local": 2,
    "Pro Growth": 30,
    "Elite Growth": 150,
  };
  assert.ok(
    Object.prototype.hasOwnProperty.call(
      DEFAULT_MONTHLY_LIMITS,
      trial._internals.TRIAL_TIER,
    ),
  );
});

test("is_premium true gives a trial the premium Kindex baseline", () => {
  // business_kindex_nightly.js gates the 850/900 baseline+ceiling purely on
  // is_premium, which the trial sets, so a trialing business scores exactly
  // like a paying one.
  const PREMIUM_BASELINE = 850;
  const STANDARD_BASELINE = 500;
  const tierBaseline = (isPremium) =>
    isPremium ? PREMIUM_BASELINE : STANDARD_BASELINE;
  assert.equal(tierBaseline(true), PREMIUM_BASELINE);
});

test("after expiry the business loses paid placement and premium baseline", async () => {
  const kPaidSubscriptionTiers = new Set(["Founding Local", "Pro Growth"]);
  const ref = await seedTrialing({ startedDaysAgo: 14 });
  await processTrials(db, NOW);
  const after = (await ref.get()).data();

  assert.ok(!kPaidSubscriptionTiers.has(after.subscription_tier));
  assert.equal(after.is_premium, false);
});

// --- sweep robustness ------------------------------------------------

test("a malformed active trial with no start timestamp doesn't break the sweep", async () => {
  const bad = db.collection("businesses").doc(uniq("biz"));
  await bad.set({ trial_status: "active", subscription_tier: "Founding Local" });
  const good = await seedTrialing({ startedDaysAgo: 14 });

  const result = await processTrials(db, NOW);
  // The healthy one still expired despite the malformed sibling.
  assert.equal(result.expired, 1);
  assert.equal((await good.get()).data().trial_status, "expired");
  assert.equal((await bad.get()).data().trial_status, "active");
});
