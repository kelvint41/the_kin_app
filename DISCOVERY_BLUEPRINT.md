# Business Discovery Engine — Data Logic Map

**Logic Architecture for consent-first business discovery**
Kinvest Guidance LLC · The KIN App · v1.0 · July 2026

Companion to `WEBSITE_BLUEPRINT.md` (web) and `SERVICES_BLUEPRINT.md` (app
service layer). Grounded in the live schema: every collection and field named
here either already exists in `lib/backend/schema/` / `firebase/` or is
explicitly marked **NEW**.

---

## 0. Principles

1. **No mass-scraped or third-party directory files.** Every business record
   traces to a human act: an owner submission, an owner claim, or a user
   suggestion. The existing San Antonio seed CSV
   (`National_Directory - San_Antonio_TX_Directory.csv`) is grandfathered as
   provenance `seed_directory` and treated as *unclaimed candidates*, not
   verified listings — it ages out as owners claim or records fail review.
2. **The live directory is sacred.** Nothing writes to `businesses` except
   the promotion step of this pipeline (and verified owners editing their own
   listing, which Firestore rules already enforce via `owner_ref`).
3. **Quality is a state machine, not a boolean.** A record's trust level is
   explicit, auditable, and displayed honestly in the app.
4. **Every automated step is idempotent** (at-least-once triggers, same
   pattern as `kindex_engine.js`).

---

## 1. The Data Logic Map (Submitted → Featured)

```
  SOURCES (consent-first)                      PIPELINE (Cloud Functions)                     LIVE APP
┌──────────────────────────┐
│ A. Google Form            │  Apps Script    ┌─────────────────────────────┐
│    (owner self-signup)    │───webhook──────▶│ ingestBusinessCandidate     │
├──────────────────────────┤                  │  (HTTPS, NEW)               │
│ B. In-app "Register Now"  │  route through  │  · provenance stamp         │
│    KinServices            │───candidates───▶│  · dedupe fingerprint       │
│    .registerBusiness      │   instead of    │  · status: submitted        │
├──────────────────────────┤   direct write  └──────────────┬──────────────┘
│ C. In-app user suggestion │                                │ creates
│    (NEW, §5)              │────────────────▶┌──────────────▼──────────────┐
├──────────────────────────┤                  │ business_candidates (NEW)   │
│ D. Seed CSV (legacy)      │  one-time       │ status: submitted           │
│    provenance-tagged      │───backfill─────▶└──────────────┬──────────────┘
└──────────────────────────┘                                 │ onCreate
                                              ┌──────────────▼──────────────┐
                                              │ normalizeBusinessCandidate  │
                                              │  (onCreate trigger, §4)     │
                                              │  · phone → E.164            │
                                              │  · name/address title case  │
                                              │  · URL/email normalization  │
                                              │  · geocode + metro tag (§3) │
                                              │  · duplicate check          │
                                              │  status → normalized        │
                                              │        or needs_attention   │
                                              │        or duplicate         │
                                              └──────────────┬──────────────┘
                                                             │
                                              ┌──────────────▼──────────────┐
                                              │ VERIFICATION PIPELINE (§2)  │
                                              │ automated checks → evidence │
                                              │ → human decision            │
                                              │ status → approved           │
                                              │        or rejected          │
                                              └──────────────┬──────────────┘
                                                             │ approved only
                                              ┌──────────────▼──────────────┐      ┌─────────────────┐
                                              │ promoteCandidate (NEW)      │─────▶│ businesses      │
                                              │  · creates BusinessesRecord │      │ (live directory)│
                                              │  · ticker via               │      └────────┬────────┘
                                              │    generateUniqueTicker     │               │
                                              │  · verification fields set  │      engagement events,
                                              │  · candidate → promoted     │      reviews, connections
                                              └─────────────────────────────┘               │
                                                                                  ┌─────────▼─────────┐
                                                                                  │ kindex_engine     │
                                                                                  │ (existing) scores │
                                                                                  └─────────┬─────────┘
                                                                                            │ top N
                                                                    ┌───────────────────────▼─────┐
                                                                    │ FEATURED: app Spotlight +   │
                                                                    │ web_projection → web_public │
                                                                    │ (ticker/map/signup flash)   │
                                                                    └─────────────────────────────┘
```

**Candidate status vocabulary** (single `status` field, one-way except where
noted): `submitted → normalized → in_review → approved → promoted`, with exits
`needs_attention` (auto-fix failed; editable, re-enters at `submitted`),
`duplicate` (terminal, linked to the existing record), `rejected` (terminal,
with `rejection_reason`).

---

## 2. Collections & Trust Model

### 2.1 `business_candidates` (NEW) — the quarantine zone

