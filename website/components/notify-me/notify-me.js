/* KIN Notify-Me — framework-free component.
 *
 * Usage in any static shell:
 *   <link rel="stylesheet" href="notify-me.css">
 *   <div id="notify-hero"></div>
 *   <script type="module">
 *     import { initNotifyMe } from "./notify-me.js";
 *     initNotifyMe(document.getElementById("notify-hero"), { source: "web_hero" });
 *   </script>
 *
 * Calls the `subscribeToLaunch` callable over its plain HTTPS protocol
 * (POST {"data": {...}} → {"result": {...}}), so the page ships zero
 * Firebase SDK bytes.
 */

const FIREBASE_PROJECT_ID = "kinvest-build-app";
const FUNCTIONS_REGION = "us-central1";
const SUBSCRIBE_URL =
  `https://${FUNCTIONS_REGION}-${FIREBASE_PROJECT_ID}.cloudfunctions.net/subscribeToLaunch`;

// Master Branding Library (assets/KIN_Logo_Assets — see CLAUDE.md).
// Default base is relative to this component's folder
// (website/components/notify-me/ → repo root → assets/); override via
// options.assetBase when the shell serves assets from another root.
const DEFAULT_ASSET_BASE = "../../../assets/KIN_Logo_Assets";
const LOGO_BY_SURFACE = {
  // Gold wordmark for dark/Evergreen surfaces, dark wordmark for light —
  // per the selection matrix in CLAUDE.md.
  dark: "10_website_header/header_logo_lockup_gold_text.png",
  light: "10_website_header/header_logo_lockup_dark_text.png",
};
// Source PNGs are 1558×286 (aspect preserved by the CSS render width).
const LOGO_WIDTH = 1558;
const LOGO_HEIGHT = 286;

const COPY = {
  hint: "One email at launch. No spam. Unsubscribe anytime.",
  placeholder: "you@example.com",
  button: "Notify Me",
  successNewTitle: "Check your inbox",
  successNewBody:
    "We sent a confirmation link. Click it and you're locked in for launch day.",
  successExistingTitle: "You're already on the list",
  successExistingBody:
    "This email is confirmed for launch day — nothing else to do.",
  errorInvalid: "Please enter a valid email address.",
  errorNetwork: "Something went wrong on our end. Please try again in a moment.",
};

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

async function callSubscribeToLaunch(email, source) {
  const res = await fetch(SUBSCRIBE_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ data: { email, source } }),
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok || body.error) {
    const err = new Error(body.error?.message || COPY.errorNetwork);
    err.code = body.error?.status;
    throw err;
  }
  return body.result || {};
}

export function initNotifyMe(container, options = {}) {
  const source = options.source || "web";
  const surface = options.surface || "dark"; // "dark" | "light"
  const assetBase = (options.assetBase || DEFAULT_ASSET_BASE).replace(/\/$/, "");
  const logoSrc = `${assetBase}/${LOGO_BY_SURFACE[surface] || LOGO_BY_SURFACE.dark}`;

  container.innerHTML = `
    <div class="kin-notify" data-state="idle" data-surface="${surface}">
      <img
        class="kin-notify__brand"
        src="${logoSrc}"
        alt="Kinvest Guidance"
        width="${LOGO_WIDTH}"
        height="${LOGO_HEIGHT}"
        decoding="async"
      >
      <form class="kin-notify__form" novalidate>
        <label class="visually-hidden" for="kin-notify-email-${source}">
          Email address
        </label>
        <input
          class="kin-notify__input"
          id="kin-notify-email-${source}"
          type="email"
          name="email"
          autocomplete="email"
          inputmode="email"
          maxlength="254"
          placeholder="${COPY.placeholder}"
          required
        >
        <button class="kin-notify__button" type="submit" disabled>
          <span class="kin-notify__button-label">${COPY.button}</span>
          <span class="kin-notify__spinner" aria-hidden="true"></span>
        </button>
      </form>
      <p class="kin-notify__hint">${COPY.hint}</p>
      <p class="kin-notify__message" role="alert"></p>
      <div class="kin-notify__success" role="status">
        <span class="kin-notify__success-icon" aria-hidden="true">✓</span>
        <div>
          <p class="kin-notify__success-title"></p>
          <p class="kin-notify__success-body"></p>
        </div>
      </div>
    </div>`;

  const root = container.querySelector(".kin-notify");
  const form = root.querySelector(".kin-notify__form");
  const input = root.querySelector(".kin-notify__input");
  const button = root.querySelector(".kin-notify__button");
  const message = root.querySelector(".kin-notify__message");
  const successTitle = root.querySelector(".kin-notify__success-title");
  const successBody = root.querySelector(".kin-notify__success-body");

  const setState = (state) => root.setAttribute("data-state", state);

  const showError = (text) => {
    message.textContent = text;
    setState("error");
    button.disabled = false;
  };

  const showSuccess = (alreadySubscribed) => {
    successTitle.textContent = alreadySubscribed
      ? COPY.successExistingTitle
      : COPY.successNewTitle;
    successBody.textContent = alreadySubscribed
      ? COPY.successExistingBody
      : COPY.successNewBody;
    setState("success");
  };

  // Empty state: submit stays dormant until there's something to submit,
  // and typing clears a previous error back to idle.
  input.addEventListener("input", () => {
    button.disabled = input.value.trim().length === 0;
    if (root.getAttribute("data-state") === "error") {
      message.textContent = "";
      setState("idle");
    }
  });

  form.addEventListener("submit", async (event) => {
    event.preventDefault();

    const email = input.value.trim().toLowerCase();
    if (!EMAIL_RE.test(email)) {
      showError(COPY.errorInvalid);
      return;
    }

    setState("loading");
    button.disabled = true;

    try {
      const result = await callSubscribeToLaunch(email, source);
      showSuccess(result.status === "already_subscribed");
    } catch (err) {
      showError(
        err.code === "INVALID_ARGUMENT" ? err.message : COPY.errorNetwork
      );
    }
  });

  return root;
}
