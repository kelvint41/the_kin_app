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

// Monthly generation caps per tier. Before this existed, an entitled
// business had unlimited Gemini calls: the `marketing_generations_used`
// field had been on the businesses schema all along but nothing ever read
// or wrote it, so one owner holding down Regenerate was unmetered spend
// against a thinking model (~4x more thought tokens than output tokens).
//
// Elite Growth gets a high-but-finite cap rather than the `null` (truly
// unlimited) that _powerHourLimitsByTier gives its top tier. Power Hour
// unlimited costs nothing per use; this does. 150/month is far above any
// plausible real usage - roughly five posts a day, every day - so it
// behaves as unlimited for an honest owner while still bounding a runaway
// loop or a compromised account.
//
// Overridable per-deployment from Firestore (see readLimits) so these can
// be retuned without a redeploy, the same reasoning as
// kindex_config/scoring_dynamics.
const DEFAULT_MONTHLY_LIMITS = {
  "Pro Growth": 30,
  "Elite Growth": 150,
};
const LIMITS_CONFIG_DOC = { collection: "ai_config", doc: "generation_limits" };

// Deliberately uncached, unlike getScoringDynamics' 5-minute cache. That
// job touches every business in one run; this is one read on a
// user-initiated action, so a stale cap is a worse trade than the read.
async function readLimits(db) {
  try {
    const snap = await db.collection(LIMITS_CONFIG_DOC.collection).doc(LIMITS_CONFIG_DOC.doc).get();
    const data = snap.exists ? snap.data() : null;
    if (!data || typeof data !== "object") return DEFAULT_MONTHLY_LIMITS;
    const merged = { ...DEFAULT_MONTHLY_LIMITS };
    for (const tier of Object.keys(DEFAULT_MONTHLY_LIMITS)) {
      const v = data[tier];
      // null is meaningful here - it means "no cap for this tier" - so it
      // has to survive, while junk values fall back to the default.
      if (v === null || (typeof v === "number" && Number.isFinite(v) && v >= 0)) {
        merged[tier] = v;
      }
    }
    return merged;
  } catch (_) {
    // A missing or unreadable config must not take the feature down; the
    // code defaults are the safe answer.
    return DEFAULT_MONTHLY_LIMITS;
  }
}

// "YYYY-MM" in the same timezone the nightly Kindex jobs use, so a
// "monthly" quota rolls over when the owner's month does rather than at
// UTC midnight mid-evening. Built from formatToParts rather than a locale
// string so the format can't drift with the runtime's ICU data.
function monthKey(ms) {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: "America/Chicago",
    year: "numeric",
    month: "2-digit",
  }).formatToParts(new Date(ms));
  const year = parts.find((p) => p.type === "year").value;
  const month = parts.find((p) => p.type === "month").value;
  return `${year}-${month}`;
}

// Claims one generation against this month's allowance, atomically.
//
// Reserves *before* the Gemini call rather than counting after it. Counting
// after would leave a race in which two concurrent taps both pass the check
// and both spend, which defeats the point of having a cap. The cost of
// reserving up front is that a generation which then fails has to be
// refunded - see refundGeneration - but a refund is a cheap write on a rare
// path, whereas an unmetered spend is the thing being prevented.
async function reserveGeneration(db, businessRef, tier, nowMs, limits) {
  const limit = Object.prototype.hasOwnProperty.call(limits, tier)
    ? limits[tier]
    : DEFAULT_MONTHLY_LIMITS[tier];
  if (limit === null || limit === undefined) {
    return { reserved: true, limit: null, used: null };
  }
  const key = monthKey(nowMs);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(businessRef);
    const data = snap.data() || {};
    // A stored month that isn't this one means the previous month's tally
    // is stale - treat it as zero instead of carrying it forward. This is
    // why the month is stored alongside the count: without it there is no
    // way to tell "0 used this month" from "never reset".
    const sameMonth = data.marketing_generations_month === key;
    const used = sameMonth && typeof data.marketing_generations_used === "number"
      ? data.marketing_generations_used
      : 0;
    if (used >= limit) {
      return { reserved: false, limit, used };
    }
    tx.set(
      businessRef,
      { marketing_generations_month: key, marketing_generations_used: used + 1 },
      { merge: true },
    );
    return { reserved: true, limit, used: used + 1 };
  });
}

// Gives the reservation back when the generation failed, so our own outage
// doesn't eat the owner's allowance. Best-effort and guarded on the month
// still matching: if the clock has since rolled over, the counter it would
// decrement belongs to a different month and must be left alone.
async function refundGeneration(db, businessRef, nowMs) {
  try {
    const key = monthKey(nowMs);
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(businessRef);
      const data = snap.data() || {};
      if (data.marketing_generations_month !== key) return;
      const used = typeof data.marketing_generations_used === "number"
        ? data.marketing_generations_used
        : 0;
      if (used <= 0) return;
      tx.set(businessRef, { marketing_generations_used: used - 1 }, { merge: true });
    });
  } catch (_) {
    // Swallowed deliberately: the generation already failed and the client
    // is about to be told so. Turning a refund failure into a second error
    // would replace a clear message with a confusing one.
  }
}

