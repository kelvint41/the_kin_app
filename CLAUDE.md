# The KIN App — repo guide

Flutter/FlutterFlow app (Kinvest Guidance LLC) + Firebase backend
(`firebase/`) + website workstream (`website/`, spec in `WEBSITE_BLUEPRINT.md`,
service layer docs in `SERVICES_BLUEPRINT.md`).

Design tokens live in `lib/flutter_flow/flutter_flow_theme.dart`:
KIN Evergreen `#0B3D2E` (primary), brand gold `#D4AF37` (accent1), muted gold
`#C5A059`, bronze `#8A7B5E`, graphite `#3D3D3D`, canvas `#FCFCFC`/`#121212`.
Contrast rule: `#D4AF37` text only on dark/Evergreen surfaces; on light
surfaces use `#7D5F16`. Fonts: Plus Jakarta Sans (primary), Playfair Display
(editorial accents).

## Master Branding Library — `assets/KIN_Logo_Assets/`

The canonical logo/asset kit for ALL UI components, landing pages, and web
features. When building anything visual: pick the variant below that matches
the background and layout, and reference it by its exact path. Full inventory
and store-upload checklist: `assets/KIN_Logo_Assets/README.txt`.

The logo mark is a gold woven globe with a green vine and an upward gold
arrow. Opaque kit assets use a **navy `#0A101E` / charcoal `#1A1A1A`**
background (the logo kit palette) — visually compatible with, but not
identical to, the app theme's Evergreen `#0B3D2E`. Prefer transparent
variants over opaque ones when placing the logo on Evergreen or any themed
surface, so the navy plate never clashes.

### Selection matrix (web work)

| Context | Asset path | Notes |
|---|---|---|
| Site header / nav on dark or Evergreen bg | `assets/KIN_Logo_Assets/10_website_header/header_logo_lockup_gold_text.png` | 1558×286 transparent; gold "KINVEST GUIDANCE" wordmark; render ~180–220px wide |
| Site header / nav on light bg | `assets/KIN_Logo_Assets/10_website_header/header_logo_lockup_dark_text.png` | 1558×286 transparent; near-black wordmark |
| Standalone mark (footer, cards, chat avatar, compact header) | `assets/KIN_Logo_Assets/10_website_header/header_logo_mark_transparent.png` | 858×819 transparent, works on any surface (duplicate of `01_master/kin_logo_master_transparent.png`) |
| Small square logo, dark UI | `assets/KIN_Logo_Assets/02_flutterflow/in_app_logo_dark_mode/kin_logo_dark_{1x_240,2x_480,3x_720}.png` | Transparent, tuned for dark; pick size by render density |
| Small square logo, light UI | `assets/KIN_Logo_Assets/02_flutterflow/in_app_logo_light_mode/kin_logo_light_{1x_240,2x_480,3x_720}.png` | Off-white plate (opaque) — light surfaces only |
| Favicon / browser tab | `assets/KIN_Logo_Assets/09_favicon/favicon_dark_256.png` (transparent) or `favicon_default_256.png` (navy plate) | 256×256; transparent one adapts to browser theme |
| Google Form header | `assets/KIN_Logo_Assets/11_google_form/google_form_header_1600x400.png` | Navy bg, lockup + "JOIN THE MOVEMENT" |
| Print/flyer QR to sign-up | `assets/KIN_Logo_Assets/12_qr_code/kin_qr_card.png` (branded card) or `kin_qr_plain.png` (transparent QR only) | |
| Social profile images | `assets/KIN_Logo_Assets/03_social_profile/` | Per-platform sizes, circle-safe margins |
| Social cover banners | `assets/KIN_Logo_Assets/04_social_banners/` | Per-platform dimensions in filenames |
| App store icons | `assets/KIN_Logo_Assets/05_store_icons/` | iOS 1024 no-alpha; Play 512 32-bit |
| Store screenshots / feature graphic | `assets/KIN_Logo_Assets/07_ios_screenshots/`, `08_play_screenshots/`, `06_play_feature_graphic/` | Templates with a gold-outlined capture slot; see README.txt |

### Rules

1. Never stretch, recolor, or add effects to the mark; scale proportionally.
2. Dark/Evergreen surface → gold-text lockup; light surface → dark-text
   lockup; tight spots → the transparent mark alone.
3. Web pages must not ship multi-hundred-KB headers: resize/compress to the
   render size (e.g. export the 1558px lockup at ~440px/2x, `loading="lazy"`
   below the fold, explicit width/height to avoid CLS).
4. Cite the exact repo path in code comments/docs when a component embeds an
   asset, so designers can trace every usage.
