# Kinvest Guidance — Living Documentation / Codebase Inventory

> **Status:** living document — update in place when the architecture changes.
> **Baseline:** 2026-07-16, branch `claude/kinvest-prestige-page-prompt-8rmpdm`
> (post security-audit remediation of Findings 1–4).
>
> Scope note: this inventory covers the hand-written logic that governs data
> and money — `lib/services/`, `lib/custom_code/`, and `firebase/`. The
> ~370 FlutterFlow-generated page widgets and the `lib/old_designs/`
> component graveyard are described by pattern, not file-by-file.

---

## 0. System at a Glance

| Layer | Technology | Where |
|---|---|---|
| Client | Flutter (FlutterFlow-generated) | `lib/` (461 `.dart`) |
| Hand-written logic | Dart service layer + custom action | `lib/services/kin_services.dart`, `lib/custom_code/` |
| Backend | Firebase: Firestore, Auth, Functions, Storage | `firebase/` |
| Scoring / AI / billing writes | Cloud Functions (Node 20) + Gemini | `firebase/custom_cloud_functions/` |
| Search | Algolia | `lib/backend/algolia/` |
| Payments | RevenueCat | `lib/flutter_flow/revenue_cat_util.dart` |

**Signature concept — the "Kindex":** a proprietary engagement score for both
businesses and customers, plus stock-ticker-style symbols. It threads through
scoring, onboarding tickers, and public rankings.

---

## 1. Data & Schema Architecture

Collections defined in `lib/backend/schema/`, governed by
`firebase/firestore.rules`. The **Client access** column reflects the current
(hardened) rules.

| Collection | Purpose | Client access |
|---|---|---|
| `users` | Account profile (`email, displayName, tickerSymbol, ownedBusiness, isAdmin, isActive, lastLogin, arToursCompleted`) | Read/write self only; `is_admin` **not** client-writable |
| `businesses` | Directory record (~65 fields) | Public read; create requires `owner_ref == self`; update restricted to `mutableBusinessFields()` allowlist |
| `reviews` | Star + text reviews | Public read; create self-authored, rating 1–5 validated |
| `UserEngagementEvents` | Append-only Kindex event log | Self read; create must be `status:'pending'` with no scoring fields |
| `KindexScores` | Computed customer scores | Public read; **function-only** write |
| `kindex_config` | Tunable `scoring_weights` doc | Auth read; function-only write |
| `ticker_registry` | Atomic uniqueness lock for customer tickers | Public read; auth create-only (doc ID = the ticker) |
| `exchange_posts` | "The Exchange" social feed | Public read; **verified** business owners create |
| `ai_generation_logs` (+ `engagement` subcol) | AI marketing audit trail | Fully locked (function-only) |
| `activity_logs` | Page-view / tap telemetry | Create shape + identity-checked; **admin-only read** |
| `agency_queue` | Internal ops / project tracking | Create closed; auth read |
| `analytics_daily` | (no current client usage) | Create closed; admin read |
| `legal_metadata` | Privacy-policy version data | Create closed; **public read (intentional — pre-signup)** |
| `entitlements` | Tier/comp grants | **Fully locked** |
| `uservisits` | Legacy visit tracking | **Fully locked** |
| `orders` | Commerce | Auth create + read; no client update |
| `connections` | Social graph | Auth create + read |
| `exchange_promotions` | Promo records | Auth create + read |
| `tier_privileges` | Per-owner privileges | Owner-scoped read (`owner_id`) |
| `bug_reports`, `analytics_events`, `claim_requests`, `marketing_requests` | Intake | Auth create-only; reads locked |
| `signup_feed` | Admin activity feed | Self create; **admin-only read** |

**Interaction pattern:** writes funnel through `KinServices` (Dart) or Cloud
Functions — the client almost never writes Firestore directly. Reads use
FlutterFlow `query*Record` stream builders. Public-read collections
(`businesses`, `KindexScores`, `reviews`, `legal_metadata`) are deliberately
public so logged-out screens (onboarding ticker, directory, privacy policy)
render without auth.

---

## 2. Core Business Logic

### 2a. `KinServices` — service layer (`lib/services/kin_services.dart`)

