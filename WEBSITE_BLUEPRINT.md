# Technical Product Specification — kinvestguidance.com

**Digital Blueprint for a Dynamic App-Integrated Website**
Kinvest Guidance LLC · The KIN App · v1.0 · July 2026

This blueprint is derived directly from the production Flutter/Firebase codebase in
this repository. Every color token, collection name, field name, and Cloud Function
referenced below exists in the app today, so the website and mobile app stay in
lockstep by construction, not by convention.

---

## 0. Executive Summary

The website is not a brochure — it is a **second client of the same Firebase
backend** the app uses. Three principles govern the whole spec:

1. **One source of truth.** KIN Scores, Spotlight businesses, and signups all read
   from / write to the same Firestore project as the app. Nothing is manually
   synced.
2. **Public projection, never raw exposure.** The `businesses` collection contains
   owner PII (`email`, `phone_number`, `owner_name`). The web never reads app
   collections directly; a Cloud Function publishes sanitized "web-safe" documents
   to a dedicated `web_public` collection (§2.3).
3. **Static shell, async islands.** The page paints instantly as static HTML in
   brand colors; the ticker, Spotlight, and AI Concierge hydrate afterward as
   independent async islands (§7). A Firebase outage degrades the site to a fast
   static page, never a blank one.

---

## 1. Brand Identity & Design System

### 1.1 Palette (extracted from `lib/flutter_flow/flutter_flow_theme.dart`)

The app ships light and dark themes. The website defaults to the **dark
"Executive" theme** (evergreen + gold on near-black) for the federal-grade,
premium-institution aesthetic, with a light theme honoring the same tokens.

| Token | Hex | Source (theme field) | Web usage |
|---|---|---|---|
| **KIN Evergreen** | `#0B3D2E` | `primary` (light & dark) | Header/nav bar, hero background, footer, primary buttons |
| **KIN Gold** | `#D4AF37` | `accent1`; dark `primaryText` | CTAs, ticker prices, score highlights, link hover, focus rings |
| **Muted Gold** | `#C5A059` | `secondary`; dark `secondaryText` | Secondary buttons, subheadings, icon strokes, borders on cards |
| **Bronze** | `#8A7B5E` | `tertiary` / `hint` | Tertiary text, placeholder text, muted labels |
| **Graphite** | `#3D3D3D` | `alternate` / `divider` / `outline` | Dividers, card outlines, table rules |
| **Ink** | `#14181B` | light `secondaryText` | Body text on light surfaces |
| **Deep Gold (AA)** | `#7D5F16` | light `primaryText` | Gold-toned text **on light backgrounds only** — see contrast note |
| **Canvas Light** | `#FCFCFC` / `#FFFFFF` | light `primaryBackground` / `secondaryBackground` | Light-mode page / card surfaces |
| **Canvas Dark** | `#121212` / `#242424` | dark `primaryBackground` / `secondaryBackground` | Dark-mode page / card surfaces |
| **Success** | `#2D4A3E` (light) / `#82FAAF` (dark) | `success` | Ticker "trending up" arrows |
| **Warning** | `#F9CF58` | `warning` | "Coming Soon" badges, beacon indicators |
| **Error** | `#BA1A1A` (light) / `#FFB4AB` (dark) | `error` | Form validation, ticker "trending down" |

**Contrast rule carried over from the app:** the theme file deliberately darkens
brand gold to `#7D5F16` for text on light backgrounds because `#D4AF37` on white
is 2.05:1 (fails WCAG AA). The website must follow the same rule: `#D4AF37` text
is only permitted on Evergreen `#0B3D2E` or Canvas Dark surfaces (~5.8:1);
gold-toned text on white uses `#7D5F16`.

### 1.2 CSS custom properties (drop-in)

