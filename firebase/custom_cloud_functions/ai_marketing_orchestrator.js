const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const { GoogleGenerativeAI, SchemaType } = require("@google/generative-ai");

// Server-side only - never shipped to the client, unlike the API key that
// used to be hardcoded in lib/backend/gemini/gemini.dart (now rotated).
// Set via: firebase functions:secrets:set GEMINI_API_KEY
const geminiApiKey = defineSecret("GEMINI_API_KEY");

// Tiers that qualify for AI Marketing Orchestrator access. Real
// subscription_tier values as written by merchant_pricing_suite_widget.dart's
// upgrade flow (see kin_services.dart's _powerHourLimitsByTier for the same
// convention) - not a generic "Premium" string, since no tier is actually
// named that in this app.
const ENTITLED_TIERS = new Set(["Pro Growth", "Elite Growth"]);

// Single source of truth: this is both the model called and the model
// recorded on every generation log. It used to be written out twice, so a
// model change silently made the logs claim a model that was never called -
// which matters here, because comparing output quality across models is
// exactly what those logs are for.
//
// Was gemini-1.5-flash, which now 404s ("not found for API version
// v1beta") - it has been retired. gemini-2.5-flash is not a usable
// fallback either: it returns "no longer available to new users" for this
// project's key. Pinned deliberately rather than using the floating
// gemini-flash-latest alias, so the model can't change under a feature
// whose whole purpose is a stable per-business learning signal.
const GEMINI_MODEL = "gemini-3.6-flash";

function isEntitled(subscriptionTier) {
  return ENTITLED_TIERS.has(subscriptionTier);
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
        model: GEMINI_MODEL,
        generationConfig: {
          responseMimeType: "application/json",
          responseSchema: RESPONSE_SCHEMA,
        },
      });
      const response = await model.generateContent(prompt);
      result = JSON.parse(response.response.text());

      // Only a missing or empty array is a real failure - there is nothing
      // to show the owner. Too many hashtags is not: the caption, CTA and
      // image concept are all still good, and discarding them over one
      // extra hashtag shows the owner a bare "INTERNAL" instead.
      //
      // This used to throw on anything other than exactly 3, calibrated
      // against gemini-1.5-flash. That model is retired, and gemini-3.6-flash
      // returned 5 in testing even though the prompt and schema both ask for
      // exactly 3 - so the strict check now fails open on a cosmetic
      // difference. Take the first 3 and keep the post.
      if (!Array.isArray(result.hashtags) || result.hashtags.length === 0) {
        throw new Error(`Model returned no hashtags (got ${JSON.stringify(result.hashtags)}).`);
      }
      result.hashtags = result.hashtags.slice(0, 3);
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
      // Only a success has content to store; on error `result` is undefined.
      generatedOutput: status === "success" ? result : null,
      // Snapshot of the business fields the prompt actually saw. Without
      // this, a stored caption can't be interpreted later - a weak caption
      // from a thin business description reads identically to a weak
      // caption from a good one, and the business doc will have been
      // edited by then.
      contextUsed: {
        business_name: business.business_name || null,
        category: business.category || null,
        description: business.description || null,
      },
    });

    if (status === "error") {
      throw new HttpsError("internal", "Could not generate content right now. Please try again.");
    }

    return { ...result, generationLogId: logRef.id, latencyMs };
  },
);

async function logCall(
  db,
  { businessRef, userRef, status, subscriptionTier, latencyMs, theme, error, generatedOutput, contextUsed },
) {
  const ref = db.collection("ai_generation_logs").doc();
  await ref.set({
    business_ref: businessRef,
    user_ref: userRef,
    status,
    subscription_tier: subscriptionTier || null,
    latency_ms: latencyMs,
    theme: theme || null,
    error: error || null,
    // The content itself, not just whether generating it worked. This is
    // the only record of what was suggested - the client copies the
    // caption to the clipboard and keeps nothing. Without it, the
    // engagement subcollection says a suggestion was dismissed but never
    // what was dismissed, which is unusable as a learning signal and
    // can't be reconstructed after the fact.
    //
    // Fields are listed explicitly rather than spreading the model's
    // response: Firestore rejects `undefined`, and a schema change or a
    // malformed response shouldn't be able to write arbitrary keys here.
    generated_output: generatedOutput
      ? {
          caption: generatedOutput.caption ?? null,
          hashtags: generatedOutput.hashtags ?? null,
          cta: generatedOutput.cta ?? null,
          image_concept: generatedOutput.image_concept ?? null,
        }
      : null,
    context_used: contextUsed || null,
    model: GEMINI_MODEL,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });
  return ref;
}

// Called by the client when the owner acts on a suggestion (uses it as
// written, uses it after rewriting the caption, regenerates, or dismisses
// it) - separate from generation itself, so "was this content actually
// useful" can be measured independently of "did generation succeed".
//
// `edited` is deliberately distinct from `used`: both mean the owner
// posted something, but only `edited` says the model didn't get there on
// its own, and it arrives with the text the owner preferred.
exports.logAiSuggestionEngagement = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const { generationLogId, action, finalCaption } = request.data || {};
  const validActions = new Set(["used", "edited", "regenerated", "dismissed"]);
  if (!generationLogId || !validActions.has(action)) {
    throw new HttpsError("invalid-argument", "generationLogId and a valid action are required.");
  }

  // Bounded and type-checked: this is client-supplied text, and the
  // caption field it comes from has no length limit of its own.
  const editedCaption =
    action === "edited" && typeof finalCaption === "string" ? finalCaption.slice(0, 5000) : null;

  const db = admin.firestore();
  await db.collection("ai_generation_logs").doc(generationLogId).collection("engagement").add({
    user_ref: db.doc(`users/${request.auth.uid}`),
    action,
    // The generated original lives on the parent doc's `generated_output`,
    // so the diff is derivable from the pair at analysis time. Storing the
    // final text rather than a precomputed diff keeps the raw signal - any
    // diff format chosen now would be the wrong one later.
    final_caption: editedCaption,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { ok: true };
});