The load-bearing design decision: **candidates live in their own collection,
not in `businesses`.** The live directory never contains "maybe" rows, app
queries never need `where status ==` filters, Algolia never indexes junk, and
`registerBusiness`'s current behavior — writing straight into the live
directory — is retired.

```
business_candidates/{candidateId}
  // Raw as-submitted (immutable once written — audit trail)
  raw: { business_name, owner_name, phone, email, website, address,
         city, state, zip, category, description, is_black_owned_claimed }
  // Written by normalizeBusinessCandidate (§4)
  clean: { ...same shape, normalized }
  geo: { lat, lng, metro, geo_confidence }            // §3
  fingerprint: string          // dedupe key, §4.4
  provenance: 'google_form' | 'in_app_owner' | 'user_suggestion' | 'seed_directory'
  submitted_by_ref: users ref | null                  // suggestions/in-app
  suggestion_count: number     // §5 quorum
  status: string               // vocabulary above
  status_history: [{ status, at, by }]                // audit trail
  verification: {              // §2.3
    level: 'unverified' | 'self_attested' | 'community_verified' | 'kin_verified',
    evidence: [{ type, link, added_by, at }],
    decided_by, decided_at, notes
  }
  created_at, updated_at
```

**Rules:** client `create` allowed only through the callable/HTTPS functions
(so deny-all direct writes, same posture as `launch_subscribers`); `read`
restricted to admins (`users.is_admin == true`, the flag `signup_feed` rules
already use).

### 2.2 Reused existing collections

| Existing asset | Role in this pipeline |
|---|---|
| `claim_requests` (`business_id`, `applicant_user_id`, `verification_proof_link`, `status`) | Ownership claims on *already-live* listings (esp. seed-directory rows). Approving a claim sets `is_claimed`, `claimed_by_user_id`, `owner_ref` and upgrades verification level. |
| `businesses.is_black_owned`, `is_verified`, `is_claimed`, `tier_level` | Display flags the promotion step sets — the app UI already renders them. |
| `KinServices.generateUniqueTicker` | Called at promotion, not at submission — tickers are only minted for real listings. |
| `activity_logs` | Every status transition appends one row (`create: if true` rules already allow the functions to write cheaply). |
| Algolia `businesses` index | Unchanged — it only ever sees promoted records. |

### 2.3 Verification Workflow — "how do we know it's Black-owned?"

Attestation is layered, never binary. The `verification.level` ladder:

| Level | Meaning | How it's reached | App display |
|---|---|---|---|
| `unverified` | Third-party info (seed rows, user suggestions) | Default for provenance ≠ owner | Listed, **no badge**; "Own this business? Claim it" CTA |
| `self_attested` | The owner themself checked "Black-owned" on submission/claim | Google Form / in-app registration by the owner account | Standard listing; identity chip shown as *self-reported* |
| `community_verified` | ≥ 3 distinct KIN members suggested/affirmed it AND no disputes | Automatic counter (§5) + no open flags | Badge: "Community Verified" |
| `kin_verified` | A human reviewer accepted documentary evidence | Manual step below | Gold check (`is_verified: true`) — the badge `exchange_posts` rules already gate on |

**Automated steps (before any human minutes are spent):**
1. **Liveness checks** — website URL resolves (HTTP < 400), phone is a valid
   NANP number after E.164 normalization, email domain has MX records.
   Failures → `needs_attention`, never auto-reject.
2. **Consistency checks** — submitted city matches geocoded address metro;
   name/address fingerprint has no `duplicate` hit.
3. **Evidence intake** — the form invites (optional) links: business
   registration, social profile, press. Stored as
   `verification.evidence[{type: 'registration'|'social'|'press'|'other'}]` —
   the same shape `claim_requests.verification_proof_link` already implies.

**Manual step (the only human gate):** a reviewer (any `is_admin` user) opens
the review queue (candidates `status in ['normalized','in_review']`, oldest
first), sees the clean record + evidence + automated check results, and makes
one of three calls:
- **Approve** → sets `verification.level` (`kin_verified` only with evidence;
  otherwise `self_attested`), `status: approved` → `promoteCandidate` runs.
- **Request info** → `needs_attention` + templated email to the submitter.
- **Reject** → terminal, reason logged; the fingerprint is retained so
  resubmission of the same junk auto-flags.

**Flagging as Verified in the database:** promotion writes
`is_black_owned: true` only when level ≥ `self_attested`, and
`is_verified: true` only when level = `kin_verified`. Disputes (in-app
"report listing") drop `is_verified` pending re-review — verification is
revocable state, not a permanent stamp.

---

## 3. Geographic Tagging

### 3.1 Tagging at ingestion (one-time, server-side)

