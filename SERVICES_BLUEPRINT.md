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
| `generateUniqueTicker` | `({businessName, maxAttempts = 3})` | Read-only: queries `businesses` for `ticker_symbol` collisions. No write. |
| `sanitizeTicker` | `(raw)` | Pure function, no Firestore access - uppercases/strips to alphanumeric, returns null unless exactly 5 chars |
| `registerBusiness` | `({category, businessType, isBlackOwned, place, businessName, phoneNumber, email, website, description})` | Generates a ticker via `generateUniqueTicker`, then creates a `BusinessesRecord` (including `tickerSymbol`); links it to the caller's `ownedBusiness` |
| `upgradeBusinessTier` | `({businessRef, packageId, tierName, isPremium, isPriorityPinned, hasFlashBeacon})` | RevenueCat purchase, then updates `BusinessesRecord` only on a confirmed purchase |
| `downgradeToCommunity` | `({businessRef})` | Resets `BusinessesRecord` to the free Community tier |

## Button map

| Button | File | Service call |
|---|---|---|
| "Submit Review" | `pages/business_profile_v2/business_profile_v2_widget.dart` | `KinServices.submitReview` |
| "Register Now" | `pages/business_setup_page/business_setup_page_widget.dart` | `KinServices.registerBusiness` |
| Community tier card | `pages/merchant_pricing_suite/merchant_pricing_suite_widget.dart` | `KinServices.downgradeToCommunity` |
| Founding Local / Pro Growth / Elite Growth tier cards | `pages/merchant_pricing_suite/merchant_pricing_suite_widget.dart` | `KinServices.upgradeBusinessTier` |

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