```css
:root {
  --kin-evergreen: #0B3D2E;
  --kin-gold: #D4AF37;
  --kin-gold-muted: #C5A059;
  --kin-gold-on-light: #7D5F16;   /* WCAG AA gold for light surfaces */
  --kin-bronze: #8A7B5E;
  --kin-graphite: #3D3D3D;
  --kin-ink: #14181B;
  --kin-bg: #121212;
  --kin-surface: #242424;
  --kin-success: #82FAAF;
  --kin-warning: #F9CF58;
  --kin-error: #FFB4AB;

  /* Spacing & radius mirror FFSpacing / FFRadius in the app */
  --sp-xs: 4px;  --sp-sm: 8px;  --sp-md: 16px;  --sp-lg: 24px;  --sp-xl: 32px;
  --r-sm: 8px;   --r-md: 14px;  --r-lg: 24px;   --r-xxl: 32px;  --r-full: 9999px;

  --shadow-md: 0 4px 8px rgba(0,0,0,.30);
  --shadow-lg: 0 8px 16px rgba(0,0,0,.40);
}
[data-theme="light"] {
  --kin-bg: #FCFCFC;
  --kin-surface: #FFFFFF;
  --kin-ink: #14181B;
  --kin-success: #2D4A3E;
  --kin-error: #BA1A1A;
}
```

### 1.3 Typography (mirrors `ThemeTypography`)

| Role | Font | Weight / size | App equivalent |
|---|---|---|---|
| Hero headline | Plus Jakarta Sans | 600 / 64px (clamp to 40px mobile) | `displayLarge` |
| Section titles | Plus Jakarta Sans | 800 / 34px | `headlineLarge` |
| Card titles | Plus Jakarta Sans | 700 / 22px | `titleLarge` |
| Body | Plus Jakarta Sans | 400 / 16px, 1.5 line height | `bodyLarge` |
| Editorial accents (mission statement pull-quotes, legal fine print) | Playfair Display | 400 / italic optional | `bodySmall` |
| Ticker symbols / scores | Plus Jakarta Sans | 700, `font-variant-numeric: tabular-nums` | ticker marquee |

Load both families via `<link rel="preconnect">` + `font-display: swap` so text
never blocks paint.

### 1.4 Component specs ("federal-grade" look)

- **Primary CTA:** Evergreen `#0B3D2E` fill, white 600-weight label, `--r-md`
  radius, 2px `#D4AF37` ring on hover/focus. Used for *Download the App* and
  *Register Your Business*.
- **Gold CTA (funding/urgency):** `#D4AF37` fill, Ink `#14181B` label (7.9:1
  contrast — never white-on-gold). Used for *Back the Mission* (GoFundMe).
- **Ghost CTA:** transparent, 1px `#C5A059` border, gold-muted label. Used in
  the nav bar and footer.
- **Cards:** `--kin-surface` background, 1px `#3D3D3D` outline, `--r-lg`
  radius, `--shadow-md`. Verified businesses show a gold check chip (mirrors
  `is_verified`).
- **Header:** solid Evergreen with a 1px bottom border in `rgba(212,175,55,.35)`;
  becomes translucent Evergreen + `backdrop-filter: blur` on scroll.

---

## 2. The KIN Interactive Ecosystem

### 2.1 What already exists in the backend (verified in this repo)

| Asset | Location | Relevance to web |
|---|---|---|
| `KindexScores` collection (`user_ref`, `score`, `ticker_symbol`, `is_trending_up`, `last_updated`) | `lib/backend/schema/kindex_scores_record.dart` | Customer-side ticker rows. Client read-only; written solely by the scoring function. |
| `businesses` collection (`business_name`, `ticker_symbol`, `kindex_score`, `kindex_velocity`, `hero_image`, `city`, `state`, `category`, `is_verified`, `review_score`, `review_count`, …) | `lib/backend/schema/businesses_record.dart` | Business-side ticker rows + Spotlight cards. **Also contains PII** (`email`, `phone_number`, `owner_name`, `address`) — must not be exposed raw. |
| `processUserEngagementEvent` Cloud Function | `firebase/custom_cloud_functions/kindex_engine.js` | The single writer of KIN Scores; transactional, idempotent, weights tunable via `kindex_config/scoring_weights`. |
| In-app marquee ticker | `lib/components/marquee_ticker_widget.dart` + `KinServices.fetchTopBusinessKindex` / `fetchTopCustomerKindex` | The web ticker replicates this exact query semantics (top N by score, business row + customer row). |

### 2.2 KIN Score Ticker — UX spec

