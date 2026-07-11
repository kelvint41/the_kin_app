const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const crypto = require("crypto");

const COLLECTION = "launch_subscribers";
const TOKEN_TTL_MS = 48 * 60 * 60 * 1000; // verification links live 48h
const MAX_EMAIL_LENGTH = 254; // RFC 5321 upper bound
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

// Brand tokens mirrored from lib/flutter_flow/flutter_flow_theme.dart so the
// confirmation page matches the app: primary (KIN Evergreen), accent1 (gold),
// and the light-mode canvas.
const BRAND = {
  evergreen: "#0B3D2E",
  gold: "#D4AF37",
  goldMuted: "#C5A059",
  canvas: "#FCFCFC",
  ink: "#14181B",
};

function normalizeEmail(raw) {
  return typeof raw === "string" ? raw.trim().toLowerCase() : "";
}

// The doc ID is the SHA-256 of the normalized email, so re-submitting the
// same address always lands on the same document (idempotent) and the raw
// address never appears in a document path.
function emailDocId(email) {
  return crypto.createHash("sha256").update(email).digest("hex");
}

function newToken() {
  return crypto.randomBytes(32).toString("hex");
}

function tokenExpiry() {
  return admin.firestore.Timestamp.fromMillis(Date.now() + TOKEN_TTL_MS);
}

function confirmUrl(subscriberId, token) {
  const project = process.env.GCLOUD_PROJECT || "kinvest-build-app";
  return (
    `https://us-central1-${project}.cloudfunctions.net/confirmLaunchSubscription` +
    `?id=${subscriberId}&token=${token}`
  );
}

// ---------------------------------------------------------------------------
// Verification email — placeholder.
//
// TODO(kelvin): replace the console.log below with the SendGrid/Mailgun send.
// Everything the provider needs is already passed in: the recipient and the
// one-click confirmation URL. If you later install the Firebase "Trigger
// Email" extension instead, swap the log for a write to its `mail`
// collection, e.g.
//   await admin.firestore().collection("mail").add({
//     to: email,
//     message: { subject: "Confirm your spot on the KIN launch list",
//                html: `... <a href="${url}">Confirm my email</a> ...` },
//   });
// ---------------------------------------------------------------------------
async function sendVerificationEmail(email, subscriberId, token) {
  const url = confirmUrl(subscriberId, token);
  console.log(
    `[launch_subscribers] verification email placeholder → to=${email} url=${url}`
  );
}

