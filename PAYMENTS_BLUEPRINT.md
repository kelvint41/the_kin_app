# Payments & Subscriptions — Audit, Strategy & Roadmap

**Holistic payment architecture for Kinvest Guidance / The KIN App**
v1.0 · July 2026 · companion to `SERVICES_BLUEPRINT.md`

Grounded in a full scan of `lib/` and `firebase/`. Every "exists" claim below
cites a real file; every "missing" claim was verified absent.

---

## Part 1 — Audit & Gap Analysis

### 1.1 What already exists (the good news: ~40% is built)

| Asset | File | State |
|---|---|---|
| RevenueCat SDK wrapper | `lib/flutter_flow/revenue_cat_util.dart` | **Working.** Cross-platform aware (iOS/Android app-store keys, `kIsWeb` branch needs a `webKey`), `initialize/purchasePackage/loadCustomerInfo/loadOfferings`, and a `CustomerInfoUpdateListener`. |
| SDK init | `lib/main.dart:35` | Called at startup — but with **TEST keys** (see Critical Risk #3). |
| Purchase flow | `KinServices.upgradeBusinessTier` (`lib/services/kin_services.dart:374`) | Calls `purchasePackage(packageId)`, and **only on success** writes the business doc. Good client-side shape. |
| Downgrade | `KinServices.downgradeToCommunity` | Resets tier to Community (no purchase). |
| Pricing UI | `lib/pages/merchant_pricing_suite/merchant_pricing_suite_widget.dart` | Four tiers with package IDs `founding_local_monthly` ($19), `pro_growth_monthly` ($29), `elite_growth_monthly` ($99), plus free Community. |
| Entitlement schemas | `entitlements_record.dart` (`tier`, `source`, `granted_reason`, `granted_at`, `expires_at`), `tier_privileges_record.dart` (`business_ref`, `subscription_tier`, `is_premium`, `is_priority_pinned`, `has_flash_beacon`, `owner_id`) | **Schema only — orphaned.** No code writes them (see Gap). |
| Server-side entitlement gate | `ai_marketing_orchestrator.js:104` `isEntitled(business.subscription_tier)` | Exists — but trusts a client-writable field (see Critical Risk #1). |
| Tier→privilege source of truth | `businesses.{subscription_tier, is_premium, is_priority_pinned, has_flash_beacon}` | This is where "premium" actually lives today. |

**Not payments (avoid confusion):** `orders_record.dart` is *delivery* tracking
(DoorDash-style: `delivery_status`, `driver_name`, `tracking_url`), not billing.

### 1.2 What is missing but required

**Backend (the biggest hole):**
- ❌ **No webhook.** Nothing listens to RevenueCat (or Stripe). Grep of
  `firebase/**/*.js` for `webhook`/`stripe`/`revenuecat` → zero handlers.
  Purchases are confirmed **client-side only**.
- ❌ **No server writer for `entitlements` / `tier_privileges`.** The only place
  those collections are populated is a demo seed script
  (`firebase/scripts/seed_screenshot_demo.js`). The professionally-designed
  schema is dead until a webhook fills it.
- ❌ **No renewal / expiry / refund / billing-retry sync.** Premium is set once
  at purchase and never revisited.

**Frontend:**
- ❌ **No account-status screen.** Nowhere shows active vs. expired, renewal
  date, or "manage subscription." The pricing suite sells; nothing services.
- ❌ **No paywall gating in the UI** beyond the pricing page — premium features
  aren't consistently guarded by a single entitlement check.
- ❌ **No web checkout.** The website we built (`website/`) has no billing path;
  RevenueCat's `webKey` is empty, so `kIsWeb` init early-returns.

**Security:** covered as Critical Risks below.

### 1.3 🔴 Critical Risks (structural conflicts — fix before charging anyone)

> **CRITICAL #1 — Entitlement is forgeable. A non-paying user can unlock premium for free.**
> The `businesses` rule is:
> ```
> allow write: if resource.data.owner_ref == /databases/$(db)/documents/users/$(request.auth.uid);
> ```
> An owner may write **any field on their own business doc** — including
> `is_premium: true`, `subscription_tier: "Elite Growth"`,
> `is_priority_pinned: true` — directly through the Firestore SDK, never
> touching RevenueCat. The one server-side check that exists
> (`ai_marketing_orchestrator.js`) reads `subscription_tier` and therefore
> **trusts forged data**. Result: the paid AI Marketing feature (real Gemini
> cost) is unlockable for $0, and every "premium" display flag is
> self-serve. This is the single most important thing in this document.

> **CRITICAL #2 — No webhook = no reconciliation and no expiry.**
> Purchase truth lives only in the client call. Two failure modes, both live
> today: (a) client dies *after* Apple/Google charges the card but *before*
> the `businessRef.update` → **customer paid, got nothing**, with no
> server record to recover from; (b) subscriptions renew, lapse, refund, and
> fail billing retries entirely server-side at the store — with no webhook,
> `is_premium` **never flips back**, so an expired/refunded card keeps
> premium forever (revenue leak + support nightmare).

> **CRITICAL #3 — Test keys committed in source.**
> `lib/main.dart:35` ships `"test_nlIQSnnGvtvhLZnWwgHRKoDnhsN"` for *both*
> store keys. Fine for dev, but it means **no real purchase works today**,
> and the pattern invites a real key being hardcoded next. Keys belong in
> build-time config / `--dart-define`, not source.

> **CRITICAL #4 — `orders` vs billing namespace.** Not a vulnerability, but
> `orders` already means "delivery" here. Do **not** overload it for payments;
> use a distinct `subscription_events` / `entitlements` namespace (below) or
> future you will conflate delivery status with billing status.

---

## Part 2 — Architectural Strategy: the Single Source of Truth

### The decision hinge: *where do your merchants pay?*

Your paying customer is a **business owner buying a listing upgrade** — B2B,
not a consumer buying coins. That reframes the usual Stripe-vs-RevenueCat
question around one fact: **Apple and Google require their in-app purchase
system for digital subscriptions bought inside the mobile app**, taking
15–30%. Where the *tap-to-pay* happens decides everything.

### Recommendation: **RevenueCat as the Single Source of Truth**, Stripe as the web rail behind it.

You already have the RevenueCat SDK wired and a `CustomerInfoUpdateListener` in
place — this is the least-rewrite, most-correct path for a hybrid app+web
product. RevenueCat normalizes App Store, Play Store, **and** web (Stripe)
receipts into *one* `CustomerInfo` entitlement object and *one* webhook, so
your backend has a single truth to sync regardless of where the money entered.

```
  App Store IAP  ─┐
  Play Store IAP ─┼─▶  RevenueCat  ──webhook──▶  syncEntitlement (Cloud Fn) ──▶ Firestore
  Web (Stripe)   ─┘   (source of truth)          (ONLY writer of premium)      entitlements/*
                                                                                businesses.is_premium (locked)
```

### Option comparison for *your* case (directory subscriptions)

| | **RevenueCat as SoT (recommended)** | **Stripe direct, everywhere** | **Stripe direct, web-only billing** |
|---|---|---|---|
| iOS/Android in-app upgrade | ✅ Compliant IAP, unified | 🔴 **Rejected by Apple** for digital goods | ✅ N/A (no in-app buy) |
| Web upgrade | ✅ via RC Web Billing / Stripe | ✅ native Stripe | ✅ native Stripe |
| One entitlement object across platforms | ✅ built-in | ❌ you build the merge | ✅ trivial (one platform) |
| One webhook to sync | ✅ | ❌ Stripe + StoreKit + Play separately | ✅ |
| Fees | RC ~1% + store 15–30% (in-app) / Stripe ~3% (web) | Stripe ~3% | Stripe ~3% |
| Existing code reuse | ✅ SDK already integrated | 🔴 rip out RevenueCat | 🟡 keep RC for app, add Stripe web |
| Best when | Selling upgrades **inside the app** | Never, for this app | Merchants **only** upgrade on a web dashboard |

**The one scenario where Stripe-direct wins:** if you decide business owners
**only ever upgrade on the website** (a merchant web dashboard) and the mobile
app never sells anything — then skip the store cut and RevenueCat's fee, wire
Stripe Checkout + Stripe webhooks directly, and the mobile app just *reads*
entitlement. For a directory whose buyers are businesses (who often prefer a
desktop billing portal), this is a legitimate, cheaper choice. **But** the
moment you want an in-app "Upgrade" button on iOS, you're back to needing
RevenueCat. Given your SDK is already in and the pricing suite is an in-app
screen, **RevenueCat as SoT is the right default.**

### The invariant that makes either safe

> **Firestore is a read-model, never a write-source, for entitlement.**
> The client may *initiate* a purchase but must **never** write
> `is_premium` / `subscription_tier`. Only the webhook-driven Cloud Function
> writes those, after verifying with RevenueCat/Stripe. Lock it in rules:
> ```
> match /businesses/{doc} {
>   allow read: if true;
>   // owner may edit profile fields but NOT entitlement fields
>   allow update: if isOwner(doc)
>     && !request.resource.data.diff(resource.data).affectedKeys()
>          .hasAny(['is_premium','subscription_tier','is_priority_pinned','has_flash_beacon']);
> }
> match /entitlements/{id}   { allow read: if isOwner…; allow write: if false; }
> match /tier_privileges/{id}{ allow read: if isOwner…; allow write: if false; }
> ```
> This single change closes Critical Risk #1. `KinServices.upgradeBusinessTier`
> stops writing the business doc directly; it initiates the purchase and then
> **waits for the webhook** to flip entitlement (client can optimistically
> poll `CustomerInfo`).

---

## Part 3 — Bottom Navigation (production Flutter)

Your router is **GoRouter** (FlutterFlow-generated `FFRoute`s in
`lib/flutter_flow/nav/nav.dart`), currently a flat route list. The correct way
to get a persistent bottom bar that **remembers each tab's state** (nav stack +
scroll position) *and* keeps web deep-links working is
`StatefulShellRoute.indexedStack` — it wraps each branch in an `IndexedStack`,
so tabs are kept alive, not rebuilt, when you switch.

### 3.1 Router: add a shell around the four tabs

```dart
// lib/flutter_flow/nav/nav.dart — replace the four tab FFRoutes with:
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) =>
      KinScaffold(navigationShell: navigationShell), // the bar host, below
  branches: [
    StatefulShellBranch(routes: [
      GoRoute(path: '/explore',   builder: (_, __) => const ExploreWidget()),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(path: '/map',       builder: (_, __) => const MapWidget()),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(path: '/favorites', builder: (_, __) => const FavoritesWidget()),
    ]),
    StatefulShellBranch(routes: [
      // The account branch decides its own landing screen (see §3.3).
      GoRoute(path: '/account',   builder: (_, __) => const AccountGate()),
    ]),
  ],
),
```

Each branch keeps its **own Navigator**, so pushing a business profile inside
[Explore] and switching to [Map] and back returns you exactly where you were —
that is the "remember where the user is" requirement, handled by the framework
rather than manual index bookkeeping.

### 3.2 The persistent bar host

```dart
// lib/components/kin_scaffold.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class KinScaffold extends StatelessWidget {
  const KinScaffold({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    (icon: Icons.explore_outlined,   active: Icons.explore,   label: 'Explore'),
    (icon: Icons.map_outlined,       active: Icons.map,       label: 'Map'),
    (icon: Icons.favorite_outline,   active: Icons.favorite,  label: 'Favorites'),
    (icon: Icons.person_outline,     active: Icons.person,    label: 'Account'),
  ];

  void _onTap(int index) {
    // initialLocation:true → tapping the active tab pops it to its root,
    // the expected mobile behavior.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      body: navigationShell, // IndexedStack under the hood — tabs stay alive
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        backgroundColor: theme.primary,          // KIN Evergreen #0B3D2E
        indicatorColor: theme.accent1.withOpacity(0.20), // brand gold wash
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          for (var i = 0; i < _tabs.length; i++)
            NavigationDestination(
              icon: Icon(_tabs[i].icon, color: theme.secondaryText),
              selectedIcon: Icon(_tabs[i].active, color: theme.accent1), // gold
              label: _tabs[i].label,
            ),
        ],
      ),
    );
  }
}
```

### 3.3 Account tab: route to status vs. upgrade by entitlement

```dart
// lib/pages/account_gate.dart
import 'package:flutter/material.dart';
import '/flutter_flow/revenue_cat_util.dart' as rc;

/// The [Account] branch lands here and forwards to the right screen.
/// Reads the RevenueCat entitlement (the SoT), NOT a Firestore flag the
/// client could have forged — see PAYMENTS_BLUEPRINT Part 2.
class AccountGate extends StatelessWidget {
  const AccountGate({super.key});

  bool get _isPremium =>
      rc.customerInfo?.entitlements.active.containsKey('premium') ?? false;

  @override
  Widget build(BuildContext context) =>
      _isPremium ? const AccountStatusPage() : const UpgradePage();
}
```

`AccountStatusPage` shows active tier, renewal/expiry date
(`customerInfo.entitlements.active['premium'].expirationDate`), and a "Manage
Subscription" button (`Purchases.showManageSubscriptions()`); `UpgradePage`
is your existing `MerchantPricingSuiteWidget`. Because the gate reads live
`CustomerInfo`, a lapsed subscriber automatically sees the upgrade path again
the instant the webhook (Part 2) reflects expiry.

---

## Deliverable — 10-Step Implementation Roadmap

**Phase A — Close the security hole (do first, before any real key):**
1. **Lock entitlement fields in `firestore.rules`** — deny client writes to
   `is_premium`/`subscription_tier`/`is_priority_pinned`/`has_flash_beacon`
   on `businesses`; keep `entitlements`/`tier_privileges` server-write-only.
   (Closes Critical Risk #1.)
2. **Stop the client writing entitlement.** Refactor
   `KinServices.upgradeBusinessTier` to initiate the RevenueCat purchase only;
   remove the direct `businessRef.update` of premium fields.
3. **Move keys out of source** to `--dart-define` / build config; swap the
   test keys for real RevenueCat keys per environment. (Critical Risk #3.)

**Phase B — Build the server source of truth:**
4. **`syncEntitlement` Cloud Function** — an HTTPS endpoint receiving
   **RevenueCat webhooks** (INITIAL_PURCHASE, RENEWAL, CANCELLATION, EXPIRATION,
   BILLING_ISSUE, PRODUCT_CHANGE), authenticated via a shared secret header.
   Admin-SDK-writes `entitlements/{businessId}` + mirrors the derived
   `is_premium`/`subscription_tier` onto `businesses`. Idempotent by event id
   (same transaction pattern as `kindex_engine.js`). (Closes Critical Risk #2.)
5. **Map RevenueCat `app_user_id` → business.** Call
   `Purchases.logIn(businessId)` at upgrade time so the webhook knows which
   business doc to update.
6. **Server entitlement helper.** Have `ai_marketing_orchestrator.js` (and any
   future gated function) read `entitlements/{id}` (server-written) instead of
   the now-locked `businesses.subscription_tier`, or trust it *because* it's
   now server-only.

**Phase C — Frontend servicing:**
7. **Account Status screen** (§3.3) — active tier, renewal date, manage/cancel,
   restore-purchases button.
8. **Single paywall guard** — one `hasEntitlement('premium')` check (reading
   `CustomerInfo`) wrapping every premium surface, so gating is consistent.

**Phase D — Web + hardening:**
9. **Web billing** — add RevenueCat Web Billing (Stripe behind it) with a real
   `webKey`, or, if you choose web-only billing (Part 2 option 3), Stripe
   Checkout + a `stripeWebhook` function writing the same `entitlements` docs.
   Either way the mobile app just *reads* entitlement.
10. **Reconciliation & tests** — a scheduled function that re-syncs
    `CustomerInfo` for at-risk subs (billing retry) and flips lapsed ones;
    end-to-end sandbox test of purchase → webhook → Firestore → UI unlock →
    expiry → re-lock.

**Sequencing note:** Steps 1–3 are the only *urgent* ones — until they ship,
premium is free-for-all and no real key should be added. Everything else is
normal product work.
