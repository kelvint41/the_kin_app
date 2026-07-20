# KIN Marketing Engine

Backend + FlutterFlow integration for the in-app marketing management system:
**referral programs, promotional campaigns, and per-region engagement
analytics.** Plus a **copy/template library** for the automated messages that
drive it.

Design principle: **reuse the app's existing reward rails, don't fork them.**
Referral rewards are granted as Kindex `UserEngagementEvents` (scored by the
existing `processUserEngagementEvent` engine against console-tunable
`kindex_config/scoring_weights`) and optional `entitlements` grants — no new
points currency is invented. The callable-vs-trigger split mirrors the app's
existing `generateMarketingContent` (callable) + `processUserEngagementEvent`
(trigger) convention.

---

## 1. Firestore schema

### `marketing_campaigns`
The campaign definition plus live, server-maintained metric counters.

| Field | Type | Notes |
|---|---|---|
| `title`, `description` | string | |
| `owner_ref` | ref → `users` | Creator; only they can edit (rules) |
| `business_ref` | ref → `businesses` | Optional, if business-specific |
| `type` | string | `referral` \| `promo` \| `awareness` |
| `status` | string | `draft` \| `active` \| `paused` \| `ended` |
| `target_regions` | array\<string\> | e.g. `["San Antonio, TX","Houston, TX"]` |
| `default_region` | string | Fallback region for analytics |
| `start_date`, `end_date` | timestamp | `expireCampaigns` ends it past `end_date` |
| `referral_reward_tier` | string | Optional entitlement tier granted per referral |
| `referral_reward_days` | int | Entitlement duration (0 = no expiry) |
| `max_referrals_per_user` | int | Anti-abuse cap (0 = unlimited) |
| `referral_count` | int | **Server-only.** Every redemption |
| `qualified_referral_count` | int | **Server-only.** Passed validation |
| `reward_granted_count` | int | **Server-only.** Rewards paid |
| `impression_count`, `click_count` | int | **Server-only.** From `logCampaignEvent` |
| `created_at`, `updated_at` | timestamp | |

### `referral_codes`  (doc id **is** the code)
Atomic uniqueness via document id — a create against a taken code collides and
is retried, exactly like `ticker_registry`. No query, no transaction.

| Field | Type | Notes |
|---|---|---|
| `owner_ref` | ref → `users` | The referrer |
| `campaign_ref` | ref → `marketing_campaigns` | |
| `created_at` | timestamp | |

### `referrals`  (doc id = `{campaignId}_{refereeUid}`)
One referral relationship. **Created only server-side** so a client can never
forge who referred them. Deterministic id ⇒ one redemption per user per campaign.

| Field | Type | Notes |
|---|---|---|
| `code` | string | |
| `campaign_ref` | ref | |
| `referrer_ref` | ref → `users` | Resolved from the code, server-side |
| `referee_ref` | ref → `users` | The new user |
| `region` | string | For per-market analytics |
| `status` | string | `pending` → `rewarded` \| `rejected` |
| `reject_reason` | string | e.g. `campaign_not_live` |
| `referrer_points_awarded`, `referee_points_awarded` | int | Server-set |
| `created_at`, `processed_at` | timestamp | |

### `campaign_analytics_daily`  (doc id = `{campaignId}_{regionSlug}_{YYYYMMDD}`)
Per-campaign, per-region daily rollup. Deterministic id + `FieldValue.increment`
so writes are cheap and mergeable. Mirrors the existing `analytics_daily`.

| Field | Type |
|---|---|
| `campaign_ref` | ref |
| `region` | string |
| `date` (YYYYMMDD), `date_ts` | string / timestamp |
| `referral_count`, `qualified_referral_count`, `reward_granted_count`, `impression_count`, `click_count` | int |

Security rules for all four collections are in `firebase/firestore.rules`;
composite indexes in `firebase/firestore.indexes.json`.

---

## 2. Cloud Functions (`firebase/custom_cloud_functions/marketing_engine.js`)

