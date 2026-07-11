# kinvestguidance.com — Site Architecture, Copy & Growth Strategy

**Brand, conversion, and SEO companion to `WEBSITE_BLUEPRINT.md`**
Kinvest Guidance LLC · Kelvin Taylor, CEO · v1.0 · July 2026

Voice: professional, community-driven, empowering, innovative. Plain
language a shop owner reads on their phone between customers — no corporate
jargon, no hype. The KIN Score's exchange styling is a metaphor we lean into
("Own your local economy") while the legal disclaimers in
`WEBSITE_BLUEPRINT.md` §6 keep it honest.

---

## 1. Site Architecture (high-conversion sitemap)

One scrolling homepage does the selling; three support pages do the trust
work. Every path ends at one of exactly two conversions: **user waitlist**
(Notify-Me) or **business sign-up** (Google Form → discovery pipeline).

```
kinvestguidance.com
│
├── /  HOMEPAGE — "the bridge"
│   1. Header (built) ..................... nav + Get the App
│   2. KIN Score Ticker (built) ........... proof of life, instantly different
│   3. HERO ............................... mission headline + Notify-Me (built)
│   4. Live Community Map (built) ......... "this is real, and it's near you"
│   5. HOW IT WORKS ....................... 3 steps, split user/owner tabs
│   6. THE MISSION ........................ Kelvin's story + GoFundMe card
│   7. FOR BUSINESS OWNERS ................ value prop + Register CTA
│   8. SPOTLIGHT RAIL (next build) ........ top businesses, social proof
│   9. COMING SOON / stores ............... second Notify-Me placement
│  10. Footer ............................. trust links, legal, contact
│
├── /for-business ......................... owner-facing landing (the Form
│                                           lives here; SEO: "get listed")
├── /mission .............................. long-form story + transparency
│                                           ledger (GoFundMe deep-dive)
├── /blog ................................. SEO engine (§4)
└── /privacy · /terms ..................... trust + store requirements
```

**Why this order:** the ticker and map appear *before* any ask — visitors see
a living economy first, get asked to join it second. The mission section sits
mid-page deliberately: people join movements after they've seen the product
works, not before.

---

## 2. Homepage Copy (draft, ready to paste)

### 2.1 Hero

> **Own Your Local Economy.**
>
> The KIN App connects you with independent, Black-owned businesses in your
> city — and turns every visit, review, and purchase into measurable
> momentum. Watch your community grow. Watch your KIN Score climb.
>
> *Launching first in San Antonio. Houston and Atlanta are next.*
>
> `[ Notify-Me email capture ]`
> One email at launch. No spam. Unsubscribe anytime.
>
> Secondary link: *Own a business? → Get listed free*

### 2.2 How It Works — For Members tab

> **Support isn't abstract anymore.**
> 1. **Discover** — Find Black-owned restaurants, shops, and services near
>    you, verified by real people, not scraped lists.
> 2. **Show up** — Visit, review, connect. Every action earns KIN Score for
>    you and momentum for them.
> 3. **Watch it grow** — Your neighborhood's businesses rise on the KIN
>    Exchange in real time. That's your spending, made visible.

### 2.3 How It Works — For Business Owners tab

> **You built the business. We built the infrastructure.**
> 1. **Get listed free** — Claim your ticker symbol on the KIN Exchange in
>    minutes. No fees to be found.
> 2. **Get verified** — A real person confirms your listing, so customers
>    know it's you.
> 3. **Get momentum** — Reviews and visits raise your KIN Score. Power Hours
>    and Spotlight put you in front of the whole city.

### 2.4 The Mission (Kelvin's section)

> **Infrastructure is the difference between surviving and owning.**
>
> Black-owned businesses don't lack talent, work ethic, or customers who
> care. Too often, they lack the digital infrastructure that big brands take
> for granted — discovery, reputation, analytics, marketing.
>
> Kinvest Guidance LLC exists to close that gap. The KIN App is the first
> piece: a directory where the community's support is counted, scored, and
> celebrated in real time. We're proving it in San Antonio, then Houston,
> then Atlanta. Then everywhere.
>
> — Kelvin Taylor, Founder & CEO
>
> `[ Seeding the Exchange card: progress bar + transparency ledger ]`
> **Back the Mission →** Every dollar goes to store fees, infrastructure,
> and onboarding San Antonio merchants — itemized, public, accountable.

### 2.5 For Business Owners band

> **Your customers are looking for you. Make sure they find you.**
> Free listing · Verified badge · Live KIN Score · AI marketing tools ·
> Delivery links · Power Hour promotions
>
> **Register Your Business — Free →**
> *Takes about 4 minutes. A human reviews every listing.*

### 2.6 Coming Soon band

> **The KIN App arrives this year.**
> iOS and Android. San Antonio first — be there on day one.
> `[ store badges (Launching Soon) + Notify-Me ]`

### 2.7 Footer mission line

> Kinvest Guidance LLC — building digital infrastructure for independent,
> Black-owned businesses. Stronger Together.

