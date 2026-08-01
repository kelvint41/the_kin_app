const { onObjectFinalized } = require("firebase-functions/v2/storage");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}
const vision = require("@google-cloud/vision");
const { createNotification } = require("./notifications.js");

const visionClient = new vision.ImageAnnotatorClient();

// storage.rules only allows writes under users/{userId}/**, so every owner
// business-item photo, business hero image, and customer profile photo
// uploaded through ImageUploadButton lands here - this is the single choke
// point for every user-uploaded image in the app (see
// lib/flutter_flow/upload_data.dart's _firebasePathPrefix).
const UPLOAD_PATH_PATTERN = /^users\/([^/]+)\/uploads\//;
const QUARANTINE_PREFIX = "quarantine/";

// LIKELY+ for adult/violence, but VERY_LIKELY only for racy - racy fires on
// a lot of harmless content (swimwear, fitness photos) at the LIKELY
// threshold, and this is auto-quarantine with no human review yet, so a
// looser bar there would pull down legitimate business photos.
function isFlagged(safeSearch) {
  const veryLikelyOrLikely = (v) => v === "LIKELY" || v === "VERY_LIKELY";
  return (
    veryLikelyOrLikely(safeSearch.adult) ||
    veryLikelyOrLikely(safeSearch.violence) ||
    safeSearch.racy === "VERY_LIKELY"
  );
}

/**
 * Fires on every object written under the storage bucket. Only acts on
 * images under users/{uid}/uploads/ (ignores its own quarantine/ writes, or
 * this would trigger itself in a loop). Flagged images are moved out of the
 * public path into quarantine/ - not deleted, so nothing is unrecoverable -
 * and the uploader is notified via the existing in-app notification inbox.
 * No human review queue yet (see launch-blockers memory); this is the
 * "auto-quarantine" tier Kelvin chose over auto-blur or a review queue.
 */
exports.moderateImageUpload = onObjectFinalized(
  { memory: "512MiB" },
  async (event) => {
    const object = event.data;
    const filePath = object.name || "";

    if (filePath.startsWith(QUARANTINE_PREFIX)) {
      return;
    }
    const match = filePath.match(UPLOAD_PATH_PATTERN);
    if (!match) {
      return;
    }
    if (!object.contentType || !object.contentType.startsWith("image/")) {
      return;
    }

    const uid = match[1];
    const bucket = admin.storage().bucket(object.bucket);
    const gcsUri = `gs://${object.bucket}/${filePath}`;

    const [result] = await visionClient.safeSearchDetection(gcsUri);
    const safeSearch = result.safeSearchAnnotation || {};

    if (!isFlagged(safeSearch)) {
      return;
    }

    const quarantinePath = `${QUARANTINE_PREFIX}${filePath}`;
    const file = bucket.file(filePath);
    await file.copy(bucket.file(quarantinePath));
    await file.delete();

    const db = admin.firestore();
    await db.collection("flagged_uploads").add({
      original_path: filePath,
      quarantine_path: quarantinePath,
      uploader_uid: uid,
      safe_search: {
        adult: safeSearch.adult || "UNKNOWN",
        violence: safeSearch.violence || "UNKNOWN",
        racy: safeSearch.racy || "UNKNOWN",
      },
      flagged_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    await createNotification(db, {
      userRef: db.collection("users").doc(uid),
      type: "image_flagged",
      title: "An upload was removed",
      body:
        "One of your photos didn't pass our content check and was taken " +
        "down. If you think this is a mistake, contact support.",
      routeName: null,
    });

    console.log(
      `moderateImageUpload: quarantined ${filePath} for uid ${uid} ` +
        `(adult=${safeSearch.adult}, violence=${safeSearch.violence}, racy=${safeSearch.racy})`,
    );
  },
);