**Intent:** crash-proof, one-line backend calls per button.
**Mechanism:** every method checks preconditions → wraps the Firebase call in
`try`/`catch` → returns `ServiceResult<T>` (`isSuccess`/`error`) instead of
throwing, so an `onPressed` handler never needs its own try/catch.

| Method | Intent | Mechanism (notable) |
|---|---|---|
| `registerBusiness` | Onboard a business | Generates unique ticker → creates `businesses` doc (`Community`, `is_verified:false`) → links `ownedBusiness` → refreshes cached user doc. Bails if no free ticker. |
| `generateUniqueTicker` / `generateUniqueUserTicker` | 5-char stock symbol | Business dedupes by query; customer reserves atomically via `ticker_registry` (the self-only `users` collection can't be queried). Customer failure is non-blocking. |
| `submitReview` | Post a review | Writes `reviews` with server timestamp. |
| `upgradeBusinessTier` | Change tier | RevenueCat `purchasePackage` **first**, then calls the `setBusinessSubscription` Cloud Function — does not write Firestore directly and does not accept entitlement booleans. |
| `downgradeToCommunity` | Free tier | Routes through the same callable with `'Community'`. |
| `startPowerHour` / `stopPowerHour` | Timed promo | Call the `startPowerHour`/`stopPowerHour` Cloud Functions, which enforce the per-tier duration cap + rolling 7-day frequency server-side. Client can't write the Power Hour fields directly. |
| `generateMarketingContent` / `logAiSuggestionEngagement` | AI marketing | Pass-throughs to Cloud Functions; no client-side Gemini path by construction. |
| `shareApp` | Share + score | Opens native share sheet, then fires a best-effort `share_app` engagement event. |

### 2b. Kindex scoring engine (`firebase/custom_cloud_functions/kindex_engine.js`)

**Intent:** award engagement points server-side so users can't self-award.
**Mechanism:** `onCreate` trigger on `UserEngagementEvents`, run in a
transaction and **idempotent** — re-checks `status === 'pending'` inside the
transaction so at-least-once redelivery is a safe no-op. Looks up
`points = weights[event_type]` (weights cached in-memory 5 min, tunable in
`kindex_config` without redeploy), increments `KindexScores`, and denormalizes
`ticker_symbol`/`is_trending_up` onto the score doc so ticker UI needn't query
the self-only `users` collection. Rejects unknown `event_type` / missing
`user_ref`.

### 2c. AI Marketing Orchestrator (`ai_marketing_orchestrator.js`)

**Intent:** paid AI post generation, entitled tiers only.
**Mechanism:** callable with three ordered gates — auth present → **ownership**
(`owner_ref == users/{uid}`) → **entitlement** (`subscription_tier` in
`{Pro Growth, Elite Growth}`) → Gemini 1.5 Flash with a JSON response schema,
validates exactly 3 hashtags, logs every call (including rejections + latency)
to `ai_generation_logs`. Gemini key is a server-side secret.

### 2d. `setBusinessSubscription` (`set_business_subscription.js`)

**Intent:** the only path allowed to write paywall fields, now that the client
can't.
**Mechanism:** callable; auth → ownership → validates `tierName` against the
shared `tier_config.js` table → derives `is_premium`/`is_priority_pinned`/
`has_flash_beacon` from the tier → writes via Admin SDK (bypasses rules),
stamping `subscription_updated_at`. Flag values match the historical client
writes exactly.

### 2e. Power Hour start/stop (`power_hour.js`)

**Intent:** the only path allowed to write Power Hour promo fields, enforcing
tier caps server-side.
**Mechanism:** two callables. `startPowerHour` runs in a transaction:
auth → ownership → per-tier duration cap + rolling 7-day weekly-frequency
limit (from a server-side `POWER_HOUR_LIMITS` table) → writes
`has_flash_beacon`/`flash_beacon_expires_at`/`flash_beacon_duration_minutes`/
`power_hour_usage_count`/`power_hour_last_reset` via Admin SDK. On the weekly
limit it throws `resource-exhausted` with the per-tier upgrade message.
`stopPowerHour` clears `has_flash_beacon` only.

### 2f. Beacon expiry (`check_and_expire_beacons.js`)

**Intent:** auto-end expired Power Hour promos.
**Mechanism:** cron every 5 minutes; batch-flips `has_flash_beacon:false`
where `flash_beacon_expires_at < now`.

### 2g. Business Kindex calc (`lib/custom_code/actions/calculate_real_time_kindex.dart`)

**Intent:** map a new star rating to a business score delta.
**Mechanism:** tier-aware baselines/ceilings (standard 500/750, premium
850/900), treats `0.0` as "unset", applies a delta by stars (5→+15, 4→+5,
3→0, 2→−5, 1→−15), clamps to the tier ceiling. Separate from the customer
scoring function in 2b — **two scoring systems share the "Kindex" name.**

### 2h. Generic proxy + auth cleanup (`firebase/functions/index.js`)

`ffPrivateApiCall` (v1 callable) and `ffPrivateApiCallV2` (v2 `onRequest` with
manual CORS + Bearer verification) proxy FlutterFlow private API calls.
`onUserDeleted` is an Auth `onDelete` trigger that deletes the user's
`users/{uid}` document.

---

## 3. Authentication & Security

Identity is Firebase Auth. Authorization lives in `firestore.rules` plus the
callable-function checks. All four findings from the security audit are
remediated on this baseline:

| Finding | Prior state | Current defense |
|---|---|---|
| **1 — Paywall/trust fields client-writable** | Owner could write any field (self-verify, self-upgrade, rank-manipulate) | `businesses` update gated by `diff().affectedKeys().hasOnly(mutableBusinessFields())`; paywall/trust/rank fields are absent from the allowlist → server-only. Tier changes go through `setBusinessSubscription`. |
| **2 — Self-grantable admin** | `is_admin` self-writable → unlock admin reads | `users` create can't set `is_admin:true`; update rejects any write touching `is_admin`. Makes every `is_admin`-gated read real. |
| **3 — Open create/read collections** | 6 collections `create:true, read:true` | `activity_logs` (shape + identity-checked create, admin read), `agency_queue`/`analytics_daily` (create closed), `legal_metadata` (create closed, public read kept for pre-signup), `entitlements`/`uservisits` (fully locked). |
| **4 — Unvalidated business creates** | Create only checked auth | Create requires `owner_ref == self`; the orphan create in `business_sign_up` was removed. |

**Sound pre-existing patterns:** `UserEngagementEvents`, `reviews`,
`ticker_registry`, `exchange_posts`, and `signup_feed` all use
`request.resource.data` field validation and owner-scoping correctly.

### Open items (tracked, not yet closed)

1. ~~**Power Hour tier caps are client-enforced.**~~ **RESOLVED** — Power Hour
   is now server-side (`power_hour.js`); the fields were removed from
   `mutableBusinessFields()`, so the client can no longer write them.
2. **RevenueCat purchase is trusted, not verified.** `setBusinessSubscription`
   confirms ownership but assumes the client completed the purchase. Full
   closure = a RevenueCat webhook or server-side subscriber lookup before
   writing paid tiers.
3. **Elite Growth perma-beacon (pre-existing parity quirk).** Elite upgrades
   set `has_flash_beacon:true` with no `flash_beacon_expires_at`;
   `checkAndExpireBeacons` skips docs missing that field, so it never
   auto-clears.
4. **Historical secret in git history.** The Gemini key formerly hardcoded in
   `lib/backend/gemini/gemini.dart` is now `--dart-define`/server-secret, but
   remains in history — rotate if not already done.

---

## 4. UI / State Management

**Pattern:** each FlutterFlow page has a `*Model`; `onPressed` handlers call a
`KinServices` method, `await` the `ServiceResult`, and show a SnackBar on
`!isSuccess`. State reaches the backend three ways:

1. **Service call (writes):** e.g. Business Setup → `registerBusiness()` writes
   `businesses` + updates the user's `ownedBusiness`, then refreshes
   `currentUserDocument` so gated pages see the new business immediately.
   Merchant Pricing → `upgradeBusinessTier()` → RevenueCat →
   `setBusinessSubscription`.
2. **Engagement events (fire-and-forget):** UI actions drop a
   `UserEngagementEvents` doc; the Cloud Function performs the real state
   change asynchronously; the ticker updates via stream.
3. **Stream builders (reads):** pages subscribe to `query*Record` streams and
   rebuild live (onboarding ticker, directory).

**Gatekeepers:** route-level `requireAuth` (only `TheExchange` uses it)
redirects to `/onboardingSelectionCard`; page-level checks such as the
Executive Dashboard's `isAdmin != true` guard on load; and the Business Setup
register button's inline Terms-of-Service consent.

**Role model:** there is no `role`/`userType` field. A user is a business
owner iff `ownedBusiness` is set; onboarding branches purely by which page the
selection card pushes (`CustomersignupPage` vs. `BusinessSetupPage`).

---

## 5. Glossary & Terminology

| Term | Meaning |
|---|---|
| **Kindex** | Proprietary engagement score. Two implementations: customer scores via `processUserEngagementEvent` → `KindexScores`; business scores via `calculateRealTimeKindex` → `businesses.kindex_score`. |
| **Ticker symbol** | 5-char alphanumeric stock-style handle. Businesses dedupe by query; customers reserve via `ticker_registry`. |
| **kindex_velocity** | Business score trend; drives the ticker's up/down arrow. |
| **Power Hour / Flash Beacon** | Time-boxed promo (`has_flash_beacon` + `flash_beacon_expires_at`); tier-capped; cron-expired. |
| **subscription_tier** | `Community` (free), `Founding Local`, `Pro Growth`, `Elite Growth`. Gates Power Hour + AI. Server-written only. |
| **`mutableBusinessFields()`** | Rules helper: the allowlist of business fields an owner may edit client-side. Everything else is server-controlled. |
| **`tier_config`** | The single per-runtime source of truth for tier attributes: `firebase/custom_cloud_functions/tier_config.js` (server, authoritative) + `lib/services/tier_config.dart` (client, display-only mirror). Holds entitlement flags, Power Hour caps, and AI entitlement per tier. |
| **`setBusinessSubscription`** | Cloud Function; the only path allowed to write tier/paywall fields. Reads flags from `tier_config.js`. |
| **ownedBusiness** | User→business link. This is how "role" is implemented — there is no explicit `role` field. |
| **owner_ref** | Business→user pointer; the basis of every ownership authorization check. |
| **The Exchange** | Verified-business social feed (`exchange_posts`). |
| **Entitlement** | Server-side "is this business allowed feature X" check (AI orchestrator, tier flags). |
| **ServiceResult<T>** | The `{data, error, isSuccess}` wrapper every `KinServices` method returns. |
| **is_claimed / claim_requests** | Imported unclaimed directory businesses vs. owner-claimed ones. |
| **weight_version** | Stamp of which `scoring_weights` snapshot scored an engagement event. |
| **_ensureDevBypassBusiness** | `main.dart` dev-only helper that seeds a real test business for the bypass account (idempotent). |

---

## 6. Known Technical Debt / Cleanup Candidates

- **Two "Kindex" systems** under one name (customer Cloud Function vs. business
  Dart action), with different baselines and update paths — easy to conflate.
- ~~**Tier list duplicated** across four files.~~ **RESOLVED** — tier
  attributes (flags, Power Hour caps, AI entitlement) are now consolidated
  into one table per runtime: `firebase/custom_cloud_functions/tier_config.js`
  (server, authoritative) and `lib/services/tier_config.dart` (client,
  display-only mirror). The two are kept in agreement by hand (a literal
  can't cross the Node/Dart boundary); a parity check confirms they match.
  RevenueCat package IDs remain in `merchant_pricing_suite_widget.dart` as a
  deliberately separate concern (product mapping, not tier policy).
- **Role inferred, never stored** — any future "switch account type" feature
  must account for the fact that role = "has `ownedBusiness`".
- **Repo dead weight:** ~90 `lib/old_designs/` components, 27 `.old` files,
  `migration_data.json` (~536 KB), a ~200 KB directory CSV, and
  `flutter_01/02.log` are all committed.
- **`app_builder_concept/` demo pages** read `agency_queue` but are not
  reachable from any route (no `pushNamed` to them) — orphaned demos.