```
address + zip ──▶ geocode (Google Geocoding API, key server-side only)
                    │ returns lat/lng + formatted address
                    ▼
             metro resolver:
               1. ZIP prefix table (fast path, no API ambiguity):
                    782xx → San Antonio · 770xx–772xx → Houston
                    303xx/311xx/300xx–302xx → Atlanta
               2. else bounding-box test on lat/lng (±~0.6° per metro)
               3. else metro: 'other', geo_confidence: 'low'
                    → surfaces in review queue, reviewer assigns manually
```

Written once to `candidates.geo.{lat,lng,metro,geo_confidence}` and carried
into `businesses.{latitude,longitude,city,state}` at promotion — **`city` is
always the canonical metro name** (`San Antonio`, `Houston`, `Atlanta`), never
the raw form input ("SATX", "san antonio tx"), because `web_projection.js`
and app queries both filter on exact string equality.

### 3.2 Display filtering (how users only see their metro)

- **Resolve the user's metro once per session:** device location (existing
  `currentUserLocationValue` plumbing) → nearest metro center within 80 km;
  fall back to a manual metro picker persisted in FFAppState (today the app
  hardcodes `FFAppConstants.SanAntonio` — this replaces that constant with a
  state variable, defaulting to San Antonio).
- **Firestore path:** every directory query adds
  `where('city', isEqualTo: userMetro)` — equality + existing single-field
  indexes, no composite-index explosion.
- **Algolia path:** search already passes `location` + `searchRadiusMeters`
  (`BusinessesRecord.search`); set radius ~80 km around the metro center and
  add `city:{metro}` as a facet filter for exactness.
- **Website path:** `web_public/map` is already keyed per metro
  (`cities: {San Antonio, Houston, Atlanta}`) — the tag IS the pipeline.
- **Expansion to city #4** = add one row to the metro table (functions
  config doc `discovery_config/metros`, mirroring how `kindex_config/scoring_weights`
  keeps tunables out of code) + one entry in the app's metro picker.

---

## 4. Data Integrity — `normalizeBusinessCandidate`

Program structure (Cloud Function, lives beside `kindex_engine.js`; v1
`onCreate` trigger to match house style):

```js
// firebase/custom_cloud_functions/discovery_pipeline.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");

exports.normalizeBusinessCandidate = functions.firestore
  .document("business_candidates/{candidateId}")
  .onCreate(async (snapshot) => {
    const db = admin.firestore();
    const ref = snapshot.ref;

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const c = snap.data();
      if (!c || c.status !== "submitted") return;   // idempotency, kindex-style

      const raw = c.raw || {};
      const issues = [];

      const clean = {
        business_name: titleCase(collapseWhitespace(raw.business_name)),
        owner_name:    titleCase(collapseWhitespace(raw.owner_name)),
        phone:         normalizePhone(raw.phone, issues),   // → +1XXXXXXXXXX
        email:         (raw.email || "").trim().toLowerCase(),
        website:       normalizeUrl(raw.website, issues),   // https://, strip
                                                            // tracking params
        address:       titleCase(collapseWhitespace(raw.address)),
        zip:           (raw.zip || "").replace(/\D/g, "").slice(0, 5),
        category:      mapCategory(raw.category, issues),   // controlled vocab
        description:   sentenceTrim(raw.description, 500),
      };
      if (!clean.business_name) issues.push("missing business_name");
      if (!clean.phone && !clean.email && !clean.website)
        issues.push("no contact channel");

      // Dedupe fingerprint: name + street number + zip survives
      // capitalization, punctuation, and "LLC" suffix noise.
      const fingerprint = makeFingerprint(clean);           // sha256 hex
      const dupes = await findExisting(db, fingerprint);    // candidates
                                                            // (promoted/other)
                                                            // + businesses
      tx.update(ref, {
        clean,
        fingerprint,
        status: dupes.length ? "duplicate"
              : issues.length ? "needs_attention"
              : "normalized",
        normalization_issues: issues,
        duplicate_of: dupes[0] || null,
        status_history: admin.firestore.FieldValue.arrayUnion({
          status: "…", at: new Date(), by: "normalizeBusinessCandidate" }),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    // Geocoding happens AFTER the transaction (external API calls don't
    // belong inside one); it patches geo.* and, on low confidence, flips
    // status normalized → needs_attention.
    await geocodeAndTagMetro(ref);
  });
```

Helper contracts (pure functions, unit-testable):

