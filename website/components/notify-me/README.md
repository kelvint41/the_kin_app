# KIN Notify-Me component

Launch-list email capture for kinvestguidance.com (blueprint §3.2 / Phase 1
item 4). Pairs with the `subscribeToLaunch` / `confirmLaunchSubscription`
Cloud Functions in `firebase/custom_cloud_functions/launch_subscribers.js`.

## Files

| File | Purpose |
|---|---|
| `notify-me.css` | All styling. Design tokens mirrored from `lib/flutter_flow/flutter_flow_theme.dart` (Evergreen `#0B3D2E`, gold `#D4AF37`, Plus Jakarta Sans, FFSpacing/FFRadius scales). |
| `notify-me.js` | Framework-free ES module. `initNotifyMe(container, { source, surface, assetBase })`. |
| `NotifyMe.jsx` | React version, same class names, same CSS file. |
| `index.html` | Demo page showing dark (hero) and light (footer) placements. Preview: `python3 -m http.server` from the **repo root** (the logo paths resolve to `assets/KIN_Logo_Assets/`), open `/website/components/notify-me/index.html`. |

## States

`data-state` on the root: `idle` (button disabled while the field is empty),
`loading` (spinner, inputs locked), `error` (inline message, error border),
`success` (form collapses into an Evergreen confirmation card; distinguishes
new signups from already-confirmed emails).

## Surfaces & branding

`surface: "dark"` (default) for Evergreen/dark sections; `surface: "light"`
swaps gold text to the WCAG-AA `#7D5F16` shade the app uses on light
backgrounds.

The component renders the Master Branding Library header lockup above the
form (see CLAUDE.md selection matrix): dark surfaces use
`assets/KIN_Logo_Assets/10_website_header/header_logo_lockup_gold_text.png`,
light surfaces use `header_logo_lockup_dark_text.png`. Paths are relative to
this folder by default (`../../../assets/KIN_Logo_Assets`); pass `assetBase`
if your shell serves the assets from a different root. For production, copy
the two lockups into the deployed static bundle and resize to ~440px wide
(2× the 220px render width) per CLAUDE.md rule 3.

## Backend contract

`POST https://us-central1-kinvest-build-app.cloudfunctions.net/subscribeToLaunch`
with `{"data": {"email": "...", "source": "web_hero"}}` →
`{"result": {"status": "pending_verification" | "already_subscribed"}}`.
No Firebase SDK required on the page.
