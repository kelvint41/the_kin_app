# KIN Notify-Me component

Launch-list email capture for kinvestguidance.com (blueprint §3.2 / Phase 1
item 4). Pairs with the `subscribeToLaunch` / `confirmLaunchSubscription`
Cloud Functions in `firebase/custom_cloud_functions/launch_subscribers.js`.

## Files

| File | Purpose |
|---|---|
| `notify-me.css` | All styling. Design tokens mirrored from `lib/flutter_flow/flutter_flow_theme.dart` (Evergreen `#0B3D2E`, gold `#D4AF37`, Plus Jakarta Sans, FFSpacing/FFRadius scales). |
| `notify-me.js` | Framework-free ES module. `initNotifyMe(container, { source, surface })`. |
| `NotifyMe.jsx` | React version, same class names, same CSS file. |
| `index.html` | Demo page showing dark (hero) and light (footer) placements. Preview: `python3 -m http.server` in this folder, open `/index.html`. |

## States

`data-state` on the root: `idle` (button disabled while the field is empty),
`loading` (spinner, inputs locked), `error` (inline message, error border),
`success` (form collapses into an Evergreen confirmation card; distinguishes
new signups from already-confirmed emails).

## Surfaces

`surface: "dark"` (default) for Evergreen/dark sections; `surface: "light"`
swaps gold text to the WCAG-AA `#7D5F16` shade the app uses on light
backgrounds.

## Backend contract

`POST https://us-central1-kinvest-build-app.cloudfunctions.net/subscribeToLaunch`
with `{"data": {"email": "...", "source": "web_hero"}}` →
`{"result": {"status": "pending_verification" | "already_subscribed"}}`.
No Firebase SDK required on the page.
