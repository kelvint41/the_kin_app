// Reviews and grants business claims submitted from the app's Claim Business
// page (see lib/pages/claim_business/). Run manually from a developer machine
// with a service account key - same setup as import_businesses.js.
//
// Why this has to be server-side:
//   firestore.rules gates business updates on
//   `owner_ref == the signed-in user`, and every bulk-imported business has
//   owner_ref == null. So no client can ever grant itself ownership - that's
//   what stops someone claiming a business they don't run. Ownership can only
//   be conferred with the Admin SDK, which bypasses rules. This script is that
//   step.
//
// Why it matters:
//   exchange_posts rules require the poster to own a business AND for that
//   business to be is_verified. Until claims are approved, no business has an
//   owner, so The Exchange is unpostable for everyone. Approving claims is
//   what turns it on.
//
// Usage:
//   node approve_claim.js                      # list pending claims
//   node approve_claim.js <claimId>            # dry run - show the exact diff
//   node approve_claim.js <claimId> --commit   # apply it
//   node approve_claim.js <claimId> --commit --verify
//                                              # also set is_verified (see below)
//   node approve_claim.js <claimId> --reject --commit [--reason "..."]
//
// About --verify:
//   Approving a claim establishes *ownership*. `is_verified` is a separate
//   trust signal shown to users (and required by the exchange_posts rule), so
//   it is NOT set automatically - pass --verify when you've decided this
//   business should also carry the verified badge.

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS
  || path.join(__dirname, 'serviceAccountKey.json');
const BUSINESSES = 'businesses';
const CLAIM_REQUESTS = 'claim_requests';
const USERS = 'users';
const TICKER_REGISTRY = 'ticker_registry';

const args = process.argv.slice(2);
const isCommit = args.includes('--commit');
const isReject = args.includes('--reject');
const shouldVerify = args.includes('--verify');
const reasonIdx = args.indexOf('--reason');
const reason = reasonIdx !== -1 ? args[reasonIdx + 1] : null;
const claimId = args.find((a, i) => !a.startsWith('--') && args[i - 1] !== '--reason');

function loadServiceAccount() {
  if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error(
      `Missing service account key at ${SERVICE_ACCOUNT_PATH}.\n` +
      'Generate one from Firebase Console -> Project Settings -> Service Accounts,\n' +
      'save it as serviceAccountKey.json in this directory, or point\n' +
      'GOOGLE_APPLICATION_CREDENTIALS at it.'
    );
    process.exit(1);
  }
  return require(SERVICE_ACCOUNT_PATH);
}

function fmt(value) {
  if (value === null || value === undefined) return '(unset)';
  if (value && value.path) return `-> ${value.path}`;
  return String(value);
}

async function listPending(db) {
  const snap = await db.collection(CLAIM_REQUESTS)
    .where('status', '==', 'pending')
    .get();

  if (snap.empty) {
    console.log('No pending claims.');
    return;
  }
  console.log(`${snap.size} pending claim(s):\n`);
  snap.forEach((doc) => {
    const d = doc.data();
    console.log(`  ${doc.id}`);
    console.log(`    business : ${d.business_name || '(unknown)'} (${d.business_id})`);
    console.log(`    claimant : ${d.claimant_name || '(none)'}${d.claimant_role ? `, ${d.claimant_role}` : ''}`);
    console.log(`    contact  : ${d.contact_email || '(none)'}${d.contact_phone ? ` / ${d.contact_phone}` : ''}`);
    console.log(`    declares : black_owned=${!!d.declared_black_owned} veteran=${!!d.declared_veteran}`);
    console.log(`    proof    : ${d.verification_proof_link || '(none provided)'}`);
    console.log(`    attested : ${!!d.attested}${d.attested_at ? ` at ${d.attested_at.toDate().toISOString()}` : ''}`);
    console.log('');
  });
  console.log('Review the proof link and contact the claimant before approving.');
  console.log('Then: node approve_claim.js <claimId> --commit');
}