function quotaMessage(tier, limit) {
  if (tier === "Pro Growth") {
    return `You've used all ${limit} AI marketing generations for this month on Pro Growth. `
      + "Upgrade to Elite Growth for more, or try again next month.";
  }
  return `You've used all ${limit} AI marketing generations for this month. `
    + "They reset at the start of next month.";
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
      // Bounds, not just a description. The description alone asked for
      // exactly 3 and gemini-3.6-flash ignored it: the first two real
      // in-app generations each came back with a single hashtag, and an A/B
      // run over the actual prompt gave [1, 3, 3] unbounded versus
      // [3, 3, 3] with these two lines. A one-hashtag post is materially
      // weaker for the owner, so the count is now enforced by the schema
      // rather than requested politely in prose.
      minItems: 3,
      maxItems: 3,
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

// Bump whenever buildPrompt's wording changes. Stored on every generation
// log next to the composed prompt, so a later analysis can tell "this
// business prefers shorter captions" apart from "we reworded the prompt and
// the output changed" - two explanations that are indistinguishable if all
// you have is the output.
const PROMPT_VERSION = 1;

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

    // Quota is claimed after entitlement and before the model call, so an
    // exhausted allowance costs nothing. Rejections are logged the same way
    // not-entitled ones are, so hitting the cap is visible in the data
    // rather than looking like silence.
    const limits = await readLimits(db);
    const quota = await reserveGeneration(
      db,
      businessSnap.ref,
      business.subscription_tier,
      startedAt,
      limits,
    );
    if (!quota.reserved) {
      await logCall(db, {
        businessRef: businessSnap.ref,
        userRef: db.doc(`users/${request.auth.uid}`),
        status: "rejected_quota_exceeded",
        subscriptionTier: business.subscription_tier,
        latencyMs: Date.now() - startedAt,
        theme,
        generationsUsed: quota.used,
        generationsLimit: quota.limit,
      });
      throw new HttpsError(
        "resource-exhausted",
        quotaMessage(business.subscription_tier, quota.limit),
      );
    }

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
      //
      // RESPONSE_SCHEMA now pins minItems/maxItems to 3, so the slice should
      // be a no-op in practice. It stays as a backstop: the bound is enforced
      // by the API, not by us, and a future schema or config change
      // shouldn't be able to leak a 10-hashtag caption to an owner.
      if (!Array.isArray(result.hashtags) || result.hashtags.length === 0) {
        throw new Error(`Model returned no hashtags (got ${JSON.stringify(result.hashtags)}).`);
      }
      result.hashtags = result.hashtags.slice(0, 3);
    } catch (e) {
      status = "error";
      errorMessage = String(e && e.message ? e.message : e);
      // The reservation was claimed before the call; give it back, since
      // this failure is ours and not something the owner should pay for out
      // of their monthly allowance.
      await refundGeneration(db, businessSnap.ref, startedAt);
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
      prompt,
      generationsUsed: quota.used,
      generationsLimit: quota.limit,
    });

    if (status === "error") {
      throw new HttpsError("internal", "Could not generate content right now. Please try again.");
    }

    return { ...result, generationLogId: logRef.id, latencyMs };
  },
);

async function logCall(
  db,
  {
    businessRef,
    userRef,
    status,
    subscriptionTier,
    latencyMs,
    theme,
    error,
    generatedOutput,
    contextUsed,
    prompt,
    generationsUsed,
    generationsLimit,
  },
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
    // The exact string sent to the model, not just the inputs it was built
    // from. buildPrompt is deterministic, so a prompt was technically
    // reconstructible from theme + context_used - but only for as long as
    // buildPrompt itself never changed. The moment the template is reworded,
    // every older log becomes unreplayable, and "this business prefers
    // shorter captions" stops being distinguishable from "we changed the
    // instructions". Null on a rejection, where no prompt was composed.
    prompt: prompt || null,
    prompt_version: prompt ? PROMPT_VERSION : null,
    model: GEMINI_MODEL,
    // Quota state at the moment of the call: what this generation consumed
    // and what the ceiling was. Recorded on rejections too, so hitting the
    // cap is visible as data instead of looking like the owner stopped
    // using the feature. Null limit means the tier is uncapped.
    generations_used: typeof generationsUsed === "number" ? generationsUsed : null,
    generations_limit: typeof generationsLimit === "number" ? generationsLimit : null,
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