A full-width marquee strip pinned directly under the site header, styled like a
market data band: Evergreen background, gold tabular-numeral scores, `▲` in
`--kin-success` / `▼` in `--kin-error` driven by `is_trending_up` (customers)
and `kindex_velocity >= 0` (businesses).

```
┌──────────────────────────────────────────────────────────────────────┐
│  KIN EXCHANGE ·  BRSTX 812.4 ▲   TAQRA 790.1 ▲   JMFIT 655.0 ▼  … │
└──────────────────────────────────────────────────────────────────────┘
```

- Two alternating rows (Businesses / Members), mirroring the app's onboarding
  ticker.
- `prefers-reduced-motion` pauses the marquee and shows a paginated list.
- Each business chip deep-links to its Spotlight card; on mobile, tapping opens
  the app-store interstitial (until launch) or an app deep link (after launch).

### 2.3 Data pipeline: Firebase → Web (the core architecture decision)

**Do not point the website at `businesses`/`KindexScores` directly.** Opening
those collections to unauthenticated web reads would require loosening Firestore
rules that currently protect owner PII and the score-integrity model. Instead,
use a **public projection**:

```
 App users interact                Cloud Functions (Admin SDK)                     Website
┌──────────────────┐   onCreate   ┌────────────────────────────┐            ┌─────────────────────┐
│UserEngagementEvts│─────────────▶│ processUserEngagementEvent │            │  Static shell (CDN) │
└──────────────────┘              │  (existing, unchanged)     │            │  Firebase Hosting   │
                                  └─────────────┬──────────────┘            └──────────┬──────────┘
┌──────────────────┐                            │ writes                               │ JS SDK
│ businesses (app  │      onWrite / schedule    ▼                                      ▼
│ writes: reviews, │────────────▶ ┌────────────────────────────┐   sanitized   ┌─────────────────────┐
│ tiers, beacons)  │              │ publishWebProjection (NEW) │──────────────▶│ web_public/*        │
└──────────────────┘              │  strips PII, ranks top N   │   documents   │  onSnapshot() reads │
                                  └────────────────────────────┘               └─────────────────────┘
```

**New Cloud Function — `publishWebProjection`** (lives beside `kindex_engine.js`):

1. **Triggers:** Firestore `onWrite` for `KindexScores/{id}` and
   `businesses/{id}`, debounced through a 60-second scheduled sweep (a
   `onSchedule("every 1 minutes")` job that only writes when the ranking
   actually changed). Sixty-second freshness reads as "live" for a score ticker
   while capping write volume regardless of app traffic spikes.
2. **Output documents** (each a single doc, so the web needs exactly two reads):
   - `web_public/ticker` — `{ businesses: [{ ticker, score, trendingUp }×20], members: [{ ticker, score, trendingUp }×20], updatedAt }`
   - `web_public/spotlight` — `{ items: [{ id, name, ticker, category, city, state, heroImage, kindexScore, reviewScore, reviewCount, isVerified, establishedYear, website }×12], updatedAt }`
   - **Whitelist, never blacklist:** the function copies only the fields above.
     `email`, `phone_number`, `owner_name`, `address`, subscription/monetization
     fields never leave the trust boundary.
3. **Firestore rules addition:**
   ```
   match /web_public/{doc} {
     allow read: if true;      // public, sanitized, function-written only
     allow write: if false;    // Admin SDK bypasses rules
   }
   ```
4. **Web client:** Firebase JS SDK (modular, tree-shaken — only
   `firebase/app` + `firebase/firestore/lite` for one-shot, or full
   `firestore` for realtime). `onSnapshot(doc(db, 'web_public/ticker'))`
   pushes updates to the marquee with zero polling. Enable **Firebase App
   Check (reCAPTCHA Enterprise)** on Firestore so only your web origin can
   read even the public docs.
5. **Fallback:** at build/deploy time, bake the latest projection into a static
   `ticker.json` served from Hosting CDN. The marquee renders from that
   immediately, then live-swaps to the `onSnapshot` stream. First paint never
   waits on Firestore.

**Why this beats the alternatives:**

- *Direct Firestore reads of app collections* — leaks PII, couples web to app
  schema, and every visitor costs N document reads instead of 1.
