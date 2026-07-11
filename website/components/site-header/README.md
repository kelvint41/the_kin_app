# KIN Site Header component

Sticky site header for kinvestguidance.com (blueprint §1.4 / §8). Shares the
exact design tokens of the Notify-Me component (`../notify-me/`), all mirrored
from `lib/flutter_flow/flutter_flow_theme.dart`.

## Files

| File | Purpose |
|---|---|
| `site-header.css` | All styling: Evergreen `#0B3D2E` bar with gold-tinted bottom border, translucent blur once scrolled, responsive collapse at 860px. |
| `site-header.js` | Framework-free ES module. `initSiteHeader(container, { links, actions, activeHref, homeHref, assetBase })`. |
| `SiteHeader.jsx` | React version, same class names, same CSS file. |
| `index.html` | Demo: header + hero + embedded Notify-Me funnel (alignment test) + tall section to exercise the scroll treatment. Preview: `python3 -m http.server` from the **repo root**, open `/website/components/site-header/index.html`. |

## Branding

The header surface is always Evergreen, so per the CLAUDE.md Master Branding
Library matrix it uses the gold-text lockup:
`assets/KIN_Logo_Assets/10_website_header/header_logo_lockup_gold_text.png`
(default path relative to this folder; override with `assetBase`). Rendered at
40px tall (34px mobile) with intrinsic `width`/`height` set — no layout shift.

## Structure

- Nav placeholders: **Home · About · Spotlight · KIN Score** (override via
  `links`); `activeHref` gets `aria-current="page"` + gold underline.
- Actions: ghost **Support** + gold **Get the App** CTA. Gold fill carries an
  Ink `#14181B` label (never white-on-gold), since an Evergreen button would
  vanish on the Evergreen bar.
- Mobile (≤860px): hamburger toggle, full-width Evergreen dropdown panel,
  Escape closes, links auto-close on tap. `prefers-reduced-motion` respected.
