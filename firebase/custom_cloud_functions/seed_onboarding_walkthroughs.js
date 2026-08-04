// One-time bootstrap script - NOT a Cloud Function, not required by
// index.js, so `firebase deploy --only functions` never picks it up.
// Run manually once (with GOOGLE_APPLICATION_CREDENTIALS pointed at a
// service account) to create the initial onboarding_walkthroughs docs
// read by WalkthroughService/WalkthroughRunner (lib/services/):
//
//   node seed_onboarding_walkthroughs.js
//
// Afterwards, edit copy directly in the Firebase Console at
// onboarding_walkthroughs/{key} - no redeploy or rebuild needed, since
// the app reads this at runtime. Existing docs are left untouched (see
// seed()) so a re-run never clobbers copy someone has already edited.
//
// target_id in each step must match a GlobalKey a screen has actually
// wired up (see WalkthroughRunner usages in google_map_page_widget.dart,
// customer_profile_page_widget.dart, owner_profile_widget.dart) - a step
// whose target_id nothing on screen registers is silently skipped rather
// than shown, so adding a step here alone doesn't do anything without
// also wiring its target in the app.

const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

const WALKTHROUGHS = {
  general_tour: {
    enabled: true,
    steps: [
      {
        target_id: "main_menu",
        title: "Everything starts here",
        body:
          "Tap the menu to find Discover, Community, Quest, and Profile - " +
          "the whole app is organized under these four.",
      },
    ],
  },
  kindex_explainer: {
    enabled: true,
    steps: [
      {
        target_id: "kindex_score",
        title: "Your KINDEX Score",
        body:
          "KINDEX measures real engagement with Black-owned businesses - " +
          "verified visits, reviews, and support all move it. It grows " +
          "with activity and can decrease over time if you go quiet, so " +
          "keep showing up to keep it climbing.",
      },
    ],
  },
};

async function seed() {
  const db = admin.firestore();
  for (const [key, data] of Object.entries(WALKTHROUGHS)) {
    const ref = db.collection("onboarding_walkthroughs").doc(key);
    const existing = await ref.get();
    if (existing.exists) {
      console.log(`onboarding_walkthroughs/${key} already exists, skipping.`);
      continue;
    }
    await ref.set(data);
    console.log(`Seeded onboarding_walkthroughs/${key}.`);
  }
}

seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