| Function | Kind | Purpose |
|---|---|---|
| `getOrCreateReferralCode` | callable (v2) | Mints/returns the caller's shareable code for a campaign. Uniqueness via doc-id collision + retry. |
| `redeemReferralCode` | callable (v2) | New user submits a code. Resolves referrer server-side, validates (active campaign, no self-referral, per-referrer cap, one-per-user), creates the `pending` referral. |
| `processReferral` | Firestore trigger | On new referral: **idempotent** (re-reads status inside a transaction, same at-least-once guard as `kindex_engine`). Grants both-sided Kindex events + optional entitlement, flips status, increments campaign + daily counters — all in one transaction. |
| `logCampaignEvent` | callable (v2) | Logs `impression`/`click` per region (supports batched `count`). |
| `expireCampaigns` | scheduled (*/5) | Flips `active` campaigns to `ended` past `end_date`. Twin of `checkAndExpireBeacons`. |

### ⚠️ One required config step
Rewards are Kindex events, so add point values to
`kindex_config/scoring_weights` (tune later from the console, no redeploy):

```
referral_success : 50      // to the referrer
referral_signup  : 25      // to the new user
```
Without these keys the scoring engine marks the events `rejected` with
`unknown event_type` and no points are awarded (the referral still records).

### Deploy
```bash
cd firebase/custom_cloud_functions
npm install
firebase deploy --only functions:getOrCreateReferralCode,functions:redeemReferralCode,functions:processReferral,functions:logCampaignEvent,functions:expireCampaigns
firebase deploy --only firestore:rules,firestore:indexes
```
No new npm dependencies — uses `firebase-admin` / `firebase-functions` already
in `package.json`.

---

## 3. FlutterFlow integration

New generated-style records: `MarketingCampaignsRecord`, `ReferralsRecord`
(wired into `lib/backend/backend.dart` with query helpers). Service methods on
`KinServices` (`lib/services/kin_services.dart`) return `ServiceResult<T>`, the
same pattern every button already uses.

**Add the two new collections in FlutterFlow** (Firestore tab) with the fields
above so the UI can data-bind — the Dart records already match these names.

### Call sites (Custom Action or button `onPressed`)

**Create a campaign** (owner/business dashboard):
```dart
final result = await KinServices.createReferralCampaign(
  title: _model.titleController.text,
  description: _model.descController.text,
  targetRegions: ['San Antonio, TX'],
  startDate: DateTime.now(),
  endDate: DateTime.now().add(const Duration(days: 30)),
  referralRewardTier: 'Pro Growth', // optional entitlement perk
  referralRewardDays: 30,
  maxReferralsPerUser: 25,
);
```

**Invite friends** — get the code, then reuse the existing `shareApp` flow:
```dart
final res = await KinServices.getOrCreateReferralCode(campaignRef: campaignRef);
if (res.isSuccess) {
  await KinServices.shareApp(
    text: 'Join me on The KIN App and support Black-owned businesses. '
        'Use my code ${res.data} 👉 https://thekin.app/i/${res.data}',
  );
}
```

**Redeem at signup** — in the post-signup "Have a code?" prompt:
```dart
final res = await KinServices.redeemReferralCode(
  code: _model.codeController.text,
  region: currentUserLocationValue?.toString(),
);
if (!res.isSuccess && mounted) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(res.error!)));
}
```

**Log a promo impression/click** — on a banner widget:
```dart
KinServices.logCampaignEvent(campaignRef: campaignRef, eventType: 'impression', region: city);
// onTap:
KinServices.logCampaignEvent(campaignRef: campaignRef, eventType: 'click', region: city);
```

For **FlutterFlow Custom Actions**, wrap any of the above in a
`Future<...>` action file under `lib/custom_code/actions/` (same boilerplate
header as `calculate_real_time_kindex.dart`) and call the `KinServices` method
inside — FlutterFlow will surface it as a bindable action.

---

## 4. Copy & template library

Merge fields in `{curly braces}` map to Firestore/local values. Keep the voice
**warm, local, and specific** — never corporate. This is a community, not a
coupon blast.

### 4a. Featured / priority-pinned business push notifications
Trigger source: `businesses` where `is_priority_pinned == true` (optionally
`has_flash_beacon == true` for Power Hour). Rotate templates; never send the
same business two days running to the same user.

