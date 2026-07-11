# KIN Community & Data layer

The unified module beneath the Site Header (blueprint §2): the **KIN Score
Ticker band**, the **Community Live Map**, and the **New Sign-up Flash**
toasts. One stylesheet, one ES module, same `flutter_flow_theme.dart` tokens
as `../site-header/` and `../notify-me/`.

## Layout order

```
Site Header (sticky)
KIN Score Ticker band   ← full-width, directly beneath the header
Hero (+ Notify-Me funnel)
Community section       ← map card, center stage, city switcher
Sign-up Flash toasts    ← fixed bottom-left overlay, outside the layout flow
```

## Initializers (`community-data.js`)

| Call | What it renders | Live source |
|---|---|---|
| `initKinTicker(el, { live, pollMs, items })` | Marquee band: `$TICKER score ▲/▼`, BIZ + MBR groups, pause on hover/focus. `prefers-reduced-motion` → static hand-scrollable strip (clone track hidden). | `web_public/ticker`, 60s poll |
| `initCommunityMap(el, { live, leaflet, city })` | Leaflet card with CARTO dark tiles, gold/Evergreen circle markers, San Antonio / Houston / Atlanta switcher with per-city counts. | `web_public/map`, fetch on load |
| `initSignupFlash({ live, demo, pollMs, toastMs })` | Toast: “New business added: **Name** in City!” — logo mark icon, `aria-live="polite"`, auto-dismiss 6s, max 3 stacked, dedupe by entry id (first poll primes silently). | `web_public/signups`, 30s poll |

All three default to brand-styled **mock data** (`live: false`) so the page
renders before the backend is deployed; live mode reads the `web_public`
documents through the Firestore REST API — zero SDK bytes on the page.

## Mapping solution

**Leaflet 1.9 + CARTO `dark_all` tiles** — no API key, no billing account,
~42 KB, dark basemap that matches the Evergreen theme. Upgrading to Mapbox
later is a one-line tile-URL swap in `initCommunityMap`. Leaflet 1.9.4 is
vendored at `website/vendor/leaflet/` (self-hosted per blueprint §7 — no
CDN dependency in the critical path).

## Backend wiring (`firebase/custom_cloud_functions/web_projection.js`)

- `publishWebProjection` — scheduled every 5 min: top-20 `businesses` by
  `kindex_score` + top-20 `KindexScores` → `web_public/ticker`; per-city
  business coordinates → `web_public/map`. **Whitelisted fields only** —
  ticker/name/score/trend and lat/lng/name/category. Owner PII never leaves
  the trust boundary.
- `publishSignupFlash` — `onCreate` of `businesses/{id}` → prepends
  `{id, name, city, at}` to `web_public/signups.items` (capped at 10).
- Rules: `web_public/*` is public-read, client-write-denied
  (`firebase/firestore.rules`).

### Go-live steps

```bash
cd firebase
firebase deploy --only functions:custom_cloud_functions:publishWebProjection,functions:custom_cloud_functions:publishSignupFlash
firebase deploy --only firestore:rules
```

then flip `live: true` in the three init calls. Later, when the shell is
bundled with the Firebase JS SDK, swap the REST polling for `onSnapshot`
streams on the same three documents — the render functions don't change.

## Demo

`python3 -m http.server` from the **repo root**, open
`/website/components/community-data/index.html` — full stack: header,
ticker, Notify-Me hero, map, and demo toasts every 10s.
