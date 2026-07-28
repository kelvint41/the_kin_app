# KIN App Service Blueprint

This documents `lib/services/kin_services.dart`, the service layer wrapping
this app's Firebase-backed button actions.

## Pattern

Every method on `KinServices`:
1. Checks auth/input preconditions up front (e.g. is the user signed in).
2. Wraps its Firebase call in a `try`/`catch`.
3. Returns a `ServiceResult<T>` instead of throwing, so an `onPressed`
   handler never needs its own try/catch and can't crash the app.

```dart
class ServiceResult<T> {
  const ServiceResult.success([this.data]) : error = null;
  const ServiceResult.failure(this.error) : data = null;

  final T? data;
  final String? error;

  bool get isSuccess => error == null;
}
```

Typical call site:

```dart
onPressed: () async {
  final result = await KinServices.submitReview(
    businessRef: businessRef,
    rating: _model.ratingBarValue ?? 0,
    reviewText: _model.textController.text,
  );
  if (!result.isSuccess && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.error!)),
    );
  }
},
```

## Methods

| Method | Signature | Firestore effect |
|---|---|---|
| `submitReview` | `({businessRef, rating, reviewText})` | Creates a `ReviewsRecord` |
| `generateUniqueTicker` | `({businessName, maxAttempts = 3})` | Business tickers. Read-only: queries `businesses` for `ticker_symbol` collisions. No write. |
| `generateUniqueUserTicker` | `({userRef, displayName, maxAttempts = 3})` | Customer tickers. Reserves against `ticker_registry` (see Kindex Ticker Engine) rather than querying `users`, which can't be queried client-side. |
| `sanitizeTicker` | `(raw)` | Pure function, no Firestore access - uppercases/strips to alphanumeric, returns null unless exactly 5 chars |
| `registerBusiness` | `({category, businessType, isBlackOwned, place, businessName, phoneNumber, email, website, description})` | Generates a ticker via `generateUniqueTicker`, then creates a `BusinessesRecord` (including `tickerSymbol`); links it to the caller's `ownedBusiness` |
| `upgradeBusinessTier` | `({businessRef, packageId, tierName, isPremium, isPriorityPinned, hasFlashBeacon})` | RevenueCat purchase, then updates `BusinessesRecord` only on a confirmed purchase |
| `downgradeToCommunity` | `({businessRef})` | Resets `BusinessesRecord` to the free Community tier |
| `fetchTopBusinessKindex` | `({limit = 20})` | Read-only: top `businesses` by `kindex_score`, for the onboarding Kindex ticker's business row. |
| `fetchTopCustomerKindex` | `({limit = 20})` | Read-only: top `KindexScores` by `score`, for the ticker's customer row. |
| `shareApp` | `({text, sharePositionOrigin, businessRef})` | Opens the native share sheet, then creates a `share_app` `UserEngagementEventsRecord` (best-effort) |
| `startPowerHour` | `({businessRef, durationMinutes})` | Sets `has_flash_beacon`, `flash_beacon_expires_at` (computed client-side), `flash_beacon_duration_minutes` on `BusinessesRecord` |
| `stopPowerHour` | `({businessRef})` | Clears `has_flash_beacon` on `BusinessesRecord` |

## Button map

| Button | File | Service call |
|---|---|---|
| "Submit Review" | `pages/business_profile_v2/business_profile_v2_widget.dart` | `KinServices.submitReview` |
| "Register Now" | `pages/business_setup_page/business_setup_page_widget.dart` | `KinServices.registerBusiness` |
| Community tier card | `pages/merchant_pricing_suite/merchant_pricing_suite_widget.dart` | `KinServices.downgradeToCommunity` |
| Founding Local / Pro Growth / Elite Growth tier cards | `pages/merchant_pricing_suite/merchant_pricing_suite_widget.dart` | `KinServices.upgradeBusinessTier` |
| "Promote" | `pages/owner_profile/owner_profile_widget.dart` | `KinServices.shareApp` |
| Power Hour panel Start/Stop | `components/power_hour_panel_widget.dart` (used by `pages/owner_profile/owner_profile_widget.dart`) | `KinServices.startPowerHour` / `stopPowerHour` |
| "Launch Power Hour Blast" | `mobile_called_power_page/mobile_called_power_page_widget.dart` | `KinServices.startPowerHour` |
| Onboarding Kindex ticker (top-of-screen marquee) | `pages/onboarding_selection_card/onboarding_selection_card_widget.dart` -> `components/marquee_ticker_widget.dart` | `KinServices.fetchTopBusinessKindex` + `fetchTopCustomerKindex` |

## Power Hour

`components/power_hour_panel_widget.dart` replaces what was an empty placeholder
in Owner Profile's "Active Promotion" section. It reuses backend
infrastructure that already existed before this feature: `has_flash_beacon`
and the scheduled Cloud Function `checkAndExpireBeacons`
(`firebase/custom_cloud_functions`, runs every 5 min) that flips
`has_flash_beacon` back to `false` once `flash_beacon_expires_at` passes -
no new Cloud Function was needed, only the two new schema fields
(`flash_beacon_expires_at`, `flash_beacon_duration_minutes`) that
`checkAndExpireBeacons` already referenced but the Dart client couldn't
read/write.

The countdown is computed client-side from `flash_beacon_expires_at` via
a local `Timer.periodic`, not a Firestore read on a loop. Stopping early
is confirm-gated (an `AlertDialog`); starting isn't, since an accidental
early stop mid-promotion is the costlier mistake.

`startPowerHour` gates on `subscription_tier` - real values as written by
`merchant_pricing_suite_widget.dart`'s upgrade flow, not generic
Community/Pro/Elite names:

| Tier | Duration cap | Weekly limit |
|---|---|---|
| Community | 30 min | 1 |
| Founding Local | 45 min | 2 |
| Pro Growth | 60 min | 3 |
| Elite Growth | 90 min | unlimited |
| anything else (typo, ad-hoc value like `Founder`/`unlimited`) | 30 min | 1 (fails safe to Community's limits) |

The requested duration is silently capped, not rejected. The frequency
check uses a rolling 7-day window (`power_hour_last_reset` +
`power_hour_usage_count`), not a fixed calendar week.

`KinServices.powerHourDurationCapMinutes(tier)` exposes the same cap
table for UI use (duration pickers, slider validation) without
duplicating it - used by both `power_hour_panel_widget.dart` and
`mobile_called_power_page_widget.dart`.

### mobile_called_power_page - a second, previously-disconnected UI

`mobile_called_power_page_widget.dart` ("Power Hour Blast") was a
pre-existing, independent page that wrote to a completely different
collection (`ExchangePromotionsRecord`), had no tier-awareness, hardcoded
1/3/5-**hour** duration options, and a cost calculation that multiplied a
`String` by an `int` (`sliderValue!.toString() * 35`, which repeats the
string rather than computing anything - not really a `$888` placeholder,
just a garbled string that looked like one). It's registered as a route
(`/mobileCalledPowerPage`) but nothing in the app navigates to it.

Consolidated onto the real system: it now reads `subscription_tier` from
the same `BusinessesRecord` stream, shows one duration chip matching the
tier's cap (via `powerHourDurationCapMinutes`), a slider (5-90 min) that
clamps to the tier cap with a SnackBar on exceed, a real
`_calculateTotalCost` ($10 per 30 min, prorated), and calls
`KinServices.startPowerHour` on launch instead of writing to
`ExchangePromotionsRecord`. Also removed a stray `InkWell` around the
"Blast Message" label that wrote an `ExchangePromotionsRecord` on tap of
the label itself - unrelated to any real action, looked like leftover
miswired FlutterFlow generation.

Note: this app already has its own Exchange system (`exchange_posts`,
`exchange_promotions` collections). A separate Exchange gate/reactions
design (`exchange_profiles`, `exchange_conversations`, `sendReaction`,
`sendExchangeMessage`, `setupExchangeProfile`) exists in a parallel
checkout but was deliberately not ported here to avoid clashing with this
app's existing Exchange implementation and in-progress work on it.

## Kindex Ticker Engine

`registerBusiness` automatically assigns a unique 5-character alphanumeric
ticker symbol to every new business:

1. `generateUniqueTicker` first tries a **semantic** candidate derived
   from the business name (e.g. 'Rollin Smoke BBQ' -> `ROLLI`): filler
   words ('LLC', 'Inc', 'Co', 'The') and punctuation/spaces are stripped,
   and the first 5 remaining characters are used. If that candidate is
   unclaimed, it wins.
2. If the name yields fewer than 5 characters after stripping, or the
   semantic candidate is already taken, it falls back to a random
   5-character candidate from `A-Z0-9`, retrying up to 3 times (e.g.
   `KIN01`).
3. If all 3 random attempts also collide, `registerBusiness`
   short-circuits and returns `ServiceResult.failure('Could not generate
   a unique ticker symbol. Please enter one manually.')` **before**
   creating the business document - nothing is written without a ticker
   assigned. The existing "Register Now" `onPressed` already surfaces any
   `ServiceResult.failure` via a SnackBar, so this error reaches the user
   with no extra wiring; building the manual-entry retry UI itself is a
   separate follow-up.
4. `sanitizeTicker` is exposed separately (uppercase, strip to
   alphanumeric, require exactly 5 characters) so that future manual-entry
   UI can validate user input with the exact same rules the generator
   uses.

Note: this semantic-first logic only applies going forward, to new
`registerBusiness` calls. The 498 businesses bulk-imported from
`National_Directory - San_Antonio_TX_Directory.csv` (see
`migration_data.json` / `firebase/scripts/import_businesses.js`) already
have randomly-generated tickers and were not retroactively changed. That
import already ran against the live `kinvest-build-app` Firestore project;
`firebase/scripts/import_businesses.js` is kept here for traceability, not
for re-running.

### Customer tickers

Customers get the same 5-character ticker concept, assigned once at
signup (`maybeCreateUser` in `backend.dart`), but through a different
mechanism than businesses:

- The `users` collection's Firestore rule only allows reading your own
  doc (`allow read: if request.auth.uid == document`), so it can't be
  queried for a `ticker_symbol` collision check the way `businesses` can.
- Instead, tickers are reserved in a dedicated `ticker_registry`
  collection, keyed by the ticker itself. Writing to a free ticker's doc
  ID is a Firestore `create` (allowed); writing to an already-taken one
  is an `update` against an existing doc, which the rule blocks
  (`allow update: if false`). This makes reservation atomic without a
  transaction. See `KindexTickerUtil.reserve` in
  `lib/flutter_flow/kindex_ticker_util.dart`.
- Unlike business registration, a failed ticker reservation never blocks
  account creation - the user just ends up with no `ticker_symbol` and is
  skipped by `fetchTopCustomerKindex` until one exists.
- `ticker_symbol` and a `is_trending_up` flag (whether the customer's most
  recently processed engagement event added or subtracted Kindex points)
  are denormalized onto each `KindexScores/{userId}` document by the
  `processUserEngagementEvent` Cloud Function
  (`firebase/custom_cloud_functions/kindex_engine.js`), since that
  collection has no display data of its own and `users` can't be queried
  client-side either. **This Cloud Function change has been edited
  locally but not yet deployed** - it needs `firebase deploy --only
  functions:custom_cloud_functions` (or the equivalent full functions
  deploy) before `fetchTopCustomerKindex` will return any real rows;
  until then customers just won't have a `ticker_symbol` and the
  ticker's customer row will be empty.

### Known issue: business trend is not real

`fetchTopBusinessKindex` derives `isTrendingUp` from
`BusinessesRecord.kindexVelocity`, but **nothing writes to
`kindex_velocity` anywhere in this codebase** - it's a schema field with
no writer, so it reads as its default (0) for virtually every business,
meaning the business row's trend arrow always shows "up" today. This was
discovered while building the customer side (which does compute a real
trend) but was left as-is since the business ticker row was explicitly
scoped as "keep as is." Fixing it properly would mean deciding where
business Kindex scoring should actually happen - since resolved: see
`business_kindex_engine.js` in the "Kindex formulas" section below, which
now updates `businesses.kindex_score` automatically on review creation.
`kindex_velocity` still has no writer - deliberately left alone rather
than filled with a placeholder value - so this trend-arrow issue is
unchanged for now; a real velocity metric is tracked as separate future
work.

## Exchange Feed & Kindex Spotlight

`the_exchange_widget.dart` (per-business Exchange page) was overhauled from
an Instagram-card feed into a social-feed-style layout:

- Wrapped `Scaffold.body` in `SafeArea` so the header clears the
  notch/camera.
- The `exchange_posts` `StreamBuilder` (queries by `business_ref`, already
  existed) was clipped inside a stray fixed `height: 120.0` `Container` -
  a real layout bug, not intentional. Removed; the feed now sizes to
  content inside the page's own scroll view.
- New component `lib/components/exchange_feed_item_widget.dart` replaces
  `RefinedPostWidget` (old_designs, Instagram-style) for feed rows: a dark
  card matching the existing header visual language (avatar, bold name,
  theme-token colors), post text/image, and a per-post **Quick Reactions**
  row (❤️🙌🏾🔥✨👏🏾).
- Quick Reactions write a `UserEngagementEventsRecord` per user+post+type
  at a **deterministic doc id** (`{uid}_{postId}_{eventType}`), exactly
  mirroring `RefinedPostWidget._handleLike`'s dedup pattern - a repeat tap
  is rejected server-side (`exchange_posts`/`UserEngagementEvents` rules
  are create-only, no update/delete) and the failure is swallowed. The
  event types (`react_love`/`react_praise`/`react_fire`/`react_sparkle`/
  `react_applause`) were already seeded into `kindex_config/scoring_weights`
  earlier, so reactions score Kindex points immediately - no Cloud
  Function change needed.
- **No aggregate reaction/like counts are shown.** `exchange_posts` and
  `UserEngagementEvents` are both `allow write: if false` /
  self-read-only respectively, so a post's total reaction count can't be
  computed client-side (an authenticated user can only read *their own*
  engagement events, not aggregate across all users on a post). Showing a
  real count would need a Cloud Function to denormalize a counter onto
  the post doc, admin-write, same shape as `kindex_engine.js` but not
  built. Each reaction button instead just highlights once the current
  session's user has tapped it.
- Post creation (both the header "+" dialog and the bottom composer bar)
  now also logs a `UserEngagementEventsRecord` with `event_type: 'post'`
  targeting the new post - previously posting only wrote the
  `ExchangePostsRecord` itself and never contributed to the author's
  Kindex score, even though `'post': 10` has been in the seeded weights
  map since the config was first created.
- New component `lib/components/kindex_spotlight_widget.dart`: a compact
  "Kindex Spotlight" preview card placed between the page header and the
  feed. Tapping it opens a modal bottom sheet with two `RankCardWidget`
  lists - "Top Business Owners" (`KinServices.fetchTopBusinessKindex`)
  and "Top Customers" (`KinServices.fetchTopCustomerKindex`) - reusing the
  two ranking queries already built for the onboarding ticker rather than
  adding a third. Per-user Kindex score is also now shown inline as a
  small gold pill next to each poster's name in the feed
  (`_KindexScoreBadge` inside `exchange_feed_item_widget.dart`), reading
  `KindexScores/{uid}` directly (guarded for the common case where a new
  user has no score doc yet - `KindexScoresRecord.getDocument` would
  otherwise throw on a non-existent doc).
- **Depends on the not-yet-deployed Cloud Function change noted above**:
  until `kindex_engine.js`'s `ticker_symbol`/`is_trending_up`
  denormalization ships, `fetchTopCustomerKindex` returns an empty list
  (every `KindexScores` doc has a blank `ticker_symbol`, so the row is
  filtered out) - meaning the Spotlight's "Top Customers" half, and the
  feed's inline score badges for customers, will show nothing until that
  deploy happens. "Top Business Owners" is unaffected by that deploy, but
  inherits the pre-existing "trend is not real" issue above (`kindex_score`
  itself is also only ever set by manual/admin writes today, so most
  businesses will show a flat/tied score until real business-side Kindex
  scoring is built).
- Comments are out of scope: there is no comment schema/collection
  anywhere in the app (`RefinedPostWidget`'s comment icon was always a
  stub). "Tied to posts/comments" in the request was implemented for
  posts only.
- Spotlight leaderboard rows are now tappable: `KindexTickerEntry` gained
  an optional `businessRef` (set by `fetchTopBusinessKindex`, left null by
  `fetchTopCustomerKindex` since a customer has no business profile to
  link to). Tapping a "Top Business Owners" row navigates to
  `BusinessProfileV2Widget` with `businessDocument` serialized, matching
  the exact convention used elsewhere (`business_showcase_widget.dart`'s
  "View Showcase"). "Top Customers" rows stay inert - no target page.

## Business Profile V2 - finalized as the Business Owner view

`business_profile_v2_widget.dart` had accumulated several FlutterFlow-scaffold
leftovers that made it feel unfinished. Cleaned up to match its new role as
the dedicated page an owner lands on for their own business:

- Removed the pulsing "Check In Now" button (an unwired `print()`-only
  stub with a looping scale animation - this was almost certainly what read
  as the status indicator "flashing," since it sat directly inside the
  Open/Closed badge). Removed the separate "Check In" button too (also
  unwired to anything persistent - it only mutated local `FFAppState`).
  Removed "Call Now" (`tel:` launch + `call_tap` activity log).
- `isBusinessOpen` (`lib/flutter_flow/custom_functions.dart`) was checked
  and found already correct - proper 12-hour parsing, overnight-hours
  handling, fail-safe-to-closed on bad data. No logic bug found; the
  "flashing" was visual (the animated button above), not a status
  miscalculation.
- "Open in Maps" had a real bug: `launchMap(address: '', title: '')` -
  hardcoded empty strings, so it opened Maps with no location. Fixed to
  pass the business's real `address`/`businessName`.
- "Order on KIN" (the delivery-options entry point) was silently broken:
  it re-queried `businesses` filtered by a `business_ref` field equal to
  the business's own reference - a field that's essentially never set in
  practice (confirmed via grep - no write site sets it), so the query
  always returned zero docs and the button rendered as an empty
  `Container()`, invisible. This is why delivery felt "removed" - the
  DoorDash/UberEats/Grubhub buttons themselves were already fully built
  and wired to `businessDoc.doordashUrl`/`ubereatsUrl`/`grubhubUrl` in
  `lib/components/clean_elegant_mobile_widget.dart`, just unreachable.
  Fixed by passing the already-loaded `businessProfileV2BusinessesRecord`
  (from the page's own outer `StreamBuilder`) directly instead of
  re-querying - deleted the broken nested `StreamBuilder` entirely.
- Added a "Manage Your Business" row (`ActionBtnWidget`, matching
  `owner_profile_widget.dart`'s existing action-row visual style) linking
  to `BusinessSetupPageWidget` (edit profile/hours), `MerchantPricingSuiteWidget`
  (manage pricing/subscription), and `OwnerProfileWidget` (owner
  dashboard). Gated behind `businessProfileV2BusinessesRecord.ownerRef ==
  currentUserReference` - this page is also reached by non-owners via
  `business_showcase_widget.dart`'s "View Showcase" button, so the
  management row only renders for the actual owner.
- Removed now-dead animation scaffolding (`animationsMap`,
  `TickerProviderStateMixin`, the `flutter_flow_animations`/
  `flutter_animate` imports) that existed solely to drive the removed
  Check-In-Now pulse.
- "Order on KIN" (delivery) is now gated to food-service businesses only,
  via a new `_isFoodServiceBusiness(category)` keyword match in
  `business_profile_v2_widget.dart`. There's no dedicated boolean for
  this: `BusinessesRecord.is_delivery_eligible` exists in the schema but
  has no writer anywhere in the app, so gating on it today would hide the
  row for every business. `category` is the only populated signal, and it
  comes in two shapes - `business_setup_page`'s fixed 5-value dropdown
  (`'Restaurant & Food'`, etc.) for new signups, vs. free-text
  Google-Places-style strings (`'Barbecue restaurant'`, `'Bakery'`) on the
  498 bulk-imported businesses - hence a substring/keyword match rather
  than an exact-value check. If `is_delivery_eligible` ever gets a real
  writer (e.g. an owner-facing toggle next to the delivery URL fields in
  `business_setup_page_widget.dart`), that would be the more precise
  signal to switch to.

## Theme Token Audit (Light/Dark consistency)

`lib/flutter_flow/flutter_flow_theme.dart` is the actual source of truth
(not FlutterFlow's settings screenshots) - `FlutterFlowTheme.of(context)`
returns `LightModeTheme()`/`DarkModeTheme()` based on `Theme.of(context)
.brightness`. Confirmed the given palette matches code exactly for
Primary/Secondary/Tertiary/Alternate/Text/Background/Success/Error/
Warning/Info/Accent1. Accent2/Accent3/Accent4(dark) in the given palette
don't match the code's 8-digit ARGB values (different hues entirely, not
rounding) - per user decision, kept the existing code values since they
carry an alpha channel a 6-digit hex can't represent and are low-traffic
overlay colors, not backgrounds/text.

**Critical fix**: `LightModeTheme.primaryText` was `#D4AF37` (the same
bright gold as dark mode) - since `primaryText` is the default color for
nearly every typography style, this gave **2.05:1 contrast** against
`primaryBackground` (#FCFCFC), failing WCAG AA at every text size (needs
4.5:1 normal / 3:1 large). This was in the design system itself, not a
code bug - confirmed by the user's own palette table listing the same
gold for both modes. Fixed by deepening light-mode `primaryText` to
`#7D5F16`, chosen to land at ~4.8:1 (a "dark goldenrod" that still reads
as gold, not black) - deliberately matched to the ~5.8:1 contrast the app
already relies on for gold-on-dark-green elsewhere, rather than picking
an arbitrary safe value. Dark mode is unchanged.

**Fixed - `owner_profile_widget.dart` and `merchant_pricing_suite_widget.dart`**
used `FlutterFlowTheme.of(context).primary` (dark green, identical in
both modes) as their Scaffold `backgroundColor` instead of
`.primaryBackground` - a full-screen green page in light mode that never
adapted to dark mode either. `owner_profile_widget.dart`'s original
FlutterFlow build-prompt (still in the file's doc comment) explicitly
specified "dark forest green primary background... and white text" -
this was the original design intent, not a mistake, but superseded by
this audit's instruction to unify all pages on the shared adaptive
tokens. Fixing the background alone would have broken these pages, since
their `Colors.white` text and `#242424`-hardcoded "premium dark cards"
were tuned only for that fixed dark backdrop - once the background
became adaptive, gold/white text and dark-hardcoded cards would clash or
go invisible in light mode. Full fix in `owner_profile_widget.dart`:
Scaffold backgrounds → `.primaryBackground`; section-header text
(`Colors.white`) → `.primaryText`; the three "premium" card backgrounds
(K-Index Score, Power Hour, Membership Tier - all hardcoded `#242424`) →
`.secondaryBackground`, so the `.primaryText` icons already inside them
stay correctly paired with an adaptive surface instead of a fixed-dark
one; a paywall lock-overlay background → `.secondaryBackground` at the
same alpha; a muted caption color (`#999999`) → `.hint` (the token
already used for this role elsewhere in the app); a gold badge/border
(`#33D4AF37`) → `.accent1.withAlpha(51)` (identical color, token-derived
instead of magic hex). Left two `Colors.white` instances untouched
intentionally: button text on a solid gold fill, and the hero business
name sitting on the page's own dark image-gradient scrim - both are
correct regardless of app theme mode, matching the same hero-scrim
pattern used correctly elsewhere (`the_exchange_widget.dart`,
`business_profile_v2_widget.dart`).

### Found but explicitly out of scope for this pass

- **Loading spinners app-wide** use `FlutterFlowTheme.of(context).primary`
  (dark green) as their `CircularProgressIndicator` color, which is
  ~1.5:1 contrast against `primaryBackground`/`secondaryBackground` in
  dark mode - close to invisible. This is consistent across ~20+ files,
  not specific to the two pages fixed here, so fixing it in only one
  place would create a new inconsistency rather than resolve one. Needs
  its own pass across every spinner call site (recommend `.secondaryText`,
  which is legible against both background tokens in both modes).
- `lib/components/marquee_ticker_widget.dart`'s root `Container` is
  hardcoded `Colors.black` - a full-width, always-visible band on the
  onboarding screen. Could be intentional "stock ticker" styling; flagged
  for a design decision rather than changed.
- `lib/old_designs/premium_story/premium_story_widget.dart` and
  `refined_post_widget.dart` use hardcoded `Colors.black` for their
  full-screen image-viewer dialogs - conventional for a lightbox, but not
  theme-token-driven.
- `lib/old_designs/exchange/exchange_widget.dart` and
  `lib/old_designs/digital_loyalty_card/digital_loyalty_card_widget.dart`
  have multiple hardcoded dark-green/charcoal full-width backgrounds, but
  are confirmed unreachable (never instantiated outside their own file) -
  only worth cleaning up if revived.
- `lib/sign_in_page/`, `lib/legal_pages/`, `lib/dynamic_pages/`,
  `lib/app_builder_concept/`, `lib/business_showcase/`,
  `lib/mobile_sign_up_page/`, `lib/customersignup_page/`,
  `lib/mobile_called_power_page/`, `lib/clean_premium_dark_page/` were
  not covered by this audit (outside `lib/pages`/`lib/old_designs`/
  `lib/components`) - a follow-up pass would need to include them for
  full route-graph coverage.

## Kindex formulas (as of this audit)

Three separate systems currently calculate "Kindex" - the first two now
both write to Firestore in production automatically; the third remains
dead code.

**1. Live event-weight engine** - `firebase/custom_cloud_functions/kindex_engine.js`,
`processUserEngagementEvent`. Triggered on `UserEngagementEvents/{id}`
document creation. Inside a transaction: looks up `weights[event.event_type]`
from `kindex_config/scoring_weights` (5-minute in-memory cache), rejects
unknown event types, then `KindexScores/{userId}.score += points`. Scores
**individual users** (customers and owners as people), not businesses.
Live weights as of this audit:

| event_type | points | event_type | points |
|---|---|---|---|
| post | 10 | comment | 2 |
| share_app | 10 | map_tap | 2 |
| call_tap | 5 | like | 1 |
| share | 5 | page_view | 1 |
| react_love/praise/fire/sparkle/applause | 1 each | | |

"Velocity" in this system is only `is_trending_up` - a boolean, whether
the last processed event added or subtracted points. No percentage, no
decay, no rolling window exists today.

**2. `BusinessesRecord.kindex_score` / `kindex_velocity`** - the fields
actually displayed everywhere (business cards, the ticker, the
leaderboard). `kindex_score` now has a real automated writer: see
`firebase/custom_cloud_functions/business_kindex_engine.js`,
`processBusinessReview`, below. `kindex_velocity` still has no writer -
it's intentionally left untouched by the new function rather than filled
with a placeholder sign-based value (see "Proposed velocity metric"
below) - so it still reads as its default (0) for every business.

**3. `lib/custom_code/actions/calculate_real_time_kindex.dart`** -
`calculateRealTimeKindex(currentScore, newStarRating, isPremiumBusiness)`.
A real formula: baseline 500 (or 850 premium) when `currentScore == 0`,
otherwise `±15` for 5-star / `±5` for 4-star / `-5` for 2-star / `-15` for
1-star (3-star neutral), clamped to a tier ceiling (750 standard / 900
premium). Its original call site (`business_profile_v2_widget.dart`, the
"Customer Reviews" header tap) stores the result in local model state and
never persists it - still decorative, still dead code, left untouched.
The formula itself has been ported (not moved) into
`business_kindex_engine.js` as the live implementation - see below.

**SUPERSEDED (July 2026): the reactive business engine was replaced by a
nightly recompute.** `business_kindex_engine.js` / `processBusinessReview`
has been deleted. It applied a fixed delta per review with no verified-visit
requirement and no per-customer cap, so one account could move a score
without bound by submitting repeated reviews. Business scoring now lives in
`business_kindex_nightly.js` (`recomputeBusinessKindexScores`, 2am
America/Chicago) plus `visit_verification.js` (`recordVerifiedVisit`
callable). See "Anti-manipulation scoring" below. The description that
follows is retained for history only:

**Former live business-side engine (deleted)** -
`firebase/custom_cloud_functions/business_kindex_engine.js`,
`processBusinessReview`. Triggered on `reviews/{reviewId}` document
creation (the review flow already wired up via
`KinServices.submitReview`), mirroring `kindex_engine.js`'s structure:
inside a transaction, re-reads the review and the target business,
applies the ported `calculateRealTimeKindex` formula (item 3 above) using
the business's current `kindex_score` and `is_premium` flag, writes the
new `kindex_score` plus `last_kindex_review_id` onto the business doc, and
marks the review `status: "processed"` (or `"rejected"` with an `error`
for a missing `business_ref`, non-numeric `rating`, or a business that no
longer exists). Idempotency guard: `reviews` docs have no client-settable
`status` field (unlike `UserEngagementEvents`' `"pending"` convention), so
the guard is simply "does `status` already exist at all" - it's only ever
written by this function, so its presence means the review was already
handled and reprocessing (from an at-least-once redelivery) is a safe
no-op.

**Tests.** `firebase/custom_cloud_functions/test/business_kindex_engine.test.js`
covers this function against the Firestore emulator - the tier
baselines/ceilings, the star deltas, the clamps, the rejection paths, and
the idempotency guard (which can't be verified by reading the code
alone). Run with:

```bash
cd firebase/custom_cloud_functions
npm install       # first time only
npm test
```

`npm test` shells out to `firebase emulators:exec --only firestore`
against a throwaway `demo-kin-test` project, so it needs no credentials
and touches no real data - but it does need Java (the Firestore emulator
is a JAR) and downloads that JAR on first run. `firebase-tools` is a
devDependency here so the suite is self-contained; a global install works
too. Note these tests use the Admin SDK, which bypasses `firestore.rules`
exactly as the deployed function does - so they say nothing about
client-side rule enforcement, including the `kindex_score` write
restriction described above.

### Proposed velocity metric (not yet implemented)

Built for the interactive simulator (see below), not deployed:
`ewma(t) = α·dailyPoints(t) + (1-α)·ewma(t-1)`, displayed as
`(ewma(t) / avgDailyPoints(t) − 1) × 100` - the entity's current daily
scoring pace as a percentage above/below its own running average. `α`
(0.05-0.95) is the tunable "sensitivity": low α smooths out single-day
spikes, high α tracks yesterday's events almost immediately. Implementing
this for real would mean deciding a target (user or business - system 2
has no live writer to hook into) and an update cadence (recomputed every
event, like the score itself, or batched daily via a scheduled function).

### Interactive simulator

Published as a Claude Artifact ("Kindex Velocity Lab") - lets you tune
every live event weight, the velocity sensitivity (α), and pick between
4 scenario presets (dormant/steady/viral spike/declining), then visualizes
score + velocity over a simulated 60-day timeline. Uses the exact live
weight values above as defaults. Not saved to this repo since it's a
standalone HTML tool, not app code - re-generate by asking to rebuild it
from this section's formula if the link is lost.

## App Store screenshot automation

Three pieces, none of which could be run end-to-end in the environment
this was built in - **no iOS Simulator or Android SDK was available**
(only Command Line Tools, not full Xcode). Written carefully against the
app's real widget structure, but treat the first real CI run as the
first real test of this pipeline, not a rerun of something verified.

- **`firebase/scripts/seed_screenshot_demo.js`** - idempotent seed script.
  Creates one demo business (`businesses/screenshot_demo_business`,
  "Rollin' Smoke Kitchen (Screenshot Demo)", category `Barbecue restaurant`
  so the delivery button shows, `kindex_score: 918`, real-looking
  hours/address/delivery URLs), links it as owned by the dev-bypass
  account (`SEED_DEV_UID` env var - required, no default), 4 supporting
  demo businesses with varied `kindex_score` values so the "Top Business
  Owners" leaderboard isn't empty/tied, 3 demo reviewer users with
  `KindexScores` docs so "Top Customers" isn't empty either, 4 demo
  `exchange_posts`, and 3 demo `reviews`. Every demo doc is clearly
  labeled "(Screenshot Demo)" and easy to find/delete. Skips re-seeding
  posts/reviews if they already exist (safe to re-run every CI trigger).
- **`integration_test/app_screenshots_test.dart`** - drives the app via
  the existing dev-bypass mechanism (`DEV_ROUTE` lands directly on either
  `/theExchange` or `/businessProfileV2` with the demo business's ref),
  waits for real content to load (polls rather than a single
  `pumpAndSettle()`, since this is a real network round-trip to Firestore
  in CI), and prints a `KIN_SCREENSHOT_READY: <name>` marker at each
  stable, screenshot-worthy moment - `the_exchange` and (after tapping
  the Kindex Spotlight card) `leaderboard` in the Exchange run,
  `business_profile` in the other. Deliberately does NOT try to capture
  pixels itself - Flutter's in-process screenshot APIs don't reliably hit
  exact device resolutions across platforms.
- **`.github/workflows/screenshots.yml`** - manual-trigger (`workflow_dispatch`)
  workflow on `macos-14` (Xcode + iOS Simulator preinstalled, no local
  install needed). Boots an iPhone 15 Pro Max simulator - whose native
  resolution, 1290×2796, *is* Apple's 6.7" screenshot spec, so no
  resizing step is needed. Runs the integration test in the background,
  tails its log, and fires `xcrun simctl io <device> screenshot` the
  instant each marker appears - a real simulator framebuffer capture, not
  a resized desktop window. Matrix over `theme: [light, dark]` × the two
  routes, uploading PNGs as build artifacts per combination. New
  `_maybeForceThemeMode()` in `main.dart` (gated on `kDebugMode`, same
  safety pattern as the dev bypass) reads a `SCREENSHOT_THEME` dart-define
  so each run boots directly into a specific mode rather than whatever
  the simulator's default appearance happens to be.

**Required GitHub repo secrets** (none of which I can create myself):
`FIREBASE_SERVICE_ACCOUNT_KEY` (base64 of the service account JSON used
elsewhere in `firebase/scripts/`), `DEV_BYPASS_EMAIL`, `DEV_BYPASS_PASSWORD`,
`DEV_BYPASS_UID` (that account's Firebase Auth uid).

**Known gap**: the device name (`iPhone 15 Pro Max`) is hardcoded in the
workflow's boot step; GitHub periodically updates which Xcode/simulator
versions ship on `macos-14`, so this may need updating if the boot step
can't find that device - check `xcrun simctl list devicetypes` in a run.

## AI Marketing Orchestrator

Generates one social media post concept (caption + 3 hashtags + CTA +
image concept) per request, gated to paying businesses.

**Architecture**: entirely server-side. `generateMarketingContent`
(`firebase/custom_cloud_functions/ai_marketing_orchestrator.js`) is a
Firebase callable function - the client (`KinServices.generateMarketingContent`
in `kin_services.dart`) sends `{businessRefPath, theme?}`, Firebase verifies
the caller's ID token before the handler runs (`request.auth` is
trustworthy, unlike anything in the request body), then the function:
checks the caller owns the business (`business.owner_ref` must match
`request.auth.uid`), checks entitlement (`subscription_tier` in `{'Pro
Growth', 'Elite Growth'}`), and only then calls Gemini using an API key
from Firebase Secret Manager (`defineSecret('GEMINI_API_KEY')` - set via
`firebase functions:secrets:set GEMINI_API_KEY`, never shipped to the
client). The existing client-side Gemini wrapper
(`lib/backend/gemini/gemini.dart`) previously had its API key committed
to source and compromised (see the comment at the top of that file) -
this is deliberately not reused for anything entitlement-gated, since a
key embedded in the compiled client isn't a real secret and a client-side
`if (isPremium)` check isn't a real security boundary.

**Entitlement**: same `subscription_tier` field and same two tiers
(`Pro Growth`/`Elite Growth`) the rest of the app already uses for paid
features - no separate "Premium" concept was introduced. There's no
hardcoded business ID or name anywhere in the entitlement path. A specific
business can be comped by setting its `subscription_tier` field directly
(the same mechanism every real upgrade already uses via
`KinServices.upgradeBusinessTier`) - deliberately not implemented as a
special-cased bypass in the middleware, after the requester's own two
messages gave two different spellings of the same business name 30
seconds apart, which is exactly the failure mode a hardcoded exact-string
match would be vulnerable to (typo silently breaks or silently
mismatches). No business named "Hair Madness"/"Hair Maddness" exists in
Firestore as of this write-up; comping it is a one-time Firestore write
once the business is actually registered.

**Prompt structure**: `buildPrompt()` in the same file. Uses Gemini's
structured-output mode (`responseSchema`, not free-text + regex) with a
required 4-field schema (`caption`, `hashtags` - array, `cta`,
`image_concept`), so the response is reliably parseable rather than
occasionally malformed free text. Includes the business's name, category,
and description from Firestore, plus an optional caller-supplied `theme`
(e.g. "weekend brunch special").

**Logging** (`ai_generation_logs` collection, Admin-SDK-write-only,
`allow read, write: if false` in rules - no client path touches it
directly):
- Every call logs `status` (`success`/`error`/`rejected_not_entitled`),
  `latency_ms` (wall-clock time around the Gemini call), `subscription_tier`,
  and `theme` - this is the AI latency + system load data. Rejected
  (not-entitled) attempts are logged too, not just successes, so upgrade-prompt
  friction is visible in the data.
- Successful calls also log `generated_output` (the `caption`, `hashtags`,
  `cta`, and `image_concept` that were actually returned) and `context_used`
  (a snapshot of the `business_name`, `category`, and `description` the
  prompt was built from). Both are `null` on error and rejection. This is
  the content side of the log, as opposed to the health side: the client
  copies the caption to the clipboard and retains nothing, so without this
  the engagement subcollection can record that a suggestion was dismissed
  but not what it said. `context_used` is stored alongside it because the
  business doc is mutable - a caption can't be judged later against a
  description that has since been rewritten. Neither field is
  reconstructable after the fact, which is why they're written on every
  generation rather than added once there's a consumer for them.
- A subcollection (`ai_generation_logs/{id}/engagement`) records what the
  owner did with each suggestion - `used`/`edited`/`regenerated`/`dismissed`,
  via the separate `logAiSuggestionEngagement` callable
  (`KinServices.logAiSuggestionEngagement`, called from
  `ai_marketing_sheet_widget.dart`'s three action buttons) - this is the
  "user engagement with suggested posts" metric, tracked independently of
  whether generation itself succeeded.
- `edited` is recorded instead of `used` when the owner changed the caption
  before using it, and carries `final_caption` (the owner's text, capped at
  5000 chars server-side). Both actions mean the owner posted something;
  only `edited` says the model didn't get there by itself. Paired with
  `generated_output.caption` on the parent doc, this is the closest thing
  available to a direct statement of what a given business actually wants
  its voice to sound like - which is why the caption is editable in the
  sheet at all rather than copy-only. A copy-only flow pushes the rewrite
  into Instagram, where it's invisible and unrecoverable.
- The diff itself is not computed or stored - the original and final text
  are both retained and the diff is derived at analysis time, since any
  diff representation chosen now would likely be the wrong granularity for
  whatever consumes it later.
- "Overall system load" beyond the per-call latency log: Cloud Functions
  already emit invocation count/concurrency/duration to Cloud Monitoring
  automatically, no extra code needed - visible in the Firebase console's
  Functions dashboard. `ai_generation_logs` itself, aggregated by day/hour,
  is a queryable proxy for load if an in-app admin view is wanted later;
  none was built in this pass.

**UI**: `lib/components/ai_marketing_sheet_widget.dart`, opened from a 4th
button ("AI Marketing") added to Business Profile V2's existing "Manage
Your Business" row (owner-only, same gating as the other three buttons
there). Shows the theme input, a Generate button, and - once generated -
the result plus Use This (copies to clipboard) / Regenerate / Dismiss,
each logging the corresponding engagement action. The caption renders as
an editable field (borderless, so it still reads as content rather than a
form) seeded from each generation, including regenerates - stale text
left over from a previous suggestion would otherwise be logged as an edit
of content it didn't come from. Use This copies whatever is in that field,
so editing and using is one action rather than two. Hashtags, CTA, and
image concept remain read-only.

**Not yet wired**: image generation itself (the "image concept" is a text
description for the owner to shoot themselves, not a generated image) and
posting directly to `exchange_posts` from the suggestion (Use This copies
to clipboard rather than opening the composer prefilled - a reasonable
follow-up if this gets used in practice).

## Known follow-ups

- RevenueCat package identifiers in `merchant_pricing_suite_widget.dart`
  (`_kFoundingLocalPackageId`, etc.) are placeholders pending real products
  in the RevenueCat dashboard.
- `registerBusiness` requires `currentUserReference` to be non-null;
  callers should be signed in before "Register Now" is reachable, but the
  method fails gracefully via `ServiceResult.failure` if not.
- No manual-entry ticker UI/service method exists yet - `generateUniqueTicker`
  failing just surfaces an error today, per the explicit ask; building the
  actual manual-input flow is future work.

## Anti-manipulation business scoring (July 2026)

Replaces the reactive `processBusinessReview` trigger, which had no
manipulation protection.

**`visit_verification.js` - `recordVerifiedVisit` (callable).** A review
only counts toward a score if the customer has a GPS-verified check-in for
that business. The client takes a single one-shot location reading (no
background tracking) and calls this function; the radius check happens
server-side against the business's stored coordinates, and the visit is
written with the Admin SDK and a server timestamp. Radius (default 100m)
and a dedup window (default 1h) are tunable from
`kindex_config/visit_verification` without a redeploy.

The collection is **`uservisits`**, not `user_visits` - worth noting because
its rules previously read `allow create: if true`, meaning any caller, even
unauthenticated, could forge a visit. Client writes are now denied outright.

**Limits of GPS verification.** This proves the *reported* coordinates are
in range and makes forgery require deliberately faking a location rather
than just POSTing a document. It cannot prove physical presence - a
mock-location provider on a rooted device still defeats it. Unspoofable
presence needs a venue-side factor (in-store QR, or confirmed purchase).

**`business_kindex_nightly.js` - `recomputeBusinessKindexScores`.** Runs at
2:00am America/Chicago. For every business it takes the trailing 7 days of
reviews, keeps only customers with a verified visit in that window, reduces
each customer to their single highest star rating, and recomputes the score
from the tier baseline using the existing deltas and ceilings. Writes
`kindex_score`, `kindex_last_recomputed_at` and
`kindex_qualifying_review_count`; `kindex_velocity` is deliberately never
touched.

**Behavioural consequence worth knowing:** because the score is recomputed
from scratch each night over a 7-day window, it is now a rolling measure
rather than a running total. A business with no qualifying reviews in the
window sits exactly at its baseline (500 standard / 850 premium) rather
than retaining points earned earlier. That follows from the spec's
"recompute from scratch", but it means scores decay toward baseline instead
of accumulating.

**Owner self-farming is blocked at three layers.** An owner checking in to
their own business would make their own review count toward their own
score, so: the check-in control is hidden for the owner on their own
profile; `recordVerifiedVisit` refuses a check-in whose caller matches the
business's `owner_ref`; and the nightly recompute drops the owner's review
outright regardless of whether a verified visit exists. The nightly gate is
the authoritative one - it decides scoring directly, so it holds even for
visits recorded before the callable check existed, or written directly back
when `uservisits` was still client-writable. The UI gate alone would be
bypassable by invoking the callable directly.

**Reviews use composite ids** (`{businessId}_{userId}`), so re-submitting
edits a customer's existing review rather than creating duplicates. Rules
allow owner updates with a 2-edit cap - anti-spam only; score integrity
comes from the nightly rules, not the cap. Grouping by customer in the
nightly job also means legacy duplicate review documents cannot double-count.

Tests: `test/business_kindex_nightly.test.js` (21 cases, emulator-backed),
covering the manipulation scenarios directly - repeat reviews from one
account, competitor 1-star farming, unverified reviews, window boundaries.

## Kindex smoothing & decay (Phase 2, July 2026)

Layered on top of the anti-manipulation redesign. Config lives in
`kindex_config/scoring_dynamics` (same tunable pattern as
`visit_verification`): per-side max nightly change (default 20) and
per-side weekly decay amounts (10 / 20 / 25, holding at the week-3 rate
unless `*_decay_escalates` is set).

**Capped movement.** Each night a score moves toward its windowed target by
at most the configured cap rather than jumping to it, so a grand opening
with 50 verified check-ins climbs like a ticker instead of snapping to the
ceiling. The cap applies in both directions.

**Escalating inactivity decay.** With no qualifying activity, the score
decays on an escalating weekly schedule. Decay is charged per *week
crossing*, not per nightly run - the amounts in the spec are weekly and the
job runs nightly, so `kindex_decayed_through_week` acts as a ledger that
keeps re-runs idempotent. Any qualifying activity resets both the streak
and the ledger immediately.

**Floor semantics.** The floor bounds *decay* only: business scores stop at
their tier baseline (500/850), customers at 0. Movement toward a target may
still land below baseline, because a genuinely badly-reviewed business
should be able to score under it - mere inactivity should not.

**First-run safety.** A business or customer with no recorded
`last_activity_at` starts its clock on the first run rather than being
treated as infinitely inactive, which would otherwise decay every
pre-existing record the night the job first ships.

**Customer side: one writer.** `kindex_engine.js` no longer writes `score`
or `is_trending_up`. It remains the validator and audit trail (rejects
unknown event types, stamps `points_awarded`, denormalizes
`ticker_symbol`), while `customer_kindex_nightly.js` owns the score. Two
writers would make smoothing meaningless - the score would still jump the
instant an event landed. `is_trending_up` now reflects real score movement
rather than the sign of the last processed event.

**Customer dedup.** Events with a `business_ref` are grouped per business
and only the highest-weighted one counts, so breadth of engagement beats
repetition. Events without one (`post`, `share_app`) are deduped per
event_type - an extension beyond the spec, without which `post` at 10
points could be farmed by posting repeatedly.

**Dashboard feed.** Every run writes a `kindex_score_history` row per
entity at a deterministic `{type}_{id}_{YYYY-MM-DD}` id, so re-runs update
the day rather than duplicating while days accumulate. Rows carry
score_before/after, target, capped, decay_applied, inactivity_weeks,
qualifying counts, and (business) verified_visit_count.

Tests: 50 emulator-backed cases across
`test/business_kindex_nightly.test.js` and
`test/customer_kindex_nightly.test.js`.