- **Spotlight**
  `title:` ✨ {business_name} is trending in {city}
  `body:` Your neighbors are loving this {category} spot. Tap to see why it's on the rise.
- **Power Hour / flash beacon (time-boxed urgency, honest)**
  `title:` 🔥 {business_name} — Power Hour is live
  `body:` {promo_offer} for the next {minutes_left} min. Support local before it's gone.
- **Kindex mover (ties promo to your moat)**
  `title:` 📈 {business_name} just jumped to #{kindex_rank} in {category}
  `body:` The community is putting them on the map. Check them out.
- **New in your area**
  `title:` 👋 New Black-owned {category} near you
  `body:` {business_name} just joined KIN in {city}. Be one of their first supporters.
- **Category affinity (personalized from prior taps)**
  `title:` You love {category} — meet {business_name}
  `body:` Hand-picked for you in {city}. {short_hook}

Rules of the road: one merge-in of real value per push (an offer, a rank, or a
genuinely new option). No "Check us out!" filler. Always deep-link to the
business profile, never a generic home screen.

### 4b. Welcome messages (onboarding drip)
- **Welcome 1 — immediate (in-app + push)**
  `Welcome to KIN, {first_name} 🖤 Every tap, review, and dollar here moves a Black-owned business up the Kindex. Let's find your first favorite in {city}.`
- **Welcome 2 — day 1, activation nudge**
  `Your KIN feed is warmer with a favorite in it. Save one {category} spot near you — it takes 5 seconds and helps them climb.`
- **Welcome 3 — day 3, first review ask**
  `Been somewhere great lately? A quick review is the single biggest boost you can give a local business on KIN. ⭐`
- **Welcome 4 — day 5, referral invite (hands off to 4c)**
  `You're officially part of the KIN community. Know someone who'd love this? Your invite code {referral_code} gets you both a boost.`

### 4c. Referral invitation copy (shared by the referrer)
Populated with the code from `getOrCreateReferralCode`.

- **Share-sheet default (SMS/DM)**
  `I'm using The KIN App to find and support Black-owned businesses in {city}. Join me — use code {referral_code} and we both get a KIN boost 👉 {invite_link}`
- **Social caption**
  `Putting my money where my community is. 🖤 Find Black-owned spots near you on @thekinapp — grab code {referral_code}. {invite_link}`
- **In-app invite banner**
  `title:` Bring a friend, grow the community
  `body:` Share your code {referral_code}. When they join, you both move up the Kindex.
- **Referee redemption success (in-app toast)**
  `Code accepted 🎉 You and {referrer_name} both earned a KIN boost. Welcome to the community.`
- **Referrer "your friend joined" push**
  `title:` 🎉 {referee_name} joined with your code
  `body:` +{referral_success_points} to your Kindex. Keep sharing — the community grows with you.

### 4d. Scheduling strategy (helpful, not spammy)
Governing rule: **every message earns its send with value.** If it isn't
timely, local, or personal, it doesn't go.

1. **Frequency cap:** ≤ 3 pushes/week/user, hard. Welcome drip is exempt but
   still ≤ 1/day.
2. **Quiet hours:** send **11am–2pm** (lunch discovery) and **5pm–7pm**
   (evening plans), in the **user's local timezone**. Never before 9am or
   after 9pm.
3. **Event-driven > broadcast:** prefer triggers a user actually caused or
   cares about — a favorited business goes on Power Hour, their Kindex rank
   changed, a new business opened in a category they browse. These convert far
   better than blasts and feel like a favor, not spam.
4. **Broadcast promos:** at most **1–2/week**, and only genuinely featured
   (`is_priority_pinned`) businesses, rotated so no business dominates.
5. **Suppression:** never notify about a business the user just visited (check
   `uservisits`), muted, or hid. Respect per-category opt-outs.
6. **Referral cadence:** ask once at day 5, then only re-surface after a
   *positive* moment (they left a 5-star review, hit a Kindex milestone) — the
   moment someone feels good is the moment they'll share.
7. **Measure and prune:** watch per-template open rate and the
   notification-driven uninstall/mute rate. Kill any template whose mute rate
   outruns its opens. `logCampaignEvent` + `campaign_analytics_daily` give you
   the per-region numbers to do this.
