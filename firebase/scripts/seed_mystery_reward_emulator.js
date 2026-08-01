/**
 * EMULATOR-ONLY seed script for the Mystery Reward System. Creates a test
 * owner + business, then increments businesses_discovered_count through
 * the 5/15/30 milestones one at a time (mirroring what submitBusinessDiscovery
 * does, but writing directly so we can watch generateMysteryReward - the
 * businesses/{id} onDocumentUpdated trigger in mystery_reward_engine.js -
 * fire for real against the emulator).
 *
 * Hard-pins FIRESTORE_EMULATOR_HOST / FIRESTORE_AUTH_EMULATOR_HOST before
 * initializing admin, and uses no service account credential at all, so
 * this can never accidentally write to production Firestore even if the
 * calling shell forgot to export the emulator host itself.
 *
 * Usage (with `firebase emulators:start --only firestore,functions` already
 * running in another terminal):
 *   node seed_mystery_reward_emulator.js
 */
process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || "localhost:8080";

const admin = require("firebase-admin");
admin.initializeApp({ projectId: "kinvest-build-app" });
const db = admin.firestore();

const TEST_USER_ID = "mystery_reward_test_owner";
const TEST_BUSINESS_ID = "mystery_reward_test_business";
const MILESTONES = [5, 15, 30];

async function main() {
  console.log(`Seeding against emulator at ${process.env.FIRESTORE_EMULATOR_HOST} ...`);

  const userRef = db.collection("users").doc(TEST_USER_ID);
  await userRef.set(
    {
      display_name: "Mystery Reward Test Owner",
      email: "mystery-reward-test@example.com",
    },
    { merge: true },
  );

  const businessRef = db.collection("businesses").doc(TEST_BUSINESS_ID);
  await businessRef.set(
    {
      business_name: "Mystery Reward Test Business",
      owner_ref: userRef,
      owner_name: "Mystery Reward Test Owner",
      city: "San Antonio",
      businesses_discovered_count: 0,
    },
    { merge: true },
  );

  for (const milestone of MILESTONES) {
    console.log(`Bumping businesses_discovered_count to ${milestone} ...`);
    await businessRef.update({ businesses_discovered_count: milestone });
    // Give the onDocumentUpdated trigger a moment to run before the next
    // write, so each milestone crossing is observed as its own update
    // rather than collapsed together.
    await new Promise((resolve) => setTimeout(resolve, 2000));
  }

  const rewardsSnap = await db
    .collection("unlocked_rewards")
    .where("user_ref", "==", userRef)
    .get();

  console.log(`\nDone. ${rewardsSnap.size} reward(s) generated for ${TEST_USER_ID}:`);
  rewardsSnap.forEach((doc) => {
    const r = doc.data();
    console.log(`  - ${r.reward_type} (tier: ${r.tier_unlocked}), promo ${r.promo_code}`);
  });
  console.log(
    "\nOpen the Emulator UI (http://localhost:4000/firestore) to inspect unlocked_rewards, kin_feed_events, and system_counters.",
  );
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
