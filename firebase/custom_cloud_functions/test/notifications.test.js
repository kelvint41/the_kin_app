// Tests for the notifications inbox: the shared write helper
// (notifications.js) and the one new trigger this feature adds
// (claim_notifications.js). recordVerifiedVisit's and
// generateMysteryReward's notification hooks are covered indirectly by
// their own existing test suites continuing to pass (see
// visit_verification.test.js) - this file focuses on what's new.

const assert = require("node:assert/strict");
const { test, beforeEach } = require("node:test");

const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp({ projectId: "demo-kin-test" });
}

const { createNotification } = require("../notifications.js");
const { notifyClaimApproved } = require("../claim_notifications.js");

const db = admin.firestore();

let counter = 0;
const uniq = (p) => `${p}_${++counter}`;

async function clear(collection) {
  const snap = await db.collection(collection).get();
  await Promise.all(snap.docs.map((d) => d.ref.delete()));
}

beforeEach(async () => {
  await Promise.all([clear("notifications"), clear("claim_requests")]);
});

async function notificationsFor(userRef) {
  const snap = await db
    .collection("notifications")
    .where("user_ref", "==", userRef)
    .get();
  return snap.docs.map((d) => d.data());
}

test("createNotification: writes the expected doc shape via a plain db", async () => {
  const userRef = db.collection("users").doc(uniq("user"));
  await createNotification(db, {
    userRef,
    type: "check_in_confirmed",
    title: "Check-in confirmed",
    body: "You checked in at Rollin Smoke.",
    routeName: "KinQuest",
  });

  const notifications = await notificationsFor(userRef);
  assert.equal(notifications.length, 1);
  const doc = notifications[0];
  assert.equal(doc.type, "check_in_confirmed");
  assert.equal(doc.title, "Check-in confirmed");
  assert.equal(doc.body, "You checked in at Rollin Smoke.");
  assert.equal(doc.route_name, "KinQuest");
  assert.equal(doc.is_read, false);
  assert.ok(doc.created_at, "created_at should be set");
});

test("createNotification: defaults route_name to null when omitted", async () => {
  const userRef = db.collection("users").doc(uniq("user"));
  await createNotification(db, {
    userRef,
    type: "reward_unlocked",
    title: "Mystery reward unlocked!",
    body: "Open the app to see what you won.",
  });

  const [doc] = await notificationsFor(userRef);
  assert.equal(doc.route_name, null);
});

test("createNotification: writes through a transaction when given one", async () => {
  const userRef = db.collection("users").doc(uniq("user"));
  await db.runTransaction(async (tx) => {
    await createNotification(tx, {
      userRef,
      type: "check_in_confirmed",
      title: "Check-in confirmed",
      body: "You checked in.",
    });
  });

  const notifications = await notificationsFor(userRef);
  assert.equal(notifications.length, 1);
});

test("createNotification: skips silently when userRef is missing", async () => {
  // Should not throw - a caller with no recipient (e.g. a business with no
  // owner_ref) shouldn't take down the calling transaction over a
  // best-effort notification.
  await createNotification(db, {
    userRef: null,
    type: "check_in_confirmed",
    title: "x",
    body: "y",
  });
  const snap = await db.collection("notifications").get();
  assert.equal(snap.size, 0);
});

function claimEvent({ before, after, requestId }) {
  return {
    data: {
      before: { data: () => before },
      after: { data: () => after },
    },
    params: { requestId },
  };
}

test("notifyClaimApproved: pending -> approved notifies the applicant", async () => {
  const applicantUserId = uniq("uid");
  const requestId = uniq("claim");
  await notifyClaimApproved.run(
    claimEvent({
      before: { status: "pending", applicant_user_id: applicantUserId },
      after: {
        status: "approved",
        applicant_user_id: applicantUserId,
        business_name: "Rollin Smoke BBQ",
      },
      requestId,
    }),
  );

  const userRef = db.collection("users").doc(applicantUserId);
  const notifications = await notificationsFor(userRef);
  assert.equal(notifications.length, 1);
  assert.equal(notifications[0].type, "claim_approved");
  assert.match(notifications[0].body, /Rollin Smoke BBQ/);
  assert.equal(notifications[0].route_name, "OwnerProfile");
});

test("notifyClaimApproved: does nothing when status is unchanged", async () => {
  const applicantUserId = uniq("uid");
  await notifyClaimApproved.run(
    claimEvent({
      before: { status: "approved", applicant_user_id: applicantUserId },
      after: { status: "approved", applicant_user_id: applicantUserId },
      requestId: uniq("claim"),
    }),
  );

  const snap = await db.collection("notifications").get();
  assert.equal(snap.size, 0);
});

test("notifyClaimApproved: does nothing when status moves to rejected", async () => {
  const applicantUserId = uniq("uid");
  await notifyClaimApproved.run(
    claimEvent({
      before: { status: "pending", applicant_user_id: applicantUserId },
      after: { status: "rejected", applicant_user_id: applicantUserId },
      requestId: uniq("claim"),
    }),
  );

  const snap = await db.collection("notifications").get();
  assert.equal(snap.size, 0);
});

test("notifyClaimApproved: approval with no applicant_user_id doesn't throw", async () => {
  await notifyClaimApproved.run(
    claimEvent({
      before: { status: "pending" },
      after: { status: "approved" },
      requestId: uniq("claim"),
    }),
  );

  const snap = await db.collection("notifications").get();
  assert.equal(snap.size, 0);
});