async function main() {
  const serviceAccount = loadServiceAccount();
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  const db = admin.firestore();

  console.log(`Project: ${serviceAccount.project_id}`);

  if (!claimId) {
    await listPending(db);
    return;
  }

  console.log(`Mode: ${isCommit ? 'COMMIT (will write)' : 'DRY RUN (no writes)'}`);
  console.log('');

  const claimRef = db.collection(CLAIM_REQUESTS).doc(claimId);
  const claimSnap = await claimRef.get();
  if (!claimSnap.exists) {
    console.error(`No claim_request with id ${claimId}.`);
    process.exit(1);
  }
  const claim = claimSnap.data();

  if (claim.status !== 'pending') {
    console.error(`Claim ${claimId} is already '${claim.status}' - refusing to act on it again.`);
    process.exit(1);
  }

  if (isReject) {
    console.log(`Rejecting claim ${claimId} for "${claim.business_name}".`);
    if (!isCommit) {
      console.log('\nDry run only - re-run with --commit to apply.');
      return;
    }
    await claimRef.update({
      status: 'rejected',
      reviewed_at: admin.firestore.FieldValue.serverTimestamp(),
      ...(reason ? { review_note: reason } : {}),
    });
    console.log('Rejected. The business is untouched and stays unclaimed.');
    return;
  }

  // --- Approval path -------------------------------------------------------
  if (!claim.attested) {
    console.error('Refusing: this claim has no ownership attestation on it.');
    process.exit(1);
  }
  if (!claim.business_id || !claim.applicant_user_id) {
    console.error('Refusing: claim is missing business_id or applicant_user_id.');
    process.exit(1);
  }

  const businessRef = db.collection(BUSINESSES).doc(claim.business_id);
  const userRef = db.collection(USERS).doc(claim.applicant_user_id);
  const [businessSnap, userSnap] = await Promise.all([businessRef.get(), userRef.get()]);

  if (!businessSnap.exists) {
    console.error(`Refusing: business ${claim.business_id} no longer exists.`);
    process.exit(1);
  }
  if (!userSnap.exists) {
    console.error(`Refusing: applicant user ${claim.applicant_user_id} has no users doc.`);
    process.exit(1);
  }

  const business = businessSnap.data();
  if (business.owner_ref) {
    console.error(
      `Refusing: "${business.business_name}" is already owned by ${business.owner_ref.path}.\n` +
      'Reject this claim instead, or resolve the conflict manually.'
    );
    process.exit(1);
  }

  const ticker = business.ticker_symbol;
  let reserveTicker = false;
  if (ticker) {
    const regSnap = await db.collection(TICKER_REGISTRY).doc(ticker).get();
    if (!regSnap.exists) {
      reserveTicker = true;
    } else {
      const holder = regSnap.get('owner_ref');
      console.log(`Note: ticker ${ticker} is already reserved by ${holder ? holder.path : '(unknown)'} - leaving it as is.`);
    }
  }

  console.log(`Claim   : ${claimId}`);
  console.log(`Business: ${business.business_name} (${claim.business_id})`);
  console.log(`Claimant: ${claim.claimant_name} <${claim.contact_email}>`);
  console.log(`Proof   : ${claim.verification_proof_link || '(none provided)'}`);
  console.log('');
  console.log('Changes to apply:');
  console.log(`  businesses/${claim.business_id}`);
  console.log(`    owner_ref          ${fmt(business.owner_ref)}  ->  -> ${userRef.path}`);
  console.log(`    is_claimed         ${fmt(business.is_claimed)}  ->  true`);
  console.log(`    claimed_by_user_id ${fmt(business.claimed_by_user_id)}  ->  ${claim.applicant_user_id}`);
  console.log(`    is_black_owned     ${fmt(business.is_black_owned)}  ->  ${!!claim.declared_black_owned}   (self-declared)`);
  console.log(`    is_veteran         ${fmt(business.is_veteran)}  ->  ${!!claim.declared_veteran}   (self-declared)`);
  if (shouldVerify) {
    console.log(`    is_verified        ${fmt(business.is_verified)}  ->  true   (--verify)`);
  } else {
    console.log(`    is_verified        ${fmt(business.is_verified)}  ->  unchanged`);
    console.log('      NOTE: exchange_posts rules require is_verified == true before');
    console.log('      this owner can post in The Exchange. Pass --verify to set it.');
  }
  console.log(`  users/${claim.applicant_user_id}`);
  console.log(`    owned_business     ${fmt(userSnap.get('owned_business'))}  ->  -> ${businessRef.path}`);
  if (reserveTicker) {
    console.log(`  ${TICKER_REGISTRY}/${ticker}  (create, reserving this business's ticker)`);
  }
  console.log(`  ${CLAIM_REQUESTS}/${claimId}`);
  console.log(`    status             pending  ->  approved`);

  if (!isCommit) {
    console.log('\nDry run only - re-run with --commit to apply.');
    return;
  }

  const batch = db.batch();
  batch.update(businessRef, {
    owner_ref: userRef,
    is_claimed: true,
    claimed_by_user_id: claim.applicant_user_id,
    is_black_owned: !!claim.declared_black_owned,
    is_veteran: !!claim.declared_veteran,
    ...(shouldVerify ? { is_verified: true } : {}),
  });
  batch.update(userRef, { owned_business: businessRef });
  if (reserveTicker) {
    batch.create(db.collection(TICKER_REGISTRY).doc(ticker), {
      owner_ref: businessRef,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  batch.update(claimRef, {
    status: 'approved',
    reviewed_at: admin.firestore.FieldValue.serverTimestamp(),
  });
  await batch.commit();

  console.log('\nApproved.');
  console.log(`${claim.claimant_name} can now edit "${business.business_name}" from the app.`);
  if (!shouldVerify) {
    console.log('They still cannot post in The Exchange until is_verified is true.');
  }
}

main().catch((err) => {
  console.error('Failed:', err);
  process.exit(1);
});