| Helper | Rule |
|---|---|
| `normalizePhone` | Strip non-digits; 10 digits → `+1…`; 11 starting with 1 → `+…`; anything else → keep raw in `raw.`, flag issue. Never guess. |
| `titleCase` | Word-wise capitalization with a protected list (`LLC`, `BBQ`, `ATX`, `SA`, `II`, `McX`/`O'X` patterns) and lowercase glue words (`of`, `and`, `the`) except leading. |
| `normalizeUrl` | Prepend `https://` if scheme missing, lowercase host, drop `utm_*`/`fbclid`, reject non-http(s) schemes. |
| `mapCategory` | Fuzzy match into the app's existing category vocabulary (the `category_chip`/`category_pill` components render a fixed set); unmatched → `Services` + issue flag so a human recategorizes. |
| `makeFingerprint` | `sha256(lower(alnum(name without legal suffixes)) + streetNumber + zip5)` — same idempotent-key pattern as `launch_subscribers`. |

The same module exports `promoteCandidate` (callable, admin-gated): copies
`clean` + `geo` into a new `BusinessesRecord` via the field names in
`createBusinessesRecordData`, mints the ticker with the existing
`generateUniqueTicker` logic, sets the verification flags per §2.3, marks the
candidate `promoted` with a `business_ref` back-link, and appends to
`activity_logs`.

---

## 5. User-Generated Growth — suggestions without clutter

**Feature:** "Suggest a business" — one screen in the app (and later the
website): name + city required, anything else optional, 30 seconds to finish.

**Anti-clutter logic (the whole design):**

1. **Suggestions are candidates, not businesses.** They enter
   `business_candidates` with `provenance: 'user_suggestion'` and sit behind
   the same review gate as everything else. The live directory cannot be
   cluttered by construction.
2. **Dedupe at the door.** The submit callable computes the fingerprint
   *before* writing. If it matches a live business → return "already on the
   Exchange — want to leave a review instead?" (converts noise into
   engagement). If it matches a pending candidate → **don't create a new doc**;
   increment `suggestion_count`, append the suggester to a `suggested_by`
   array. N duplicate suggestions become one strong candidate instead of N
   weak ones.
3. **Quorum promotes attention, not listings.** `suggestion_count >= 3` (from
   distinct users) bumps the candidate to the top of the review queue and
   qualifies it for `community_verified` *if approved* — the count never
   bypasses the human gate.
4. **Rate limiting** — max 5 suggestions per user per day (counter on the
   callable, same pattern as Power Hour's weekly limits), and suggestions
   require a signed-in account (`request.auth != null`), so the quorum can't
   be botted by anonymous traffic.
5. **Incentive loop (closes the flywheel):** when a suggested business is
   approved, the suggester(s) receive a `UserEngagementEventsRecord` of type
   `business_suggestion_approved` — the existing `kindex_engine.js` pays it
   out as KIN Score points (one new row in `kindex_config/scoring_weights`,
   zero new code). Users grow the directory because it grows their score.

---

## 6. From Promoted to **Featured**

Featured status is earned, never bought outright, and it's already mostly
built:

1. Promotion writes the listing; profile completeness (photo, hours,
   description) is displayed to owners as a checklist — complete profiles
   convert engagement better.
2. Engagement (reviews, connections, visits, Power Hours) flows through the
   existing `UserEngagementEvents → kindex_engine` loop and moves
   `kindex_score` / `kindex_velocity`.
3. `web_projection.publishWebProjection` (already deployed with the website
   work) takes the top-N by `kindex_score` into the public ticker and map;
   the app Spotlight and the website Spotlight rail read the same ranking.
4. Tie-breakers honor trust: at equal score, `kin_verified` outranks
   `self_attested`; `is_priority_pinned` (paid) may pin within Spotlight but
   never fakes a score.

**Full journey:** Google Form → `ingestBusinessCandidate` →
`business_candidates(submitted)` → `normalizeBusinessCandidate` (clean +
metro + dedupe) → automated verification checks → human approve →
`promoteCandidate` → `businesses` (flags per verification level) → engagement
→ Kindex → **Featured** in-app Spotlight + `web_public` ticker/map — with the
sign-up flash toast on the website announcing the arrival in real time.

---

## 7. Build Order

| Step | Deliverable | Reuses |
|---|---|---|
| 1 | `business_candidates` rules + `ingestBusinessCandidate` HTTPS function (Apps Script webhook from the Google Form) | `launch_subscribers.js` patterns |
| 2 | `normalizeBusinessCandidate` + helpers + unit tests | house transaction/idempotency style |
| 3 | Geocoding + metro resolver + `discovery_config/metros` | `kindex_config` pattern |
| 4 | Admin review queue (FlutterFlow page over candidates, `is_admin`-gated like `signup_feed`) | existing admin flag |
| 5 | `promoteCandidate` + reroute `KinServices.registerBusiness` through candidates | `generateUniqueTicker` |
| 6 | "Suggest a business" screen + callable + scoring-weight row | `kindex_engine`, rate-limit pattern |
| 7 | Seed-CSV backfill as `provenance: seed_directory` candidates; retire direct CSV imports | one-time script in `firebase/scripts/` |