// Public callable behind the website's Notify-Me form. Unauthenticated by
// design (visitors have no account); all writes to launch_subscribers happen
// here via the Admin SDK, so Firestore rules can stay deny-all for clients.
exports.subscribeToLaunch = onCall(
  {
    // TODO(kelvin): once the site is live, tighten to the real origins:
    //   cors: ["https://www.kinvestguidance.com", "https://kinvestguidance.com"]
    cors: true,
    // TODO(kelvin): flip to true after registering the site with App Check
    // (reCAPTCHA Enterprise) — blocks calls that don't come from your pages.
    enforceAppCheck: false,
  },
  async (request) => {
    const email = normalizeEmail(request.data?.email);
    if (!email || email.length > MAX_EMAIL_LENGTH || !EMAIL_RE.test(email)) {
      throw new HttpsError(
        "invalid-argument",
        "Please enter a valid email address."
      );
    }

    const source =
      typeof request.data?.source === "string"
        ? request.data.source.slice(0, 40)
        : "web";

    const db = admin.firestore();
    const docRef = db.collection(COLLECTION).doc(emailDocId(email));

    // Transaction so two rapid submits of the same address can't race into
    // a double-create or clobber a confirmed subscription back to pending.
    const outcome = await db.runTransaction(async (tx) => {
      const snap = await tx.get(docRef);

      if (snap.exists) {
        const data = snap.data();
        if (data.status === "confirmed") {
          return { status: "already_subscribed" };
        }
        // Still pending: re-issue the token only if the old link expired,
        // so mashing the button doesn't invalidate an email already sent.
        const expired =
          !data.token_expires_at ||
          data.token_expires_at.toMillis() < Date.now();
        if (!expired) {
          return { status: "pending_verification" };
        }
        const token = newToken();
        tx.update(docRef, {
          verification_token: token,
          token_expires_at: tokenExpiry(),
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { status: "pending_verification", sendToken: token };
      }

      const token = newToken();
      tx.set(docRef, {
        email,
        status: "pending_verification",
        source,
        verification_token: token,
        token_expires_at: tokenExpiry(),
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      return { status: "pending_verification", sendToken: token };
    });

    if (outcome.sendToken) {
      await sendVerificationEmail(email, docRef.id, outcome.sendToken);
    }

    // Never echo the token back to the browser — it must only ever travel
    // through the recipient's inbox, or the double opt-in proves nothing.
    return { status: outcome.status };
  }
);

function brandedPage(title, body) {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>${title} · The KIN App</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;800&display=swap" rel="stylesheet">
<style>
  body { margin:0; min-height:100vh; display:grid; place-items:center;
         background:${BRAND.evergreen}; color:${BRAND.canvas};
         font-family:"Plus Jakarta Sans",system-ui,sans-serif; }
  main { max-width:420px; margin:24px; padding:32px;
         background:rgba(0,0,0,.25); border:1px solid rgba(212,175,55,.35);
         border-radius:24px; text-align:center; }
  h1 { color:${BRAND.gold}; font-weight:800; font-size:28px; margin:0 0 12px; }
  p  { color:${BRAND.goldMuted}; font-size:16px; line-height:1.5; margin:0; }
  .brand { display:block; margin-top:24px; color:${BRAND.gold};
           font-weight:600; font-size:14px; letter-spacing:.08em;
           text-transform:uppercase; }
</style>
</head>
<body><main><h1>${title}</h1><p>${body}</p>
<span class="brand">The KIN App · Kinvest Guidance LLC</span></main></body></html>`;
}

// Landing endpoint for the link inside the verification email. GET-only,
// renders a small branded page so the click never dead-ends on raw JSON.
exports.confirmLaunchSubscription = onRequest(async (req, res) => {
  const id = typeof req.query.id === "string" ? req.query.id : "";
  const token = typeof req.query.token === "string" ? req.query.token : "";

  const invalid = () =>
    res
      .status(400)
      .send(
        brandedPage(
          "Link expired or invalid",
          "This confirmation link is no longer valid. Head back to kinvestguidance.com and re-enter your email to get a fresh one."
        )
      );

  if (!/^[a-f0-9]{64}$/.test(id) || !/^[a-f0-9]{64}$/.test(token)) {
    return invalid();
  }

  const db = admin.firestore();
  const docRef = db.collection(COLLECTION).doc(id);

  const confirmed = await db.runTransaction(async (tx) => {
    const snap = await tx.get(docRef);
    if (!snap.exists) return false;
    const data = snap.data();

    if (data.status === "confirmed") return true; // idempotent re-click

    const tokenMatches =
      data.verification_token &&
      crypto.timingSafeEqual(
        Buffer.from(data.verification_token),
        Buffer.from(token)
      );
    const expired =
      !data.token_expires_at || data.token_expires_at.toMillis() < Date.now();
    if (data.status !== "pending_verification" || !tokenMatches || expired) {
      return false;
    }

    tx.update(docRef, {
      status: "confirmed",
      confirmed_at: admin.firestore.FieldValue.serverTimestamp(),
      verification_token: admin.firestore.FieldValue.delete(),
      token_expires_at: admin.firestore.FieldValue.delete(),
    });
    return true;
  });

  if (!confirmed) return invalid();

  return res
    .status(200)
    .send(
      brandedPage(
        "You're on the list",
        "Your email is confirmed. You'll get exactly one email the day The KIN App goes live on the App Store and Google Play."
      )
    );
});
