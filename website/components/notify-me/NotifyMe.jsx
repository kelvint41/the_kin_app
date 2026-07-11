/* KIN Notify-Me — React version. Shares notify-me.css with the vanilla
 * component (same class names, same design tokens), so both render
 * identically wherever they're embedded.
 *
 *   import NotifyMe from "./NotifyMe.jsx";
 *   import "./notify-me.css";
 *   <NotifyMe source="web_hero" surface="dark" />
 */

import { useId, useState } from "react";

const FIREBASE_PROJECT_ID = "kinvest-build-app";
const FUNCTIONS_REGION = "us-central1";
const SUBSCRIBE_URL =
  `https://${FUNCTIONS_REGION}-${FIREBASE_PROJECT_ID}.cloudfunctions.net/subscribeToLaunch`;

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

export default function NotifyMe({ source = "web", surface = "dark" }) {
  const inputId = useId();
  const [email, setEmail] = useState("");
  const [state, setState] = useState("idle"); // idle | loading | success | error
  const [error, setError] = useState("");
  const [alreadySubscribed, setAlreadySubscribed] = useState(false);

  const handleChange = (event) => {
    setEmail(event.target.value);
    if (state === "error") {
      setError("");
      setState("idle");
    }
  };

  const handleSubmit = async (event) => {
    event.preventDefault();

    const normalized = email.trim().toLowerCase();
    if (!EMAIL_RE.test(normalized)) {
      setError(COPY.errorInvalid);
      setState("error");
      return;
    }

    setState("loading");
    try {
      const result = await callSubscribeToLaunch(normalized, source);
      setAlreadySubscribed(result.status === "already_subscribed");
      setState("success");
    } catch (err) {
      setError(err.code === "INVALID_ARGUMENT" ? err.message : COPY.errorNetwork);
      setState("error");
    }
  };

  return (
    <div className="kin-notify" data-state={state} data-surface={surface}>
      <form className="kin-notify__form" noValidate onSubmit={handleSubmit}>
        <label className="visually-hidden" htmlFor={inputId}>
          Email address
        </label>
        <input
          className="kin-notify__input"
          id={inputId}
          type="email"
          name="email"
          autoComplete="email"
          inputMode="email"
          maxLength={254}
          placeholder={COPY.placeholder}
          value={email}
          onChange={handleChange}
          required
        />
        {/* Empty state: dormant until the field has content */}
        <button
          className="kin-notify__button"
          type="submit"
          disabled={email.trim().length === 0 || state === "loading"}
        >
          <span className="kin-notify__button-label">{COPY.button}</span>
          <span className="kin-notify__spinner" aria-hidden="true" />
        </button>
      </form>
      <p className="kin-notify__hint">{COPY.hint}</p>
      <p className="kin-notify__message" role="alert">
        {error}
      </p>
      <div className="kin-notify__success" role="status">
        <span className="kin-notify__success-icon" aria-hidden="true">
          ✓
        </span>
        <div>
          <p className="kin-notify__success-title">
            {alreadySubscribed ? COPY.successExistingTitle : COPY.successNewTitle}
          </p>
          <p className="kin-notify__success-body">
            {alreadySubscribed ? COPY.successExistingBody : COPY.successNewBody}
          </p>
        </div>
      </div>
    </div>
  );
}
