const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}
const { GoogleGenerativeAI, SchemaType } = require("@google/generative-ai");
const { FieldValue } = require("firebase-admin/firestore");
const { createNotification } = require("./notifications.js");

// Same secret ai_marketing_orchestrator.js defines - Cloud Functions secrets
// are looked up by name, so redeclaring it here rather than importing that
// module's binding keeps this feature independently deployable/testable.
const geminiApiKey = defineSecret("GEMINI_API_KEY");

// Pinned for the same reason as ai_marketing_orchestrator.js's GEMINI_MODEL:
// a stable model matters here too, since support_chat_logs.category is what
// getSupportChatStats aggregates on - a silent model swap could shift
// classification behavior without anything in the data explaining why.
const GEMINI_MODEL = "gemini-3.6-flash";

// What every reply gets classified into, so admin-side aggregation
// (getSupportChatStats) has a fixed, known set of buckets to count rather
// than free-text categories that would need de-duping by hand.
const CATEGORIES = ["question", "bug_report", "suggestion", "praise", "other"];

const RESPONSE_SCHEMA = {
  type: SchemaType.OBJECT,
  properties: {
    reply: {
      type: SchemaType.STRING,
      description: "A helpful, concise reply to the user's message, in a warm and direct support-agent voice. 1-4 sentences unless the question genuinely needs more.",
    },
    category: {
      type: SchemaType.STRING,
      enum: CATEGORIES,
      description: "The single best-fit category for what the user's message actually is.",
    },
    summary: {
      type: SchemaType.STRING,
      description: "A short (under 12 words) neutral paraphrase of what the user asked/said, for an admin skimming many of these later - not a restatement of your reply.",
    },
  },
  required: ["reply", "category", "summary"],
};

const SYSTEM_PROMPT = [
  // Always "The KIN App" - that is the product's name, matching
  // main.dart's app title, the Android manifest label and the store
  // listing. Replies that said just "KIN" read as a different product.
  "You are the in-app support assistant for The KIN App, an app that helps customers discover and check into Black-owned local businesses, and helps business owners manage their listing (Kindex score, The Exchange posts, KIN Quest check-ins, subscription tiers, AI marketing tools).",
  "Always call the product \"The KIN App\" - never shorten it to \"KIN\" on its own. Feature names keep their own names (KIN Quest, The Exchange, Kindex).",
  "Answer questions about how the app works using only what a reasonable support agent would know from the product description above - do not invent specific policies, prices, or features you aren't told about here.",
  "If the user is reporting a bug or problem, acknowledge it clearly and let them know it's been logged for the team - do not try to debug it yourself.",
  "If the user is offering a suggestion or idea, thank them genuinely and let them know it's been passed along - do not promise it will be built.",
  "Never ask for or reference passwords, payment details, or other sensitive personal information.",
  "Keep replies short, plain, and specific - no corporate filler.",
].join("\n");

function buildPrompt(message, history) {
  const historyText = (history || [])
    .slice(-6) // Recent context only - see the callable's history handling below for why this is capped.
    .map((turn) => `${turn.role === "user" ? "User" : "Assistant"}: ${turn.text}`)
    .join("\n");
  return [
    SYSTEM_PROMPT,
    "",
    historyText ? `Recent conversation:\n${historyText}` : null,
    "",
    `New message from the user: ${message}`,
  ]
    .filter((line) => line !== null)
    .join("\n");
}

/**
 * Sends one message in the in-app support chat and returns a reply.
 *
 * Every exchange is logged to `support_chat_logs` (message, reply, category,
 * summary) regardless of category - this is deliberately also the
 * suggestions/comments intake mechanism, not a separate form: a "suggestion"
 * is just a message the model classified that way, so it lands in the same
 * place a bug report or question does rather than in a second disconnected
 * system an admin has to check separately.
 */
exports.sendSupportChatMessage = onCall(
  { secrets: [geminiApiKey] },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }

    const { message, conversationId, history } = request.data || {};
    if (typeof message !== "string" || !message.trim()) {
      throw new HttpsError("invalid-argument", "message is required.");
    }
    const trimmedMessage = message.trim().slice(0, 2000);

    // history is client-supplied conversation context (this session's prior
    // turns), capped and only ever used to build the prompt - never trusted
    // for anything else. conversationId just threads related log rows
    // together; a missing one still logs fine as a standalone exchange.
    const boundedHistory = Array.isArray(history)
      ? history
          .filter((h) => h && typeof h.text === "string" && (h.role === "user" || h.role === "assistant"))
          .map((h) => ({ role: h.role, text: h.text.slice(0, 2000) }))
          .slice(-6)
      : [];

    const db = admin.firestore();
    const userRef = db.collection("users").doc(uid);

    let result;
    try {
      const genAI = new GoogleGenerativeAI(geminiApiKey.value());
      const model = genAI.getGenerativeModel({
        model: GEMINI_MODEL,
        generationConfig: {
          responseMimeType: "application/json",
          responseSchema: RESPONSE_SCHEMA,
        },
      });
      const response = await model.generateContent(
        buildPrompt(trimmedMessage, boundedHistory),
      );
      result = JSON.parse(response.response.text());
      if (!CATEGORIES.includes(result.category)) {
        result.category = "other";
      }
    } catch (e) {
      throw new HttpsError(
        "internal",
        "Could not get a response right now. Please try again.",
      );
    }

    const logRef = db.collection("support_chat_logs").doc();
    await logRef.set({
      user_ref: userRef,
      conversation_id: typeof conversationId === "string" ? conversationId.slice(0, 200) : null,
      message: trimmedMessage,
      reply: result.reply,
      category: result.category,
      summary: result.summary || null,
      model: GEMINI_MODEL,
      created_at: FieldValue.serverTimestamp(),
    });

    // Tell an admin something came in. Without this, support messages
    // landed in support_chat_logs and nobody knew unless they thought to
    // open the admin stats - a support inbox nobody is told about is a
    // support inbox nobody reads.
    //
    // Deliberately the cheapest mechanism available, and it adds no new
    // service: one small indexed query plus one Firestore write to the
    // `notifications` inbox the app already has (NotificationsWidget
    // renders it). No email provider, no FCM/push, no extra function
    // invocation - this runs inside the call that was already happening.
    // At Firestore's rates that is a rounding error, and it sits inside
    // the free daily write allowance at any volume this app will see
    // before there is revenue to pay for something better.
    //
    // Only questions and bug reports notify. `suggestion` and anything
    // else stay in the log for later review - a suggestion is not
    // something to interrupt anyone over, and notifying on everything is
    // how an inbox becomes noise that gets ignored.
    //
    // Wrapped so a notification failure can never cost the user their
    // reply: the support answer is already computed at this point.
    if (result.category === "question" || result.category === "bug_report") {
      try {
        const adminsSnap = await db
          .collection("users")
          .where("is_admin", "==", true)
          .limit(5)
          .get();
        await Promise.all(
          adminsSnap.docs.map((adminDoc) =>
            createNotification(db, {
              userRef: adminDoc.ref,
              type: "support_message",
              title: result.category === "bug_report"
                ? "New bug report in support"
                : "New support question",
              body: result.summary || trimmedMessage.slice(0, 140),
              // Must match ExecutiveDashboardWidget.routeName exactly
              // (underscore included) or the notification taps into nothing.
              routeName: "Executive_Dashboard",
            }),
          ),
        );
      } catch (err) {
        console.error("Support notification failed (reply still sent):", err);
      }
    }

    return {
      reply: result.reply,
      category: result.category,
      logId: logRef.id,
    };
  },
);

exports._internals = { CATEGORIES, buildPrompt };
