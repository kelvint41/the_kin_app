const functions = require("firebase-functions");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

// Reactor score at/above this counts as "notable" for amplification -
// matches the Founding Backer tier and up in kindex_tiers.dart (Flutter).
// Duplicated as a plain number here rather than shared, same reasoning as
// haversineMeters/geohash_util.dart's split: one runtime is Dart, one is
// JS, and this scoring is frozen pre-launch so the threshold won't drift
// out from under a shared constant that doesn't exist anyway.
const NOTABLE_KINDEX_THRESHOLD = 720;

// Reactions that can trigger amplification (see kQuickReactions in
// exchange_feed_item_widget.dart) - a vouch and the app's own name for
// itself, the two reaction types meant to carry that weight.
const AMPLIFYING_EVENT_TYPES = new Set(["react_backed", "react_spotlight"]);

/**
 * A third, independent onCreate trigger on UserEngagementEvents, alongside
 * kindex_engine.js's processUserEngagementEvent and showcase_interest.js's
 * recordItemInterest. Own idempotency marker (reaction_counted), same
 * reasoning as showcase_interest.js: Cloud Functions' at-least-once
 * redelivery can't double-increment a counter this trigger tracks
 * independently of the other two triggers on the same event doc.
 *
 * Two things happen here for a react_* event targeting an exchange_posts
 * doc:
 *  - reaction_counts.<event_type> increments - this is what persists what
 *    ExchangeFeedItemWidget's _reactedEmoji used to hold only in memory,
 *    lost on every app restart.
 *  - for react_backed/react_spotlight specifically, if the reactor's own
 *    KindexScores.score is at/above NOTABLE_KINDEX_THRESHOLD,
 *    notable_reaction is stamped on the post with their name - last
 *    notable reactor only, not a growing list, so a popular post's single
 *    document doesn't become a write-contention hot spot.
 *
 * Testable core, separate from the trigger wrapper below - same
 * take-a-ref-not-a-snapshot convention as showcase_interest.js's
 * processEvent, so tests can call it directly against the emulator.
 */
async function processEvent(eventRef) {
  const db = admin.firestore();
  const eventSnap = await eventRef.get();
  const event = eventSnap.data();
  if (!event) return;
  if (event.reaction_counted === true) return;

  const eventType = event.event_type;
  const targetRef = event.target_ref;
  const isExchangeReaction =
    !!targetRef &&
    targetRef.parent.id === "exchange_posts" &&
    typeof eventType === "string" &&
    eventType.startsWith("react_");

  if (!isExchangeReaction) {
    await eventRef.update({ reaction_counted: true });
    return;
  }

  // Done outside the transaction below on purpose: this reads two other
  // documents (KindexScores, then users/exchange_profiles), and a
  // Firestore transaction requires every read before any write. Racing a
  // same-second score update is an acceptable staleness window for a
  // "notable" label; the counter increment itself is what actually needs
  // transactional correctness under concurrent reactions.
  let notableReaction = null;
  if (AMPLIFYING_EVENT_TYPES.has(eventType) && event.user_ref) {
    notableReaction = await lookupNotableReactor(db, event.user_ref, eventType);
  }

  await db.runTransaction(async (tx) => {
    const freshSnap = await tx.get(eventRef);
    const freshEvent = freshSnap.data();
    if (!freshEvent || freshEvent.reaction_counted === true) return;

    const update = {
      [`reaction_counts.${eventType}`]: admin.firestore.FieldValue.increment(1),
    };
    if (notableReaction) {
      update.notable_reaction = notableReaction;
    }
    tx.update(targetRef, update);
    tx.update(eventRef, { reaction_counted: true });
  });
}

/**
 * Returns {name, event_type} when [userRef]'s KindexScores.score clears
 * NOTABLE_KINDEX_THRESHOLD and a display name can be found, else null - a
 * reactor with no score doc, a below-threshold score, or no resolvable
 * name simply doesn't amplify anything, rather than stamping a blank or
 * placeholder label.
 */
async function lookupNotableReactor(db, userRef, eventType) {
  const scoreSnap = await db.collection("KindexScores").doc(userRef.id).get();
  const score = scoreSnap.exists ? scoreSnap.data().score : null;
  if (typeof score !== "number" || score < NOTABLE_KINDEX_THRESHOLD) {
    return null;
  }

  // users/{uid} first (the account's own name), exchange_profiles/{uid}
  // as a fallback - mirrors businessCoords()'s "try multiple shapes"
  // convention (business_geohash_on_create.js) rather than assuming one
  // is always populated. Admin SDK reads bypass firestore.rules, so
  // reading another user's users/ doc here is fine even though a client
  // could never do it directly.
  const userSnap = await userRef.get();
  let name = userSnap.exists ? userSnap.data().display_name : null;
  if (!name) {
    const profileSnap = await db
      .collection("exchange_profiles")
      .doc(userRef.id)
      .get();
    name = profileSnap.exists ? profileSnap.data().display_name : null;
  }
  if (!name) return null;

  return { name, event_type: eventType };
}

exports.recordExchangeReactionCounts = functions.firestore
  .document("UserEngagementEvents/{eventId}")
  .onCreate((snapshot) => processEvent(snapshot.ref));

exports._internals = { processEvent, lookupNotableReactor };
