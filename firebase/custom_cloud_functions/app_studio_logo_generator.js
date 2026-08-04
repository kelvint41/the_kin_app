const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const crypto = require("crypto");
const { GoogleGenAI, SafetyFilterLevel, PersonGeneration } = require("@google/genai");
const vision = require("@google-cloud/vision");

// Reuses the same secret ai_marketing_orchestrator.js already calls Gemini
// with - one Gemini API key for the whole project, same as that function's
// own comment describes.
const geminiApiKey = defineSecret("GEMINI_API_KEY");

const visionClient = new vision.ImageAnnotatorClient();

// Imagen model for logo previews. Pinned to one exact string for the same
// reason GEMINI_MODEL is pinned in ai_marketing_orchestrator.js: model
// availability under this project's API key has moved before (see that
// file's own comment - gemini-1.5-flash 404s, gemini-2.5-flash rejected new
// callers) and a floating alias would let this feature silently break.
//
// UNVERIFIED against live traffic as of writing - this needs a real call
// against the deployed project's Gemini API key before this feature is
// exposed to any real visitor. If it 404s or is rejected, that error
// surfaces to the caller as "Could not generate logo previews right now"
// (see the catch block below) rather than crashing the whole page, but the
// feature will not work until this string is corrected to whatever model
// name this project's key actually has access to.
const IMAGEN_MODEL = "imagen-4.0-generate-001";

const MIN_BRIEF_LENGTH = 150;
const MAX_BRIEF_LENGTH = 3000;
const MAX_SHORT_FIELD_LENGTH = 200;
const IMAGES_PER_REQUEST = 2;

// --- Abuse prevention -------------------------------------------------
//
// This page is deliberately reachable with no account (see
// app_studio_page_widget.dart's own doc comment) - that's the whole point,
// most people who'd want a custom app are not already on KIN. Which means
// there is no uid to gate on, no Power Hour-style per-business quota to
// reuse, and no Firebase App Check configured in this project to block
// scripted callers outright. Three independent caps close that gap instead
// of one, because each is bypassable alone: per-email is beaten by typing a
// new email, per-IP is beaten by a VPN/rotating proxy, and neither alone
// bounds a distributed attacker. The global daily cap is the actual ceiling
// on worst-case spend regardless of how the other two are evaded.
const MAX_PER_IP_PER_DAY = 3;
const MAX_PER_EMAIL_PER_DAY = 3;
// Started at 30/day rather than a higher number - easy to raise once real
// usage patterns are known, much harder to walk back a number that's
// already been publicly relied on.
const MAX_GLOBAL_PER_DAY = 30;
const LIMITS_COLLECTION = "app_studio_logo_limits";
const WINDOW_MS = 24 * 60 * 60 * 1000;

