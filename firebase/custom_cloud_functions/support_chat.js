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
    needsHuman: {
      type: SchemaType.BOOLEAN,
      description: "True if you were not able to actually answer this - the question is outside everything you were told about the app, you're genuinely unsure, or the user is expressing frustration / repeating a question your prior reply didn't resolve. False for anything you could answer with real confidence, including bug reports and suggestions (those are working as intended when logged, not a failure to answer).",
    },
  },
  required: ["reply", "category", "summary", "needsHuman"],
};

const SYSTEM_PROMPT = [
  // Always "The KIN App" - that is the product's name, matching
  // main.dart's app title, the Android manifest label and the store
  // listing. Replies that said just "KIN" read as a different product.
  "You are the in-app support assistant for The KIN App, an app that helps customers discover and check into Black-owned local businesses, and helps business owners manage their listing.",
  "Always call the product \"The KIN App\" - never shorten it to \"KIN\" on its own. Feature names keep their own names (KIN Quest, The Exchange, Kindex, Marketplace, App Studio, Power Hour, Location Beacon).",
  "What you know about how the app actually works - answer confidently from this, and only this:",
  "- Discovery: customers browse Black-owned businesses on a map or list, search by name, and filter (Near Me, Restaurants, Food Trucks, etc).",
  "- KIN Quest: a gamified discovery mode. Checking in at a business requires being physically there (GPS-verified) and awards points; some businesses are Rare or Hidden Gem tiers worth more points. Discovering enough businesses unlocks mystery rewards at milestones.",
  "- Kindex Score: The KIN App's own reputation score, for both customers and businesses. It moves based on real engagement (reviews, check-ins, posts) and recalculates nightly, not instantly.",
  "- The Exchange: a community feed where verified business owners post updates; customers react with one of five quick reactions.",
  "- Marketplace: businesses list items for sale or trade. Customers can browse and react, but there is no in-app checkout yet - tapping an item goes to that business's profile to contact them directly.",
  "- A business's profile page has direct contact buttons (call, directions, website, email where provided), hours, photos, and a description.",
  "- Claiming a business: if a business is already listed but nobody has claimed it, the owner submits a Claim Business request with proof of ownership, which a KIN team member reviews manually - it is not instant. A brand-new business not yet listed at all can instead self-register through Business Setup and goes live immediately without waiting on review.",
  "- Editing a business profile: from Owner Profile, tap the hamburger menu (top right) and choose \"Edit Business Profile.\"",
  "- Subscription tiers, lowest to highest: Community (free), Founder, Founding Local, Premium Local, Elite. Higher tiers unlock more, including Kindex trend analytics (Premium Local and up), priority placement, and Power Hour. A free trial of Founding Local is available to businesses that haven't used it yet.",
  "- Power Hour and Location Beacon (for mobile/food-truck vendors, to broadcast where they currently are): from Owner Profile, tap the \"Growth Tools\" card, then \"Active Promotion.\"",
  "- App Studio: businesses can submit a brief to have a custom app and marketing materials built for them. This is a real, actively-developing capability, not vaporware, but it is not yet an instant, self-serve builder - say plainly that they submit their business details and the team follows up. To get there: from Owner Profile, tap the \"Growth Tools\" card, then \"Need an app for your business?\" near the bottom.",
  "- Promoting a business (sharing it) and managing listings (items/jobs/events, including job applicant messages): both live on the same \"Growth Tools\" card on Owner Profile as Power Hour and App Studio above.",
  "- AI marketing tools: AI-assisted marketing content generation for a business's own promotion.",
  "- Community Events and the Job Board: businesses can post events and job openings; customers can browse both.",
  "- Getting more help than you can give: there's a floating support button (the same headset icon you're in now) on Owner Profile, Business Insights, and Growth Tools, always one tap away without needing the hamburger menu.",
  "- Deleting an account is available from the account menu, and is permanent.",
  "Whenever you mention a specific feature or screen, also say how to get there in the app (which page, which button or menu) using the paths above - don't just confirm a feature exists without saying where to find it.",
  "Do not invent specific policies, prices, exact dollar amounts, navigation paths, or any feature not described above. If a question falls genuinely outside this list, say you're not sure and that it's been flagged for the team - do not guess.",
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

    const { message, conversationId, history, visitorName } = request.data || {};
    if (typeof message !== "string" || !message.trim()) {
      throw new HttpsError("invalid-argument", "message is required.");
    }
    const trimmedMessage = message.trim().slice(0, 2000);
    // Client-captured at the start of the conversation (see
    // support_chat_widget.dart) rather than pulled from the user's profile
    // display name, which is frequently empty - this is what actually
    // gives an admin a name to show against a conversation instead of
    // just a uid. Denormalized onto every row rather than only the first,
    // so the admin dashboard can show it without joining back through
    // conversation_id.
    const trimmedVisitorName =
      typeof visitorName === "string" && visitorName.trim()
        ? visitorName.trim().slice(0, 100)
        : null;

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
      result.needsHuman = result.needsHuman === true;
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
      visitor_name: trimmedVisitorName,
      message: trimmedMessage,
      reply: result.reply,
      category: result.category,
      summary: result.summary || null,
      needs_human: result.needsHuman,
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
    // Questions and bug reports notify as routine inbox items. needsHuman
    // notifies regardless of category - it's the bot itself flagging that
    // it couldn't actually help, which is a different signal from "a
    // question came in" and reads with different urgency in the title
    // below. `suggestion`/`praise` with needsHuman false stay in the log
    // for later review - notifying on everything is how an inbox becomes
    // noise that gets ignored.
    //
    // Wrapped so a notification failure can never cost the user their
    // reply: the support answer is already computed at this point.
    if (result.category === "question" || result.category === "bug_report" || result.needsHuman) {
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
              title: result.needsHuman
                ? "Support chat needs you"
                : result.category === "bug_report"
                ? "New bug report in support"
                : "New support question",
              body: trimmedVisitorName
                ? `${trimmedVisitorName}: ${result.summary || trimmedMessage.slice(0, 140)}`
                : result.summary || trimmedMessage.slice(0, 140),
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
