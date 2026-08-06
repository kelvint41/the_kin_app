const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}
const { FieldValue } = require("firebase-admin/firestore");

/// `blackOwned`/`veteran` are optional overrides from the reviewing admin;
/// when omitted (not just falsy - `false` is a real override), falls back
/// to what the claimant self-declared. Pulled out as its own function,
/// same reasoning as business_discovery.js's normalizeName/findsDuplicate,
/// so this one piece of real decision logic can be unit tested without
/// the Firestore emulator the rest of this file needs.
function resolveBlackOwnedAndVeteran(claim, { blackOwned, veteran } = {}) {
  return {
    blackOwned: typeof blackOwned === "boolean" ? blackOwned : !!claim.declared_black_owned,
    veteran: typeof veteran === "boolean" ? veteran : !!claim.declared_veteran,
  };
}

/**
 * Approves or rejects a pending business claim. Admin only.
 *
 * This is the in-app counterpart to firebase/scripts/approve_claim.js,
 * which stays in place as a still-valid manual/terminal fallback - the two
 * duplicate each other's business rules on purpose (same guards, same
 * fields) rather than one wrapping the other, since the script runs
 * standalone with a service account key and has no way to call into a
 * deployed function. If the approval rules ever change, both need the
 * update.
 *
 * Why this can't be a client-side write at all, approve or reject:
 * claim_requests is `read: false`-adjacent for writes (create-only from
 * clients - see firestore.rules) precisely because approving one means
 * granting `businesses.owner_ref`, which firestore.rules can never let a
 * client set on their own claim (that's what stops someone claiming a
 * business they don't run). Only the Admin SDK, running here, can do it.
 *
 * `blackOwned`/`veteran` default to the claimant's own declared_* values
 * but are deliberately separate parameters, not hardcoded to them - the
 * admin reviewing the claim (lib/pages/admin_claim_review/) can override
 * either before confirming, so approval is a real decision about the
 * business's status, not a blind copy of a checkbox nobody verified.
 */
exports.resolveClaimRequest = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const db = admin.firestore();
  const callerSnap = await db.doc(`users/${uid}`).get();
  if (!callerSnap.exists || callerSnap.data().is_admin !== true) {
    throw new HttpsError("permission-denied", "Admin access required.");
  }

  const { claimId, action, blackOwned, veteran, verify, reviewNote } =
    request.data || {};
  if (typeof claimId !== "string" || !claimId.trim()) {
    throw new HttpsError("invalid-argument", "claimId is required.");
  }
  if (action !== "approve" && action !== "reject") {
    throw new HttpsError("invalid-argument", "action must be approve or reject.");
  }

  const claimRef = db.collection("claim_requests").doc(claimId);
  const claimSnap = await claimRef.get();
  if (!claimSnap.exists) {
    throw new HttpsError("not-found", "That claim no longer exists.");
  }
  const claim = claimSnap.data();

  // Idempotency/race guard - same refusal approve_claim.js has, so a
  // double-tap (or someone else already having resolved it) can't
  // double-process a claim.
  if (claim.status !== "pending") {
    throw new HttpsError(
      "failed-precondition",
      `This claim is already '${claim.status}'.`,
    );
  }

  if (action === "reject") {
    await claimRef.update({
      status: "rejected",
      reviewed_at: FieldValue.serverTimestamp(),
      reviewed_by: db.doc(`users/${uid}`),
      ...(reviewNote ? { review_note: String(reviewNote) } : {}),
    });
    return {
      success: true,
      action: "rejected",
      businessName: claim.business_name || "",
    };
  }

  // --- Approval path, mirrors approve_claim.js's approval branch --------
  if (!claim.attested) {
    throw new HttpsError(
      "failed-precondition",
      "This claim has no ownership attestation on it.",
    );
  }
  if (!claim.business_id || !claim.applicant_user_id) {
    throw new HttpsError(
      "failed-precondition",
      "Claim is missing business_id or applicant_user_id.",
    );
  }

  const businessRef = db.collection("businesses").doc(claim.business_id);
  const userRef = db.collection("users").doc(claim.applicant_user_id);
  const [businessSnap, userSnap] = await Promise.all([
    businessRef.get(),
    userRef.get(),
  ]);

  if (!businessSnap.exists) {
    throw new HttpsError("not-found", "That business no longer exists.");
  }
  if (!userSnap.exists) {
    throw new HttpsError(
      "failed-precondition",
      "The applicant has no user record.",
    );
  }

  const business = businessSnap.data();
  if (business.owner_ref) {
    throw new HttpsError(
      "failed-precondition",
      `"${business.business_name}" is already owned by someone else. ` +
        "Reject this claim instead, or resolve the conflict manually.",
    );
  }

  const { blackOwned: resolvedBlackOwned, veteran: resolvedVeteran } =
    resolveBlackOwnedAndVeteran(claim, { blackOwned, veteran });

  const ticker = business.ticker_symbol;
  let reserveTicker = false;
  if (ticker) {
    const regSnap = await db.collection("ticker_registry").doc(ticker).get();
    reserveTicker = !regSnap.exists;
  }

  const batch = db.batch();
  batch.update(businessRef, {
    owner_ref: userRef,
    is_claimed: true,
    claimed_by_user_id: claim.applicant_user_id,
    is_black_owned: resolvedBlackOwned,
    is_veteran: resolvedVeteran,
    ...(verify === true ? { is_verified: true } : {}),
  });
  batch.update(userRef, { owned_business: businessRef });
  if (reserveTicker) {
    batch.create(db.collection("ticker_registry").doc(ticker), {
      owner_ref: businessRef,
      created_at: FieldValue.serverTimestamp(),
    });
  }
  batch.update(claimRef, {
    status: "approved",
    reviewed_at: FieldValue.serverTimestamp(),
    reviewed_by: db.doc(`users/${uid}`),
  });
  await batch.commit();

  return {
    success: true,
    action: "approved",
    businessName: business.business_name || claim.business_name || "",
  };
});

exports._internals = { resolveBlackOwnedAndVeteran };
