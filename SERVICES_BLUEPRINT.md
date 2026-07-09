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

## Button map

| Button | File | Service call |
|---|---|---|
| "Submit Review" | `pages/business_profile_v2/business_profile_v2_widget.dart` | `KinServices.submitReview` |
| "Register Now" | `pages/business_setup_page/business_setup_page_widget.dart` | `KinServices.registerBusiness` |
| Community tier card | `pages/merchant_pricing_suite/merchant_pricing_suite_widget.dart` | `KinServices.downgradeToCommunity` |
| Founding Local / Pro Growth / Elite Growth tier cards | `pages/merchant_pricing_suite/merchant_pricing_suite_widget.dart` | `KinServices.upgradeBusinessTier` |
| Onboarding Kindex ticker (top-of-screen marquee) | `pages/onboarding_selection_card/onboarding_selection_card_widget.dart` -> `components/marquee_ticker_widget.dart` | `KinServices.fetchTopBusinessKindex` + `fetchTopCustomerKindex` |

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