---

## 3. Conversion Flow & CTA System

Two conversions, one visual language (tokens from CLAUDE.md):

| CTA | Style | Placements | Handoff |
|---|---|---|---|
| **Get the App** (post-launch) / **Notify Me** (pre-launch) | Gold fill, ink text — the only gold buttons on the page | Header (persistent) · Hero · Coming Soon · after Spotlight | Pre-launch: `subscribeToLaunch` double opt-in (built). Post-launch: flip `web_public/config` store URLs — badges/CTAs update with no redeploy (built into blueprint). |
| **Register Your Business — Free** | Evergreen fill on light bands / outlined on dark | Hero secondary link · Owners band · map card ("Your business could be here") · footer · `/for-business` | Google Form (modal, lazy-loaded) → `ingestBusinessCandidate` → discovery pipeline (DISCOVERY_BLUEPRINT.md). |
| **Back the Mission** | Gold outline (never competes with the two above) | Mission card · post-conversion thank-you states | GoFundMe link-out with native-styled progress card. |

**Friction rules:** never two primary CTAs in one viewport; every conversion
returns a warm next step (Notify-Me success → "Want us to launch sooner? Back
the mission" · Form thank-you → "Know another great business? Suggest it");
mobile gets a slim sticky bottom bar (**Notify Me · List a Business**) after
50% scroll — the highest-converting placement on phones, where most local
traffic will land.

**The handoff promise:** the same email captured pre-launch receives exactly
one launch email with store links (§WEBSITE_BLUEPRINT 3.2) — the waitlist IS
the day-one user base.

---

## 4. SEO & Growth — 3-Month Content Plan (San Antonio)

**Positioning:** kinvestguidance.com should become the freshest, most
credible answer to "Black-owned businesses in San Antonio" — earned by
publishing the directory's own verified data, which no competitor has.

### Foundation (week 1, one-time)
- Title: `The KIN App — Discover Black-Owned Businesses in San Antonio`;
  meta descriptions per page; OG/Twitter cards using the branding library.
- `LocalBusiness` + `Organization` JSON-LD; later, per-business schema on
  Spotlight pages (the `web_public` data makes this automatic).
- Google Business Profile for Kinvest Guidance LLC; Search Console + sitemap.

### Month 1 — Plant the flag (target: index + first local rankings)
| Content | Target query |
|---|---|
| Pillar page: **"The Guide to Black-Owned Businesses in San Antonio (2026)"** — 15–20 verified listings from the directory, organized by category, updated monthly (freshness signal) | "black owned businesses san antonio" |
| Blog: "How the KIN Score Works" | brand + "what is a kin score" |
| Blog: "Why San Antonio First" (founder story, expansion map) | "support black owned businesses san antonio" |
| `/for-business` page live | "list my business san antonio directory" |

### Month 2 — Own the categories (target: long-tail wins)
| Content | Target query |
|---|---|
| Category guides ×3: **restaurants**, **barbershops/beauty**, **services** — each pulls live from the verified directory | "black owned restaurants san antonio" etc. |
| Merchant spotlight ×2 (interview one real owner; they share it — first backlinks) | business name + neighborhood queries |
| Blog: "Claim Your Business on the KIN Exchange" (walkthrough) | "claim business listing" |

### Month 3 — Compound (target: authority + expansion seeds)
| Content | Target query |
|---|---|
| Neighborhood guides ×2 (East Side, Southtown) using map data | "black owned businesses near me" + neighborhood |
| "State of the San Antonio KIN Exchange" — first data report from real Kindex/engagement stats (uniquely defensible; local press bait) | citations/backlinks |
| Houston + Atlanta teaser pages ("The Exchange is coming — get on the list") | early "black owned businesses houston/atlanta" presence |
| Outreach: 5 local orgs (SA Black Chamber, culture blogs, university small-biz centers) pitching the data report | backlinks, referral traffic |

**Cadence after month 3:** one category/neighborhood guide + one spotlight
per month, pillar page refreshed monthly, data report quarterly. Every guide
ends with both CTAs — owners see "get listed," members see "get the app."

**Measurement:** Search Console positions for the pillar terms; organic
sessions → Notify-Me conversions (source tag `web_seo`); form submissions
attributed via `?src=` params the discovery pipeline stores as provenance
metadata.

---

## 5. Voice Guardrails (for anyone writing under this brand)

- Say **"independent, Black-owned businesses"** — celebrate specificity.
- "Community," "ownership," "momentum," "infrastructure" — yes.
  "Synergy," "disrupt," "leverage," "ecosystem play" — no.
- The exchange language is aspirational, never financial advice: businesses
  have *momentum*, scores *climb*, neighborhoods *rise*. Never "invest,"
  "returns," or "shares" in product copy (see WEBSITE_BLUEPRINT §6.2).
- Every claim traceable: "verified by real people" is true because of the
  discovery pipeline; "watch it live" is true because of the ticker. If a
  feature isn't built, the copy says "coming," not "here."
