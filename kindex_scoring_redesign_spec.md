# Kindex Business Scoring — Anti-Manipulation Redesign Spec

**Project:** KIN App (kinvest-build-app)
**Date:** July 26, 2026
**Branch:** claude/business-kindex-auto-update-k8lfup (or a new branch off it)
**Owner decision-maker:** Kelvin Taylor

## Background / Problem

The current `processBusinessReview` Cloud Function (in
`firebase/custom_cloud_functions/business_kindex_engine.js`) applies a fixed
+15/-15 score change to a business's `kindex_score` every time a review
document is created in the `reviews` collection, triggered on
`reviews/{reviewId}` creation.

This has no protection against manipulation:
- A single customer can leave unlimited reviews for the same business,
  each one independently swinging the score.
- There is no requirement that the reviewer actually visited/patronized
  the business — anyone can review any business with no verification.
- A malicious actor (or a business owner farming their own score, or a
  competitor tanking a rival's score) can currently move `kindex_score`
  by an unbounded amount with repeated review submissions.

This must be fixed before launch, since `kindex_score` is a core
trust/discovery signal shown to shoppers.

## Desired behavior (confirmed with product owner, July 26 2026)

1. **Reviews always post live**, exactly as today — text, star rating,
   and photos appear on the business profile immediately upon submission.
   Nothing about the review *display* changes.

2. **Only reviews tied to a verified visit affect `kindex_score`.**
   - If a customer submits a review without a verified visit/check-in
     for that business, the review still displays normally but must be
     excluded from score calculation entirely.
   - "Verified visit" should use the existing `user_visits` Firestore
     collection if it already captures check-ins reliably (GPS-based,
     QR code, purchase confirmation — whichever mechanism the app
     currently uses). **Needs investigation** — see Open Questions below.

3. **Only a customer's highest-rated review in a trailing 7-day window
   counts toward the score**, per business. If the same (verified)
   customer visits and reviews the same business multiple times within
   7 days, only their single highest star rating in that window is used
   in the score calculation for that business. Lower-rated repeat
   reviews from the same customer in that window still display on the
   business profile, but do not additionally move the score (positively
   or negatively).

4. **`kindex_score` is recalculated once per day via a scheduled batch
   job, not reactively per-review.** Recommended approach:
   - Replace (or supplement) the current `onCreate` trigger on
     `reviews/{reviewId}` with a Cloud Scheduler–triggered function that
     runs nightly (e.g., 2:00 AM local time, adjust as needed).
   - For each business, the nightly job:
     a. Pulls all *verified-visit* reviews for that business from the
        trailing 7-day window.
     b. Groups by customer, keeps only each customer's highest star
        rating in that window.
     c. Recomputes `kindex_score` from scratch using the existing
        scoring formula (ported from `calculate_real_time_kindex.dart`
        — same point values, same tier-specific baselines/maximums as
        already implemented).
     d. Writes the new `kindex_score` (and updates `kindex_velocity`
        using the existing, already-correct logic for that field —
        do NOT touch how `kindex_velocity` is calculated, only
        `kindex_score`).
   - This eliminates the need for delta-tracking/undo logic on review
     edits — since the score is recomputed from scratch nightly, edits
     are naturally absorbed into the next run with no special-case code.

5. **Review edits remain simple.** Customers can edit an existing
   review (text and/or star rating) at any time. Because scoring is now
   a nightly batch recompute rather than a reactive per-review delta,
   edits do not require special handling for score integrity — the next
   nightly run will simply reflect whatever the review's current state
   is at that time, gated by the same verified-visit + 7-day-highest
   rules above.
   - A lightweight edit cap (e.g., limit to 2–3 edits per review) is
     still recommended, but purely to prevent review-text spam/abuse —
     it is NOT load-bearing for score-manipulation prevention anymore,
     since the nightly recompute handles that.

6. **One review document per customer per business**, not one per
   visit. Use a predictable/composite document ID
   (e.g., `{businessId}_{customerId}`) instead of an auto-generated ID,
   so that a customer's "new" review submission for a business they've
   already reviewed becomes an *update* to their existing review
   document rather than a new document. This keeps the reviews
   collection clean (no duplicate review spam) and makes the 7-day
   highest-rating logic in step 3 simpler to query.
   - **Note:** this may require a data migration/dedup pass on existing
     review documents that don't follow this ID scheme yet. Flag this
     to the user before altering document IDs on existing data —
     do not silently delete/merge existing reviews without a reviewed
     migration plan.

## Explicitly out of scope for this task

- Do not change how `kindex_velocity` is calculated.
- Do not change the *customer-side* Kindex system
  (`kindex_engine.js` / `processUserEngagementEvent`) — this spec is
  business-side scoring only.
- Do not change review display/UI unless required to show a "verified
  visit" badge (optional nice-to-have, not required for this fix).

## Open questions — RESOLVED (July 26, 2026)

1. **Does `user_visits` already reliably capture real visits/check-ins
   today? RESOLVED: NO.** The `user_visits` collection exists in the
   Firestore schema (fields: `user_ref`, `business_ref`,
   `visit_timestamp`) but has zero references anywhere in the Dart
   codebase (confirmed via
   `grep -rln "user_visits\|UserVisitsRecord\|createUserVisits" lib/`
   — no results). Nothing currently writes to this collection. This is
   the same pattern found earlier this session with `hero_image` and
   `google_place_id`: a schema field defined in FlutterFlow but never
   wired to any actual app logic.

   **DECISION (July 26, 2026): Option A — build visit verification
   first, using on-demand GPS check-in.** Product owner explicitly
   wants this done right the first time rather than deferring to V2.

   **Verification mechanism: on-demand (not continuous) GPS check.**
   - Add a "Check In" / "I'm Here" button on the business profile page
     (placed near where the customer would leave a review).
   - Tapping it triggers a single, one-time location read — NOT
     continuous background location tracking. No background service,
     no meaningful battery impact. This is the same permission model
     as "share my location for this order," requested only at the
     moment of the tap.
   - Compare that single GPS reading against the business's stored
     address/coordinates. If within a small radius (suggest 100
     meters, adjustable), write a `user_visits` document
     (`user_ref`, `business_ref`, `visit_timestamp`) and unlock the
     ability to leave a review that counts toward `kindex_score` for
     that business.
   - A review can still be submitted without a check-in (keeps the
     review always-postable per point 1 of this spec), but only
     check-in-verified reviews count toward score, per point 2.
   - GPS permission handling: if the customer denies location
     permission, the Check In button should clearly explain why it's
     needed (verifying real visits protects the integrity of business
     scores) and reviews can still be left, just uncounted, same as
     any other unverified review.

2. Confirm exact nightly run time (suggest low-traffic hours, e.g.
   2:00–4:00 AM Central, matching San Antonio launch market).
3. Confirm edit cap number (2 edits total suggested as a starting
   point, purely as an anti-spam measure per point 5 above).
4. Decide whether to show any "pending" UI indicator to business owners
   when new (uncounted-yet) reviews have come in since the last nightly
   recompute — optional, not required for correctness.

## Suggested implementation order

1. ~~Investigate `user_visits`~~ — DONE, see Open Questions above.
   Confirmed unused; building check-in verification is now step 2.
2. **Build the on-demand GPS check-in feature first** (Check In button
   on business profile → single location read → radius check against
   business address → write `user_visits` document). This is the new
   prerequisite and should be built and tested on its own before
   touching scoring logic.
3. Update review submission logic to use composite document IDs
   (`{businessId}_{customerId}`), handling the existing-reviews
   migration question (see point 6 of main spec above).
4. Update review submission to check for a recent `user_visits` match
   before allowing a review to count toward score (gate per point 2).
5. Build the nightly scheduled Cloud Function that recomputes
   `kindex_score` per business per the rules in point 4 of the main
   spec (verified-visit + 7-day-highest-per-customer).
6. Remove or disable the old reactive `onCreate` scoring trigger in
   `processBusinessReview` (reviews should still be created/stored
   normally — only the *scoring side effect* moves to the nightly job).
7. Update Firestore rules if needed to support the new document ID
   scheme and to protect `user_visits` from being spoofed/written
   directly by a client without going through the verified check-in
   flow (client should not be able to write arbitrary `user_visits`
   documents claiming a visit that didn't happen).
8. Test end-to-end: verify a customer must check in (GPS-verified)
   before their review counts toward score; verify repeated same-week
   reviews from one verified customer only count once (highest
   rating); verify unverified-visit reviews still post but don't move
   the score; verify the nightly job runs and produces correct scores
   against a few test businesses; verify denying location permission
   still allows posting a review (just uncounted).