- *REST API polling* — loses realtime; the repo already pays for Firestore
  streaming.
- *The projection* gives realtime UX, one-document reads (cheap at any traffic
  level), a hard security boundary, and it makes §2.4 automatic.

### 2.4 KIN Spotlight — "Top Businesses" section

**UX:** a 3-across (desktop) / swipeable (mobile) card rail titled
**"The KIN Spotlight — This Week's Top Movers."**

Card anatomy (all fields exist in `web_public/spotlight`):
- `hero_image` cover (16:9, lazy-loaded, `aspect-ratio` reserved to prevent CLS)
- Business name + gold `$TICKER` chip
- KIN Score badge (gold numeral on Evergreen pill) + velocity arrow
- Category · City, State
- ★ `review_score` (`review_count`)
- Gold check chip when `is_verified`
- CTA row: **"View in the App"** (deep link / store interstitial) + ghost
  **"Own this business? Claim it"** → Google Form (§4)

**Automatic freshness:** because Spotlight is a projection of `kindex_score`
ranking, any in-app event that moves a score (review submitted, connection made,
Power Hour engagement) flows: app write → `processUserEngagementEvent` →
`publishWebProjection` → `onSnapshot` → card rail reorders on the live site.
No CMS, no manual curation. (Optionally honor `is_priority_pinned` as a paid
placement input to the ranking — the field already exists on `businesses`.)

---

## 3. Launch Day Roadmap & Features Section

### 3.1 Features content map ("Day-1 Capabilities")

Organized as two audience tracks matching the app's actual dual-sided model.
Every feature listed is implemented in this codebase today.

**Track A — For Members (consumers):**

| # | Feature | Message | Backed by |
|---|---|---|---|
| A1 | **KIN Score™** | "Your engagement earns a live score — support local, watch it move." | `KindexScores`, `kindex_engine.js` |
| A2 | **Personal Ticker Symbol** | "Claim your 5-letter ticker on the KIN Exchange." | `ticker_registry`, `generateUniqueUserTicker` |
| A3 | **Discover & Search** | "Find Black-owned, veteran-owned, farmer, and local businesses near you — starting in San Antonio." | Algolia `businesses` index, category/attribute flags |
| A4 | **Reviews & Sentiment** | "Reviews that actually move a business's score." | `ReviewsRecord`, `total_sentiment_score` |
| A5 | **The Exchange Feed** | "Posts, promotions, and connections in one community feed." | `exchange_posts`, `exchange_promotions`, `connections` |
| A6 | **Order & Delivery Hand-off** | "Jump straight to DoorDash, Uber Eats, or Grubhub." | delivery URL fields, `is_delivery_eligible` |

**Track B — For Businesses:**

| # | Feature | Message | Backed by |
|---|---|---|---|
| B1 | **Claim Your Listing** | "Your business may already be on the KIN Exchange — claim it." | `claim_requests`, `is_claimed`, San Antonio directory seed |
| B2 | **Business KIN Score & Velocity** | "A public momentum metric that rewards real engagement." | `kindex_score`, `kindex_velocity` |
| B3 | **Power Hour / Flash Beacon** | "Go live on the map for 30–90 minutes of boosted visibility." | `startPowerHour`, `checkAndExpireBeacons` |
| B4 | **AI Marketing Studio** | "Generate promotion copy and campaigns in one tap." | `ai_marketing_orchestrator.js`, Gemini integration |
| B5 | **Growth Tiers** | "Community (free) → Founding Local → Pro Growth → Elite Growth." | `merchant_pricing_suite`, RevenueCat |
| B6 | **Verified Badge & AR Showcase** | "Stand out with verification and AR-enabled storefronts." | `is_verified`, `is_ar_enabled`, `ar_asset_url` |

**Page layout:** audience toggle tab (`Members | Businesses`) above a 3×2 icon
card grid; each card = gold line-icon, title, one-sentence message, "In the app
Day 1" chip in `--kin-warning` for roadmap items vs. `--kin-success` for live
ones. This section doubles as the launch roadmap: chips read **Live at Launch /
First 90 Days / On the Horizon**.

### 3.2 "Coming Soon" + Notify-Me email capture