function hash(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

function dayKey(nowMs) {
  return new Date(nowMs).toISOString().slice(0, 10); // YYYY-MM-DD, UTC
}

function callerIp(request) {
  const raw = request.rawRequest;
  if (!raw) return "unknown";
  // Cloud Functions v2 sits behind Google's front end, which sets this
  // correctly; x-forwarded-for is the fallback for the rare case it isn't
  // populated on request.ip directly. First entry is the original client.
  const forwarded = raw.headers && raw.headers["x-forwarded-for"];
  if (typeof forwarded === "string" && forwarded.length > 0) {
    return forwarded.split(",")[0].trim();
  }
  return raw.ip || "unknown";
}

// One doc per limit key (ip/email/global), each independently windowed.
// Reads and writes all three inside one transaction so a request either
// claims a slot against all three ceilings or none of them - there is no
// state where it holds an IP slot but not a global one.
async function reserveGenerationSlots(db, { ipKey, emailKey, nowMs }) {
  const globalKey = `global_${dayKey(nowMs)}`;
  const refs = {
    ip: db.collection(LIMITS_COLLECTION).doc(`ip_${ipKey}`),
    email: db.collection(LIMITS_COLLECTION).doc(`email_${emailKey}`),
    global: db.collection(LIMITS_COLLECTION).doc(globalKey),
  };

  return db.runTransaction(async (tx) => {
    const [ipSnap, emailSnap, globalSnap] = await Promise.all([
      tx.get(refs.ip),
      tx.get(refs.email),
      tx.get(refs.global),
    ]);

    const windowed = (snap, max) => {
      const data = snap.exists ? snap.data() : null;
      const stillInWindow =
        data && typeof data.window_start_ms === "number" &&
        nowMs - data.window_start_ms < WINDOW_MS;
      const count = stillInWindow && typeof data.count === "number" ? data.count : 0;
      const windowStart = stillInWindow ? data.window_start_ms : nowMs;
      return { count, windowStart, exceeded: count >= max };
    };

    const ipState = windowed(ipSnap, MAX_PER_IP_PER_DAY);
    const emailState = windowed(emailSnap, MAX_PER_EMAIL_PER_DAY);
    // Global cap resets by calendar day (its doc id already encodes the
    // day), so it has no rolling window to check - just a count.
    const globalData = globalSnap.exists ? globalSnap.data() : null;
    const globalCount = globalData && typeof globalData.count === "number" ? globalData.count : 0;

    if (ipState.exceeded) return { reserved: false, reason: "ip" };
    if (emailState.exceeded) return { reserved: false, reason: "email" };
    if (globalCount >= MAX_GLOBAL_PER_DAY) return { reserved: false, reason: "global" };

    tx.set(refs.ip, { count: ipState.count + 1, window_start_ms: ipState.windowStart }, { merge: true });
    tx.set(refs.email, { count: emailState.count + 1, window_start_ms: emailState.windowStart }, { merge: true });
    tx.set(refs.global, { count: globalCount + 1, day: dayKey(nowMs) }, { merge: true });

    return { reserved: true, refs };
  });
}

// Gives back the slot claimed above when the generation itself failed or
// every image came back filtered - the caller got nothing, so this attempt
// should not count against their daily allowance. Mirrors
// ai_marketing_orchestrator.js's refundGeneration for the same reason: our
// own failure should not be the visitor's cost.
async function refundGenerationSlots(db, refs) {
  if (!refs) return;
  try {
    await db.runTransaction(async (tx) => {
      for (const ref of Object.values(refs)) {
        const snap = await tx.get(ref);
        if (!snap.exists) continue;
        const count = typeof snap.data().count === "number" ? snap.data().count : 0;
        if (count <= 0) continue;
        tx.set(ref, { count: count - 1 }, { merge: true });
      }
    });
  } catch (_) {
    // Best-effort, same reasoning as the marketing generator's refund path:
    // the generation already failed and the client is about to be told so.
  }
}

function limitMessage(reason) {
  if (reason === "ip" || reason === "email") {
    return "You've reached today's limit for logo previews. Please try again "
      + "tomorrow, or send your request now and we'll follow up with options.";
  }
  return "Logo previews are in high demand right now. Please try again "
    + "later, or send your request now and we'll follow up with options.";
}

function validateInput(data) {
  const contactName = typeof data.contactName === "string" ? data.contactName.trim() : "";
  const contactEmail = typeof data.contactEmail === "string" ? data.contactEmail.trim() : "";
  const businessName = typeof data.businessName === "string" ? data.businessName.trim() : "";
  const style = typeof data.style === "string" ? data.style.trim() : "";
  const colorPreference = typeof data.colorPreference === "string" ? data.colorPreference.trim() : "";
  const brief = typeof data.brief === "string" ? data.brief.trim() : "";

  // Mirrors app_studio_page_widget.dart's own _submit() validation - a
  // direct function call that skips the form must still fail the same way
  // the form itself would have.
  if (!contactName) {
    throw new HttpsError("invalid-argument", "Your name is required.");
  }
  if (!contactEmail.includes("@") || contactEmail.length < 5) {
    throw new HttpsError("invalid-argument", "A valid email address is required.");
  }
  if (brief.length < MIN_BRIEF_LENGTH) {
    throw new HttpsError(
      "invalid-argument",
      `Please provide more detail in your project brief - at least ${MIN_BRIEF_LENGTH} characters.`,
    );
  }
  if (
    contactName.length > MAX_SHORT_FIELD_LENGTH ||
    contactEmail.length > MAX_SHORT_FIELD_LENGTH ||
    businessName.length > MAX_SHORT_FIELD_LENGTH ||
    style.length > MAX_SHORT_FIELD_LENGTH ||
    colorPreference.length > MAX_SHORT_FIELD_LENGTH
  ) {
    throw new HttpsError("invalid-argument", "One of the fields is too long.");
  }
  if (brief.length > MAX_BRIEF_LENGTH) {
    throw new HttpsError("invalid-argument", "Your project brief is too long.");
  }

  return { contactName, contactEmail, businessName, style, colorPreference, brief };
}

function buildPrompt({ businessName, style, colorPreference, brief }) {
  return [
    "Design a clean, professional logo icon for a small business.",
    businessName ? `Business name: ${businessName}` : null,
    style ? `Desired style: ${style}` : null,
    colorPreference ? `Preferred colors: ${colorPreference}` : null,
    `About the business, for context: ${brief.slice(0, 600)}`,
    "",
    "The logo should be simple, memorable, and work well at small sizes " +
      "(app icon, favicon). Flat vector style, centered on a plain white " +
      "background, no mockups, no text unless the business name is short " +
      "and clearly requested as part of the mark.",
  ]
    .filter(Boolean)
    .join("\n");
}

// Belt-and-suspenders on top of Imagen's own safetyFilterLevel: every image
// this project already lets users upload goes through the same
// safeSearchDetection check before it's servable (see
// moderate_image_upload.js) - generated images get no less scrutiny just
// because a model made them instead of a person.
async function isFlagged(imageBytesBuffer) {
  try {
    const [result] = await visionClient.safeSearchDetection({
      image: { content: imageBytesBuffer },
    });
    const safeSearch = result.safeSearchAnnotation || {};
    const veryLikelyOrLikely = (v) => v === "LIKELY" || v === "VERY_LIKELY";
    return (
      veryLikelyOrLikely(safeSearch.adult) ||
      veryLikelyOrLikely(safeSearch.violence) ||
      safeSearch.racy === "VERY_LIKELY"
    );
  } catch (_) {
    // A moderation-check failure must not accidentally let an unchecked
    // image through - treat it as flagged and drop it, the same
    // fail-closed choice as everywhere else images are checked in this app.
    return true;
  }
}

exports.generateAppStudioLogos = onCall(
  { secrets: [geminiApiKey], timeoutSeconds: 120, memory: "512MiB" },
  async (request) => {
    const nowMs = Date.now();
    const db = admin.firestore();

    const input = validateInput(request.data || {});
    const ipKey = hash(callerIp(request));
    const emailKey = hash(input.contactEmail.toLowerCase());

    const reservation = await reserveGenerationSlots(db, { ipKey, emailKey, nowMs });
    if (!reservation.reserved) {
      throw new HttpsError("resource-exhausted", limitMessage(reservation.reason));
    }

    let logoUrls = [];
    try {
      const genAI = new GoogleGenAI({ apiKey: geminiApiKey.value() });
      const prompt = buildPrompt(input);
      const response = await genAI.models.generateImages({
        model: IMAGEN_MODEL,
        prompt,
        config: {
          numberOfImages: IMAGES_PER_REQUEST,
          aspectRatio: "1:1",
          safetyFilterLevel: SafetyFilterLevel.BLOCK_LOW_AND_ABOVE,
          // A logo mark has no business depicting people - closing off an
          // entire class of prompt-injection attempt at generation time,
          // not just catching it after the fact in the Vision check below.
          personGeneration: PersonGeneration.DONT_ALLOW,
        },
      });

      const generated = response.generatedImages || [];
      if (generated.length === 0) {
        throw new Error("Model returned no images.");
      }

      const bucket = admin.storage().bucket();
      const requestId = db.collection(LIMITS_COLLECTION).doc().id;

      for (let i = 0; i < generated.length; i++) {
        const image = generated[i].image;
        if (!image || !image.imageBytes) continue;
        const bytes = Buffer.from(image.imageBytes, "base64");

        if (await isFlagged(bytes)) {
          continue;
        }

        const mimeType = image.mimeType || "image/png";
        const ext = mimeType === "image/jpeg" ? "jpg" : "png";
        const path = `app_studio_logos/${requestId}/${i}.${ext}`;
        const file = bucket.file(path);
        await file.save(bytes, { metadata: { contentType: mimeType } });
        await file.makePublic();
        logoUrls.push(`https://storage.googleapis.com/${bucket.name}/${path}`);
      }

      if (logoUrls.length === 0) {
        throw new Error("All generated images were filtered.");
      }
    } catch (e) {
      await refundGenerationSlots(db, reservation.refs);
      console.error("generateAppStudioLogos failed:", e && e.message ? e.message : e);
      throw new HttpsError(
        "internal",
        "Could not generate logo previews right now. Your request will still "
          + "be sent - we'll follow up with design options directly.",
      );
    }

    await db.collection("app_studio_logo_logs").add({
      contact_email: input.contactEmail,
      business_name: input.businessName || null,
      style: input.style || null,
      color_preference: input.colorPreference || null,
      image_count: logoUrls.length,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { logoUrls };
  },
);
