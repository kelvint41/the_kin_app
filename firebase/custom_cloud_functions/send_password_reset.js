const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret, defineString } = require("firebase-functions/params");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}
const postmark = require("postmark");

// Set via: firebase functions:secrets:set POSTMARK_SERVER_TOKEN
const postmarkServerToken = defineSecret("POSTMARK_SERVER_TOKEN");

// Must be a Sender Signature (or address on a verified domain) in the
// Postmark account tied to postmarkServerToken, or sends will fail.
const senderEmail = defineString("PASSWORD_RESET_SENDER_EMAIL", {
  default: "noreply@kinvestguidance.com",
});

function buildEmail(resetLink) {
  const text =
    `We received a request to reset the password for your KIN account.\n\n` +
    `Reset your password: ${resetLink}\n\n` +
    `If you didn't request this, you can safely ignore this email - ` +
    `your password will not be changed.`;
  const html =
    `<p>We received a request to reset the password for your KIN account.</p>` +
    `<p><a href="${resetLink}">Reset your password</a></p>` +
    `<p>If you didn't request this, you can safely ignore this email - ` +
    `your password will not be changed.</p>`;
  return { text, html };
}

/**
 * Replaces the client's direct FirebaseAuth.sendPasswordResetEmail call
 * (Firebase's default sender is unauthenticated and gets spam-filtered by
 * most providers). Generates the reset link server-side via Admin SDK and
 * delivers it through Postmark instead.
 *
 * Always resolves the same way regardless of whether `email` belongs to a
 * real account, so this can't be used to enumerate registered emails - the
 * client shows the same "check your email" message either way.
 */
exports.sendPasswordReset = onCall(
  { secrets: [postmarkServerToken] },
  async (request) => {
    const email = request.data && request.data.email;
    if (typeof email !== "string" || !email.includes("@")) {
      throw new HttpsError("invalid-argument", "A valid email is required.");
    }

    try {
      const resetLink = await admin.auth().generatePasswordResetLink(email);
      const client = new postmark.ServerClient(postmarkServerToken.value());
      const { text, html } = buildEmail(resetLink);
      await client.sendEmail({
        From: senderEmail.value(),
        To: email,
        Subject: "Reset your KIN password",
        TextBody: text,
        HtmlBody: html,
        MessageStream: "outbound",
      });
    } catch (e) {
      if (e.code === "auth/user-not-found") {
        console.log("sendPasswordReset: no account for this email - not sending, not erroring.");
      } else {
        console.error("sendPasswordReset failed:", e);
        throw new HttpsError("internal", "Could not send reset email.");
      }
    }

    return { sent: true };
  },
);