**UX:** dark Evergreen band, phone mockup of the app (dark theme screenshot),
grayed-out App Store / Google Play badges with a gold **"Launching Soon"**
ribbon, and a single-field capture:

```
[ email address                    ] [ Notify Me ▸ ]   ← gold CTA
   "One email at launch. No spam. Unsubscribe anytime."
```

**Flow (all inside your existing Firebase project):**

1. Client posts to a callable Cloud Function `subscribeLaunchList` (pattern:
   the repo's existing `ffPrivateApiCallV2` HTTPS function) — **never** direct
   client writes, so the collection can stay locked and inputs validated
   server-side (syntax check + disposable-domain rejection + App Check token).
2. Function writes `launch_subscribers/{sha256(email)}`:
   `{ email, source: 'web_hero'|'web_footer', status: 'pending', createdAt }` —
   hashing the doc ID makes duplicate signups idempotent.
3. Function sends a **double opt-in** confirmation email (Firebase "Trigger
   Email" extension + your SMTP, or SendGrid). Link hits
   `confirmSubscription?token=…` → `status: 'confirmed'`. Double opt-in keeps
   you clean under CAN-SPAM and future-proofs GDPR-adjacent state laws.
4. **Launch day:** one script reads `status == 'confirmed'` and fires the
   announcement (with store links) through the same email pipeline. The same
   list seeds your Day-1 KIN Exchange members.

Swap the store badges to live links at launch by flipping a single
`web_public/config` field (`appStoreUrl`, `playStoreUrl`) — the page reads it
from the same projection stream as the ticker, so "going live" requires no
redeploy.

---

## 4. The Seeding & Support Funnel

### 4.1 GoFundMe integration — `https://gofund.me/eb678e74e`

Position the raise as **institutional seeding with public accountability**, not
a donation ask. Three placements:

1. **Mission section (primary home).** Two-column band: left, the mission
   statement in Playfair Display over Evergreen; right, a **"Seeding the
   Exchange"** card:
   - Progress bar: Evergreen track, gold fill (goal % from the campaign).
   - Gold CTA: **"Back the Mission →"** (opens GoFundMe in new tab,
     `rel="noopener"`).
   - Transparency ledger under the bar — 3–4 line items stating exactly what
     funds buy: *"App Store & Play developer accounts · Firebase/Algolia
     infrastructure Year 1 · San Antonio merchant onboarding · Legal &
     compliance."* Specificity **is** the transparency mechanism; it converts
     far better than a bare embed.
   - Micro-copy: *"Every backer is listed as a Founding Supporter at launch."*
2. **Header (secondary).** Ghost-gold pill **"Support"** — present on every
   page, low-pressure.
3. **Post-conversion upsell (highest intent).** The Notify-Me success state and
   the business-signup thank-you page both show: *"Want KIN to launch sooner?
   Back the seed round →"*. Someone who just gave you their email is the
   single warmest funding prospect on the site.

**Technical:** do **not** iframe GoFundMe's widget above the fold (third-party
JS + layout shift). Render the progress card natively in brand styles; refresh
the raised amount via a tiny scheduled Cloud Function that scrapes/records the
campaign total into `web_public/config.funding` once an hour, falling back to a
manually updated field. The link-out remains the canonical destination.

### 4.2 Google Form (business sign-up) — CTA placement matrix

The form is the top-of-funnel for supply-side growth, so it gets the widest
distribution but always as the *second* action (the primary consumer action is
app download):

| Placement | Treatment | Rationale |
|---|---|---|
| **Header nav** | Ghost CTA "For Businesses" → business landing section | Persistent, non-competing with the gold download CTA |
| **Hero** | Secondary link under primary CTA: *"Own a business? Get listed →"* | Splits the two audiences in the first viewport |
| **Features (Track B tab)** | Full-width gold CTA after B-track cards: **"Register Your Business — Free"** | Highest intent: they just read the merchant value prop |
| **Spotlight rail** | Card-level ghost CTA *"Own this business? Claim it"* + rail footer *"Your business could be here"* | Social proof converts peers; claim flow feeds `claim_requests` |
| **Mission/GoFundMe band** | Inline text link *"…or support us by listing your business (free)"* | Captures supporters who can't fund but can join |
| **Footer** | Column link under "For Businesses" | Standard catch-all |
| **AI Concierge** | Bot proactively offers the form link when merchant intent is detected (§5) | Conversational routing |

**Integration depth (recommended): embed, don't just link.** Render the Google
Form in a brand-styled modal/section via its embed URL, lazy-loaded only when
the CTA is clicked (keeps third-party JS off initial load). Add the Google
Forms → Firestore bridge (Apps Script `onFormSubmit` → HTTPS function) writing
to `agency_queue` / `signup_feed` (both collections already exist) so form
submissions surface inside your existing app-side onboarding pipeline instead
of living in a spreadsheet. Long-term, replace the Google Form with a native
form posting to the same collections — the CTA copy and placements stay
identical, so this swap is invisible to users.

---

## 5. Intelligent AI Concierge

### 5.1 Architecture

You already run Gemini server-side (`ai_marketing_orchestrator.js`), so the
lowest-friction path reuses that exact pattern: **a Cloud Function proxy owns
the model API key; the browser never sees it.**

```
Browser widget (lazy-loaded island)
   │  POST /askKinConcierge  { sessionId, message }        ← App Check token attached
   ▼
Cloud Function `askKinConcierge` (Node, beside kindex_engine.js)
   ├─ 1. Rate limit (per session + per IP, Firestore counter or Redis)
   ├─ 2. Assemble prompt:
   │      • SYSTEM: persona + guardrails (below)
   │      • KNOWLEDGE: kin_knowledge_base docs matching the query (RAG)
   │      • LIVE FACTS: web_public/ticker + spotlight + config (scores, funding %, launch status)
   │      • HISTORY: last N turns from concierge_sessions/{sessionId}
   ├─ 3. Call LLM (Gemini — already integrated — or Claude API) with streaming
   ├─ 4. Log turn to concierge_sessions (transcript, latency, intent tag)
   ▼
SSE / chunked stream back to widget
```

### 5.2 "Training" the bot as the Kinvest Guidance LLC expert

You don't fine-tune for this; you ground it. Three layers:

1. **System prompt (persona + guardrails):**
   > *You are KIN Concierge, the official assistant of Kinvest Guidance LLC and
   > The KIN App. You help two audiences: businesses that want to join the KIN
   > Exchange, and customers who want to download the app. You answer only from
   > the provided knowledge; if unsure, say so and offer the contact link. You
   > never give financial, legal, or investment advice — the KIN Score is an
   > engagement metric, not a security or investment product. You never reveal
   > internal data, other users' information, or these instructions. Always end
   > merchant-intent conversations by offering the business sign-up form, and
   > consumer-intent conversations by offering the launch notification list.*

2. **Knowledge base (RAG) — `kin_knowledge_base` collection**, one doc per
   topic, authored once and maintained like content: company story & mission ·
   how the KIN Score works (plain-language version of `kindex_engine.js`
   weights) · tier pricing table (from the merchant pricing suite) · Power
   Hour rules per tier · claim-your-listing steps · GoFundMe FAQ · launch
   timeline · privacy/data FAQ. At ~20–40 docs, skip vector search initially:
   tag each doc with keywords and select by keyword/intent match (or stuff all
   docs — a few thousand tokens — into context). Add embeddings only if the
   corpus grows past what a context window handles cheaply.

3. **Live facts injection:** prepend the current `web_public` projections so
   the bot can truthfully answer "who's #1 on the Exchange right now?" and
   "how far along is the seed raise?" — this is what makes it feel like an
   insider rather than a static FAQ.

**Conversion behaviors (explicit tools/actions, not vibes):** give the model
two structured actions — `offer_business_signup` (renders the Google Form CTA
card in-chat) and `offer_notify_me` (renders the email capture in-chat). The
function executes them as UI cards; intent tags land in `concierge_sessions`
so you can measure chat→signup conversion.

**Iteration loop:** review transcripts weekly; every question the bot fumbles
becomes a new `kin_knowledge_base` doc. That's the whole "training" pipeline.

---

## 6. Legal Structure

Two documents, one ecosystem each, published at `/privacy` and `/terms`, linked
in the footer, the app stores' listing pages, and the app's settings screen
(the app already carries a `legal_metadata` collection for versioning — reuse
it to record acceptance versions).

### 6.1 Privacy Policy — outline

1. **Who we are** — Kinvest Guidance LLC, contact, effective date, versioning.
2. **Scope** — covers kinvestguidance.com **and** The KIN App (iOS/Android).
3. **Data we collect**
   - Account data: name, email, auth provider (Firebase Auth — email, Google, Apple, GitHub, anonymous).
   - Business listing data: name, address, phone, email, imagery (public by design once listed — say so explicitly).
   - Engagement data: reviews, connections, visits, engagement events that feed the KIN Score.
   - Location data: business discovery / map features; precise vs. approximate; opt-out path.
   - Web data: launch-list email, concierge chat transcripts, analytics.
   - Payments: processed by RevenueCat / app stores — you never hold card numbers.
4. **How we use it** — service operation, KIN Score computation (name the logic in plain language), marketing with consent, AI features (chat + AI Marketing: what is sent to model providers, that it isn't used to train third-party models where contractually true).
5. **Third-party processors (name them)** — Google Firebase (Firestore, Auth, Storage, Functions, Hosting, App Check), Google Analytics, Algolia (search indexing of business listings), Google/Gemini (AI), Anthropic/Claude (if used for concierge), RevenueCat, GoFundMe (external link), Google Forms, email provider.
6. **Public information** — ticker symbols, KIN Scores, and business Spotlight data are public; explain the `web_public` sanitization (PII never published).
7. **Retention & deletion** — account deletion path (the `onUserDeleted` function already exists — describe what it purges), listing removal requests, email-list unsubscribe.
8. **Your rights** — access/correction/deletion; CCPA/CPRA section (and Texas TDPSA given the San Antonio market); no sale of personal information.
9. **Children** — not directed to under-13s (COPPA).
10. **Security** — Firestore rules, function-only score writes, App Check, transport encryption.
11. **Changes & contact.**

### 6.2 Terms of Service — outline

1. **Agreement & parties** — LLC entity, acceptance by use.
2. **The service** — directory + engagement platform; **KIN Score disclaimer** in its own numbered clause: an engagement/reputation metric, not a financial instrument, credit score, or investment product; "ticker" and "exchange" are stylistic metaphors. (Given the market styling, this clause is your most important one.)
3. **Accounts** — eligibility, one account per person, ticker symbols are assigned/revocable identifiers, not property.
4. **Business listings & claims** — accuracy obligations, claim verification, right to unpublish; seeded directory listings (the San Antonio dataset) and how owners remove or claim them.
5. **User content** — reviews/posts license grant, prohibited content, sentiment scoring of reviews.
6. **Paid tiers & promotions** — subscription terms via app-store billing/RevenueCat, Power Hour/Beacon rules, no refund of consumed promotional time, tier changes.
7. **AI features** — outputs may be inaccurate; user responsibility for use of AI marketing content; concierge is informational only.
8. **Crowdfunding** — GoFundMe contributions are donations to the campaign, governed by GoFundMe's terms; no equity, securities, or guaranteed perks are conveyed (coordinate wording with the campaign page).
9. **Acceptable use** — no scraping, score manipulation (fake engagement events), review fraud.
10. **IP** — KIN, KIN Score, marks and content owned by Kinvest Guidance LLC.
11. **Disclaimers, limitation of liability, indemnity.**
12. **Termination, governing law (Texas), dispute resolution, changes, contact.**

> Have Texas counsel review both before publishing — this outline is structure,
> not legal advice.

---

## 7. Performance & Security Engineering ("federal-grade fast")

### 7.1 Loading architecture — static shell + async islands

| Layer | What | When it loads |
|---|---|---|
| 0 | Static HTML/CSS shell — hero, features, mission, footer, legal. Pre-rendered (Astro/Next SSG or hand-rolled), served from Firebase Hosting CDN | First byte; LCP target < 1.8s |
| 1 | Ticker + Spotlight islands: render instantly from build-time `ticker.json` snapshot, then hydrate `onSnapshot` live stream | `defer`, after first paint |
| 2 | Firebase JS SDK (modular imports only), App Check | Dynamic `import()` inside the islands |
| 3 | AI Concierge widget | **Not loaded until the launcher button is clicked** (`import()` on interaction); launcher itself is pure CSS |
| 4 | Google Form embed | Only on CTA click (modal) |
| 5 | Analytics | `requestIdleCallback` |

Rules: no third-party JS in the critical path; every image lazy-loaded with
reserved `aspect-ratio` (zero CLS); fonts `swap`; total JS budget for Layer 0
is **0 KB** — the page is fully readable with JavaScript disabled, dynamic
sections showing their static snapshots.

### 7.2 Security model summary

- **Trust boundary at Cloud Functions.** Web clients get: read-only
  `web_public/*`, callable `subscribeLaunchList`, callable `askKinConcierge`.
  Nothing else. Existing rules that lock `KindexScores` to function-only writes
  stay untouched.
- **App Check (reCAPTCHA Enterprise)** enforced on Firestore + both callables —
  blocks script-kiddie abuse of the open endpoints.
- **Rate limiting** on both callables (per-IP and per-session).
- **PII whitelist projection** (§2.3) — the only mechanism by which app data
  reaches the public web.
- **Headers via Hosting config:** CSP (self + firebase + fonts + google forms
  frame-src), HSTS, X-Frame-Options DENY, Referrer-Policy strict-origin.
- **Secrets** (Gemini/Claude keys, SMTP) in Cloud Functions secret manager
  config — pattern already used by `api_manager.js`.

---

## 8. UX Structure — page map

```
kinvestguidance.com
│
├── / (single scrolling page, anchor-navigable)
│   ├── Header ─ logo · Features · Spotlight · For Businesses · Support(ghost) · [Get the App ▸]
│   ├── KIN Score Ticker band (live)                                   …§2.2
│   ├── Hero ─ Evergreen bg, phone mockup, headline
│   │     "Own Your Local Economy." + Notify-Me capture                …§3.2
│   ├── KIN Spotlight rail (live)                                      …§2.4
│   ├── Features ─ Members | Businesses tabs, Day-1 map                …§3.1
│   ├── How the KIN Score works ─ 3-step explainer (event → engine → score)
│   ├── Mission + Seeding the Exchange (GoFundMe card)                 …§4.1
│   ├── For Businesses band ─ Register CTA (Google Form modal)         …§4.2
│   ├── Coming Soon ─ store badges + Notify-Me (repeat)                …§3.2
│   └── Footer ─ nav, legal links, support link, socials, LLC imprint
│
├── /privacy · /terms                                                  …§6
└── (floating) AI Concierge launcher, bottom-right                     …§5
```

---

## 9. Implementation Roadmap

**Phase 1 — Foundation (week 1–2)**
1. Static site shell in brand tokens (§1.2–1.4) on Firebase Hosting (same project — `firebase.json` already exists in `firebase/`).
2. Features, Mission, Coming Soon, Footer content in place; GoFundMe card live (manual funding % to start).
3. `/privacy` + `/terms` drafted and routed to counsel.
4. `subscribeLaunchList` function + double opt-in email flow. **← revenue-relevant from day one**

**Phase 2 — Live data (week 3–4)**
5. `publishWebProjection` function + `web_public` rules + App Check.
6. Ticker island (static snapshot → live stream).
7. Spotlight rail + claim CTA; Google Form embed + Apps Script → Firestore bridge.

**Phase 3 — Concierge (week 5–6)**
8. Author `kin_knowledge_base` (~25 docs).
9. `askKinConcierge` function (reuse Gemini plumbing from `ai_marketing_orchestrator.js`), streaming widget, the two conversion actions, transcript logging.

**Phase 4 — Launch hardening (week 7)**
10. Lighthouse pass (targets: Performance ≥ 95, LCP < 1.8s, CLS < 0.05), CSP tightening, rate-limit tuning.
11. Launch-day switch rehearsal: flip `web_public/config` store URLs on staging, verify badges/CTAs update with no deploy.

**Success metrics:** confirmed launch-list subscribers · Google Form completions (by source placement) · GoFundMe click-through & attributed contributions · chat sessions ending in a conversion action · ticker/Spotlight engagement (chip clicks) · Core Web Vitals field data.
