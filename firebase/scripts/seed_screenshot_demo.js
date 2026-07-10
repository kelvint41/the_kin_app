// One-time (idempotent) seed for App Store / Play Store screenshot
// generation. Creates a single clean demo business plus supporting posts,
// reviews, and leaderboard data so the automated screenshot run
// (integration_test/app_screenshots_test.dart, driven by
// .github/workflows/screenshots.yml) has something presentable to render -
// never run against anything but a project you're comfortable seeding
// marketing/demo data into.
//
// All demo doc IDs are fixed strings (not auto-generated) so the CI
// workflow's DEV_ROUTE query params can reference them directly without a
// lookup step. Every demo record is named distinctly ("... (Screenshot
// Demo)") so it's never mistaken for a real business/review while browsing
// Firestore, and is easy to find/delete later.
//
// Usage: node seed_screenshot_demo.js
// Requires serviceAccountKey.json in this directory (see other scripts
// here for the same convention) and NODE_PATH pointing at a node_modules
// with firebase-admin installed, e.g.:
//   NODE_PATH=../custom_cloud_functions/node_modules node seed_screenshot_demo.js

const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const DEMO_BUSINESS_ID = "screenshot_demo_business";
const DEMO_OWNER_UID_PLACEHOLDER = "__DEV_BYPASS_UID__"; // replaced below

const SUPPORTING_BUSINESSES = [
  { id: "screenshot_demo_biz_2", name: "Heritage Coffee Roasters (Screenshot Demo)", category: "Coffee shop", score: 842 },
  { id: "screenshot_demo_biz_3", name: "The Golden Needle Tailors (Screenshot Demo)", category: "Tailor", score: 761 },
  { id: "screenshot_demo_biz_4", name: "Ivy & Iron Fitness (Screenshot Demo)", category: "Gym", score: 705 },
  { id: "screenshot_demo_biz_5", name: "Bloom & Bramble Florals (Screenshot Demo)", category: "Florist", score: 668 },
];

const DEMO_REVIEWERS = [
  { id: "screenshot_demo_reviewer_1", displayName: "Jasmine R.", tickerSymbol: "JASM1" },
  { id: "screenshot_demo_reviewer_2", displayName: "Marcus T.", tickerSymbol: "MARC1" },
  { id: "screenshot_demo_reviewer_3", displayName: "Aaliyah W.", tickerSymbol: "AALI1" },
];

const DEMO_POSTS = [
  "New menu drop this weekend — smoked brisket sandwich with our house pickles. Come hungry.",
  "Thank you for 500 five-star reviews this year. This community built this business. ❤️",
  "Reminder: we're open late tonight for the block party. Live music starts at 7.",
  "Fresh batch of cornbread just came out of the oven. First 20 customers get a free slice.",
];

const DEMO_REVIEWS = [
  { rating: 5.0, text: "Best barbecue in the city, hands down. The staff remembered my order from last time — that's how you know a place is special." },
  { rating: 5.0, text: "Went for a birthday dinner and they made it feel like a celebration. Will absolutely be back." },
  { rating: 4.0, text: "Great food, great vibe. A little wait on a Friday night but worth it." },
];

