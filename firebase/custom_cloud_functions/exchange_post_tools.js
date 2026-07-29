const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { GoogleGenerativeAI } = require("@google/generative-ai");

// Same secret binding as ai_marketing_orchestrator.js - one Gemini key for
// the whole app, set via: firebase functions:secrets:set GEMINI_API_KEY
const geminiApiKey = defineSecret("GEMINI_API_KEY");
const GEMINI_MODEL = "gemini-3.6-flash";

const MAX_POST_LENGTH = 2000;

/**
 * Optional, opt-in cleanup for an Exchange post's grammar/spelling/clarity.
 * Called from the post composer/editor's "Clean up with AI" button - never
 * automatically, and the caller decides whether to use the result.
 *
 * Deliberately a separate, lighter-weight function from
 * generateMarketingContent: this has no business/tier/quota concept (any
 * signed-in KIN member can post to The Exchange, not just business owners),
 * no JSON schema response, and no generation log - it's a plain text-in,
 * text-out utility.
 */
exports.cleanUpPostText = onCall({ secrets: [geminiApiKey] }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const postText = request.data && request.data.postText;
  if (typeof postText !== "string" || !postText.trim()) {
    throw new HttpsError("invalid-argument", "postText is required.");
  }
  if (postText.length > MAX_POST_LENGTH) {
    throw new HttpsError(
      "invalid-argument",
      `postText must be ${MAX_POST_LENGTH} characters or fewer.`,
    );
  }

  const prompt = [
    "You are cleaning up a short social post for a community app.",
    "Fix grammar, spelling, and punctuation. Keep the author's own voice, tone,",
    "meaning, and length - this is a light copy-edit, not a rewrite.",
    "Do not add hashtags, emojis, or commentary. Return only the corrected post text,",
    "with no quotes or preamble around it.",
    "",
    "Post:",
    postText,
  ].join("\n");

  try {
    const genAI = new GoogleGenerativeAI(geminiApiKey.value());
    const model = genAI.getGenerativeModel({
      model: GEMINI_MODEL,
      generationConfig: { responseMimeType: "text/plain" },
    });
    const response = await model.generateContent(prompt);
    const cleanedText = response.response.text().trim();
    if (!cleanedText) {
      throw new Error("Model returned an empty response.");
    }
    return { cleanedText };
  } catch (e) {
    throw new HttpsError(
      "internal",
      "Could not clean up this post right now. Please try again.",
    );
  }
});
