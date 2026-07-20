const functions = require("firebase-functions");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

const { hasPersistentBeacon } = require("./tier_config.js");

const BATCH_SIZE = 450; // stays under Firestore's 500-write batch limit

// Scheduled audit of every business with has_flash_beacon == true. A beacon is
// legitimate only if EITHER:
//   - it's an ACTIVE Power Hour: flash_beacon_expires_at is set and in the
//     future, OR
//   - the business's subscription tier grants a PERSISTENT beacon
//     (tier_config hasFlashBeacon - today only Elite Growth).
// Anything else is cleared: a past-expiry Power Hour (the original job), and
// now also a beacon with NO expiry on a tier that doesn't grant one - the old
// Elite-parity orphan, or drift left after a downgrade.
//
// The previous version queried has_flash_beacon == true AND
// flash_beacon_expires_at < now. That range filter silently skipped docs
// missing flash_beacon_expires_at, so no-expiry beacons could never be cleared.
// Querying on has_flash_beacon alone and auditing each doc in code fixes that.
exports.checkAndExpireBeacons = functions.pubsub
  .schedule("*/5 * * * *")
  .onRun(async () => {
    const db = admin.firestore();
    const nowMs = Date.now();

    const activeBeacons = await db
      .collection("businesses")
      .where("has_flash_beacon", "==", true)
      .get();

    if (activeBeacons.empty) {
      console.log("No active beacons to audit.");
      return null;
    }

    const toClear = [];
    activeBeacons.docs.forEach((doc) => {
      const data = doc.data();
      const expiresAt = data.flash_beacon_expires_at;
      const activePowerHour =
        !!expiresAt &&
        typeof expiresAt.toMillis === "function" &&
        expiresAt.toMillis() > nowMs;
      const tierGrantsBeacon = hasPersistentBeacon(data.subscription_tier);

      // Leave legitimate beacons on; clear everything else.
      if (!activePowerHour && !tierGrantsBeacon) {
        toClear.push(doc.ref);
      }
    });

    if (toClear.length === 0) {
      console.log(
        `Audited ${activeBeacons.size} beacon(s); all valid, none cleared.`,
      );
      return null;
    }

    // Commit in chunks so a large sweep stays under the batch write limit.
    for (let i = 0; i < toClear.length; i += BATCH_SIZE) {
      const batch = db.batch();
      toClear.slice(i, i + BATCH_SIZE).forEach((ref) => {
        batch.update(ref, { has_flash_beacon: false });
      });
      await batch.commit();
    }

    console.log(
      `Cleared ${toClear.length} invalid/expired beacon(s) of ` +
        `${activeBeacons.size} audited.`,
    );
    return null;
  });