async function main() {
  const devUid = process.env.SEED_DEV_UID;
  if (!devUid) {
    console.error("Set SEED_DEV_UID to the dev-bypass account's Firebase Auth uid before running this script.");
    process.exit(1);
  }

  const businessRef = db.collection("businesses").doc(DEMO_BUSINESS_ID);
  const userRef = db.collection("users").doc(devUid);

  await businessRef.set(
    {
      business_name: "Rollin' Smoke Kitchen (Screenshot Demo)",
      category: "Barbecue restaurant",
      description:
        "Slow-smoked, family-recipe barbecue in the heart of the neighborhood. Black-owned since 2014, proud to serve the community that built us.",
      owner_ref: userRef,
      owner_name: "Kelvin A.",
      address: "412 S Flores St, San Antonio, TX 78204",
      city: "San Antonio",
      state: "Texas",
      zip_code_postcode: "78204",
      phone_number: "2105550142",
      website: "https://rollinsmokekitchen.example.com",
      opening_time: "11:00 AM",
      closing_time: "10:00 PM",
      is_black_owned: true,
      is_verified: true,
      is_claimed: true,
      is_premium: true,
      subscription_tier: "Elite Growth",
      ticker_symbol: "SMOKE",
      kindex_score: 918,
      review_count: DEMO_REVIEWS.length,
      review_score: 4.7,
      doordash_url: "https://doordash.com",
      ubereats_url: "https://ubereats.com",
      grubhub_url: "https://grubhub.com",
      has_flash_beacon: false,
    },
    { merge: true },
  );
  console.log(`Seeded business: ${DEMO_BUSINESS_ID}`);

  await userRef.set({ owned_business: businessRef }, { merge: true });
  console.log(`Linked dev-bypass account (${devUid}) as owner`);

  for (const biz of SUPPORTING_BUSINESSES) {
    await db.collection("businesses").doc(biz.id).set(
      {
        business_name: biz.name,
        category: biz.category,
        city: "San Antonio",
        state: "Texas",
        is_black_owned: true,
        is_verified: true,
        is_claimed: true,
        kindex_score: biz.score,
        kindex_velocity: 1,
      },
      { merge: true },
    );
  }
  console.log(`Seeded ${SUPPORTING_BUSINESSES.length} supporting businesses for the leaderboard`);

  for (const reviewer of DEMO_REVIEWERS) {
    await db.collection("users").doc(reviewer.id).set(
      {
        display_name: reviewer.displayName,
        ticker_symbol: reviewer.tickerSymbol,
      },
      { merge: true },
    );
    await db.collection("KindexScores").doc(reviewer.id).set(
      {
        user_ref: db.collection("users").doc(reviewer.id),
        score: 400 + Math.floor(Math.random() * 500),
        ticker_symbol: reviewer.tickerSymbol,
        is_trending_up: true,
        last_updated: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
  console.log(`Seeded ${DEMO_REVIEWERS.length} demo reviewers + Kindex scores`);

  const postsSnapshot = await db
    .collection("exchange_posts")
    .where("business_ref", "==", businessRef)
    .get();
  if (postsSnapshot.empty) {
    for (let i = 0; i < DEMO_POSTS.length; i++) {
      const postRef = db.collection("exchange_posts").doc();
      await postRef.set({
        post_id: postRef.id,
        user_ref: userRef,
        business_ref: businessRef,
        post_text: DEMO_POSTS[i],
        timestamp: admin.firestore.Timestamp.fromMillis(Date.now() - i * 6 * 60 * 60 * 1000),
        likes_count: 12 + i * 7,
      });
    }
    console.log(`Seeded ${DEMO_POSTS.length} demo posts`);
  } else {
    console.log("Demo posts already exist, skipping");
  }

  const reviewsSnapshot = await db
    .collection("reviews")
    .where("business_ref", "==", businessRef)
    .get();
  if (reviewsSnapshot.empty) {
    for (let i = 0; i < DEMO_REVIEWS.length; i++) {
      const reviewer = DEMO_REVIEWERS[i % DEMO_REVIEWERS.length];
      const reviewRef = db.collection("reviews").doc();
      await reviewRef.set({
        business_ref: businessRef,
        user_ref: db.collection("users").doc(reviewer.id),
        rating: DEMO_REVIEWS[i].rating,
        review_text: DEMO_REVIEWS[i].text,
        timestamp: admin.firestore.Timestamp.fromMillis(Date.now() - i * 30 * 60 * 60 * 1000),
      });
    }
    console.log(`Seeded ${DEMO_REVIEWS.length} demo reviews`);
  } else {
    console.log("Demo reviews already exist, skipping");
  }

  console.log("\nDone. Demo business path for DEV_ROUTE query params: businesses/" + DEMO_BUSINESS_ID);
  console.log("  /theExchange?businessRef=" + DEMO_BUSINESS_ID);
  console.log("  /businessProfileV2?businessDocument=" + DEMO_BUSINESS_ID);
  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
