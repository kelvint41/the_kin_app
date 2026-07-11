const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");

// Public projection pipeline for kinvestguidance.com (WEBSITE_BLUEPRINT.md
// §2.3). The website never reads app collections directly — `businesses`
// carries owner PII (email, phone_number, owner_name, address). These
// functions copy a WHITELIST of web-safe fields into web_public/*, which is
// the only collection the site can read (rules: public read, no client
// write; these writes go through the Admin SDK).

const MAP_CITIES = ["San Antonio", "Houston", "Atlanta"];
const TICKER_LIMIT = 20;
const MAP_POINTS_PER_CITY = 250;
const SIGNUP_FEED_LIMIT = 10;

// Ticker + map density points, recomputed on a fixed cadence. A 5-minute
// sweep reads as "live" for score movement while keeping write volume flat
// no matter how busy the app gets.
exports.publishWebProjection = functions.pubsub
  .schedule("*/5 * * * *")
  .onRun(async () => {
    const db = admin.firestore();

    const [bizSnap, memberSnap, ...citySnaps] = await Promise.all([
      db
        .collection("businesses")
        .orderBy("kindex_score", "desc")
        .limit(TICKER_LIMIT)
        .get(),
      db
        .collection("KindexScores")
        .orderBy("score", "desc")
        .limit(TICKER_LIMIT)
        .get(),
      ...MAP_CITIES.map((city) =>
        db
          .collection("businesses")
          .where("city", "==", city)
          .limit(MAP_POINTS_PER_CITY)
          .get()
      ),
    ]);

    const businesses = bizSnap.docs
      .map((d) => d.data())
      .filter((b) => b.ticker_symbol)
      .map((b) => ({
        ticker: b.ticker_symbol,
        name: b.business_name || "",
        score: Math.round((b.kindex_score || 0) * 10) / 10,
        trendingUp: (b.kindex_velocity || 0) >= 0,
      }));

    const members = memberSnap.docs
      .map((d) => d.data())
      .filter((m) => m.ticker_symbol)
      .map((m) => ({
        ticker: m.ticker_symbol,
        score: Math.round((m.score || 0) * 10) / 10,
        trendingUp: m.is_trending_up !== false,
      }));

    const cities = {};
    MAP_CITIES.forEach((city, i) => {
      cities[city] = citySnaps[i].docs
        .map((d) => d.data())
        .filter((b) => b.latitude && b.longitude)
        .map((b) => ({
          // Whitelist only: public directory facts, never owner contact info.
          lat: Math.round(b.latitude * 1e5) / 1e5,
          lng: Math.round(b.longitude * 1e5) / 1e5,
          name: b.business_name || "",
          category: b.category || "",
        }));
    });

    const updatedAt = admin.firestore.FieldValue.serverTimestamp();
    await Promise.all([
      db
        .collection("web_public")
        .doc("ticker")
        .set({ businesses, members, updatedAt }),
      db.collection("web_public").doc("map").set({ cities, updatedAt }),
    ]);

    console.log(
      `[web_projection] ticker: ${businesses.length} businesses / ` +
        `${members.length} members; map: ` +
        MAP_CITIES.map((c) => `${c}=${cities[c].length}`).join(", ")
    );
    return null;
  });

// "New Sign-up Flash": every new business appends a sanitized entry to a
// single capped document the website polls/streams for toast notifications.
exports.publishSignupFlash = functions.firestore
  .document("businesses/{businessId}")
  .onCreate(async (snapshot) => {
    const data = snapshot.data() || {};
    const name = (data.business_name || "").trim();
    const city = (data.city || "").trim();
    if (!name) return null; // nothing worth announcing

    const db = admin.firestore();
    const feedRef = db.collection("web_public").doc("signups");

    const entry = {
      // Random ID lets the web client dedupe toasts across polls without
      // exposing the business document ID.
      id: crypto.randomBytes(8).toString("hex"),
      name,
      city,
      // serverTimestamp() isn't allowed inside arrayUnion-style updates,
      // so the trigger stamps the time itself.
      at: admin.firestore.Timestamp.now(),
    };

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(feedRef);
      const items = (snap.exists && snap.data().items) || [];
      items.unshift(entry);
      tx.set(feedRef, {
        items: items.slice(0, SIGNUP_FEED_LIMIT),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    console.log(`[web_projection] signup flash: ${name} (${city})`);
    return null;
  });
