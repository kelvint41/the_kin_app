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
business Kindex scoring should actually happen (nothing currently
updates `businesses.kindex_score`/`kindex_velocity` at all outside of
manual/admin writes) - a bigger scope than the ticker feature itself.

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
