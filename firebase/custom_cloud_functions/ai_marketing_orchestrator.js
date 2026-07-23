const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const { GoogleGenerativeAI, SchemaType } = require("@google/generative-ai");

// Server-side only - never shipped to the client, unlike the API key that
// used to be hardcoded in lib/backend/gemini/gemini.dart (now rotated).
// Set via: firebase functions:secrets:set GEMINI_API_KEY
const geminiApiKey = defineSecret("GEMINI_API_KEY");

// Which tiers qualify for AI Marketing Orchestrator access is defined in
// the shared tier_config table (aiMarketingEntitled), the single source of
// truth for all per-tier server decisions. Today that's Pro Growth and
// Elite Growth - there's no generic "Premium" string, since no tier is
// actually named that in this app.
const { isAiMarketingEntitled } = require("./tier_config.js");

function isEntitled(subscriptionTier) {
  return isAiMarketingEntitled(subscriptionTier);
}

const RESPONSE_SCHEMA = {
  type: SchemaType.OBJECT,
  properties: {
    caption: {
      type: SchemaType.STRING,
      description: "A catchy, high-converting social media caption, 1-3 sentences, in the business's voice.",
    },
    hashtags: {
      type: SchemaType.ARRAY,
      items: { type: SchemaType.STRING },
      description: "Exactly 3 relevant hashtags, each starting with #, no spaces.",
    },
    cta: {
      type: SchemaType.STRING,
      description: "A strong, specific call to action (e.g. 'Order now', 'Book your table', 'Stop by before 6pm').",
    },
    image_concept: {
      type: SchemaType.STRING,
      description: "A concrete visual/photo concept for the post - composition, subject, mood - not a caption restatement.",
    },
  },
  required: ["caption", "hashtags", "cta", "image_concept"],
};

function buildPrompt({ businessName, category, description, theme }) {
  return [
    "You are a social media marketing strategist for independent, black-owned local businesses.",
    `Business name: ${businessName || "the business"}`,
    category ? `Category: ${category}` : null,
    description ? `About the business: ${description}` : null,
    theme
      ? `Write for this specific post idea/theme: ${theme}`
      : "Write a general promotional post that would work well today.",
    "",
    "Generate ONE high-converting social media post concept for this business.",
    "The caption should sound like a real small-business owner, not a corporate ad - warm, specific, no generic filler like 'Check us out!'.",
    "The 3 hashtags must be genuinely relevant to this business and category, not generic ones like #smallbusiness repeated everywhere.",
    "The CTA must be concrete and actionable, not vague.",
    "The image concept must be something the owner could realistically photograph themselves, not a professional studio shoot.",
  ]
    .filter(Boolean)
    .join("\n");
}

exports.generateMarketingContent = onCall(
  { secrets: [geminiApiKey] },
  async (request) => {
    const startedAt = Date.now();
    const db = admin.firestore();

    // Firebase callable functions verify the caller's ID token before this
    // handler ever runs - request.auth is trustworthy, unlike anything the
    // client body claims.
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }

    const businessRefPath = request.data && request.data.businessRefPath;
    if (!businessRefPath || typeof businessRefPath !== "string") {
      throw new HttpsError("invalid-argument", "businessRefPath is required.");
    }

    const businessSnap = await db.doc(businessRefPath).get();
    if (!businessSnap.exists) {
      throw new HttpsError("not-found", "Business not found.");
    }
    const business = businessSnap.data();

    // Authorization: only the business's own owner can generate content
    // for it - entitlement alone isn't enough, this also blocks any
    // signed-in user from generating content for a business they don't own.
    const ownerPath = business.owner_ref && business.owner_ref.path;
    if (ownerPath !== `users/${request.auth.uid}`) {
      throw new HttpsError(
        "permission-denied",
        "You can only generate marketing content for your own business.",
      );
    }

    // Entitlement check happens here, server-side, before the AI is ever
    // invoked - the app only triggers the Gemini call if this returns
    // true. The client never sees or controls this decision.
    const entitled = isEntitled(business.subscription_tier);
    if (!entitled) {
      await logCall(db, {
        businessRef: businessSnap.ref,
        userRef: db.doc(`users/${request.auth.uid}`),
        status: "rejected_not_entitled",
        subscriptionTier: business.subscription_tier || null,
        latencyMs: Date.now() - startedAt,
      });
      throw new HttpsError(
        "permission-denied",
        "AI Marketing Orchestrator requires Pro Growth or Elite Growth. Upgrade to unlock.",
      );
    }

    const theme = typeof request.data.theme === "string" ? request.data.theme.slice(0, 500) : null;
    const prompt = buildPrompt({
      businessName: business.business_name,
      category: business.category,
      description: business.description,
      theme,
    });

    let result;
    let status = "success";
    let errorMessage = null;
    try {
      const genAI = new GoogleGenerativeAI(geminiApiKey.value());
      const model = genAI.getGenerativeModel({
        model: "gemini-1.5-flash",
        generationConfig: {
          responseMimeType: "application/json",
          responseSchema: RESPONSE_SCHEMA,
        },
      });
      const response = await model.generateContent(prompt);
      result = JSON.parse(response.response.text());

      if (!Array.isArray(result.hashtags) || result.hashtags.length !== 3) {
        throw new Error(`Model returned ${result.hashtags?.length ?? 0} hashtags, expected 3.`);
      }
    } catch (e) {
      status = "error";
      errorMessage = String(e && e.message ? e.message : e);
    }

    const latencyMs = Date.now() - startedAt;
    const logRef = await logCall(db, {
      businessRef: businessSnap.ref,
      userRef: db.doc(`users/${request.auth.uid}`),
      status,
      subscriptionTier: business.subscription_tier,
      latencyMs,
      theme,
      error: errorMessage,
    });

    if (status === "error") {
      throw new HttpsError("internal", "Could not generate content right now. Please try again.");
    }

    return { ...result, generationLogId: logRef.id, latencyMs };
  },
);

async function logCall(db, { businessRef, userRef, status, subscriptionTier, latencyMs, theme, error }) {
  const ref = db.collection("ai_generation_logs").doc();
  await ref.set({
    business_ref: businessRef,
    user_ref: userRef,
    status,
    subscription_tier: subscriptionTier || null,
    latency_ms: latencyMs,
    theme: theme || null,
    error: error || null,
    model: "gemini-1.5-flash",
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });
  return ref;
}

// Called by the client when the owner acts on a suggestion (uses it,
// regenerates, or dismisses it) - separate from generation itself, so
// "was this content actually useful" can be measured independently of
// "did generation succeed".
exports.logAiSuggestionEngagement = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const { generationLogId, action } = request.data || {};
  const validActions = new Set(["used", "regenerated", "dismissed"]);
  if (!generationLogId || !validActions.has(action)) {
    throw new HttpsError("invalid-argument", "generationLogId and a valid action are required.");
  }

  const db = admin.firestore();
  await db.collection("ai_generation_logs").doc(generationLogId).collection("engagement").add({
    user_ref: db.doc(`users/${request.auth.uid}`),
    action,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { ok: true };
});
