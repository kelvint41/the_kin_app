// Reverses an approved business claim, returning the business, the owning
// user, and the claim request to their pre-claim state.
//
// Why this exists: approve_claim.js confers ownership of a real business
// listing on a real account. A claim approved against the wrong business -
// or staged for testing and then approved by mistake - leaves that listing
// showing as claimed and verified by someone who does not run it. There has
// to be an undo, and it has to be as auditable as the approval was.
//
// What it reverses, mirroring approve_claim.js exactly:
//   businesses/<id>   owner_ref, is_claimed, claimed_by_user_id, is_verified
//   users/<uid>       owned_business
//   claim_requests/<claimId>   deleted
//
// What it deliberately does NOT touch:
//   - is_black_owned / is_certified_black_owned. Certification comes from
//     the BOB Bexar list, not from the claim, and survives a reverted claim.
//     Undoing it here would destroy sourced data over an unrelated mistake.
//   - subscription_tier / is_premium. approve_claim.js never sets these, so
//     there is nothing for this to put back.
//   - ticker_registry. The reservation belongs to the business and predates
//     the claim.
//
// Usage:
//   node revert_claim.js <claimId>            # dry run - shows the diff
//   node revert_claim.js <claimId> --commit   # applies the reversal
//
// Safety:
//   - Defaults to dry run; --commit is required to write.
//   - Refuses if the business's owner_ref does not match the claim's
//     applicant. That would mean ownership changed after approval, and
//     blindly unsetting it could strip a legitimate owner.
//   - Writes revert_claim_results.json recording the full prior state, so
//     the reversal is itself reversible.

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS
  || path.join(__dirname, 'serviceAccountKey.json');
const RESULTS_LOG_PATH = path.join(__dirname, 'revert_claim_results.json');
const BUSINESSES = 'businesses';
const CLAIM_REQUESTS = 'claim_requests';
const USERS = 'users';

const args = process.argv.slice(2);
const isCommit = args.includes('--commit');
const claimId = args.find((a) => !a.startsWith('--'));

function loadServiceAccount() {
  if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error(`Missing service account key at ${SERVICE_ACCOUNT_PATH}.`);
    process.exit(1);
  }
  return require(SERVICE_ACCOUNT_PATH);
}

const fmt = (v) => {
  if (v === undefined) return '(unset)';
  if (v === null) return 'null';
  if (v && v.path) return `-> ${v.path}`;
  return JSON.stringify(v);
};

async function main() {
  if (!claimId) {
    console.error('Usage: node revert_claim.js <claimId> [--commit]');
    process.exit(1);
  }

  const serviceAccount = loadServiceAccount();
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  const db = admin.firestore();

  console.log(`Project: ${serviceAccount.project_id}`);
  console.log(`Mode: ${isCommit ? 'COMMIT (will write to Firestore)' : 'DRY RUN (no writes)'}`);

  const claimRef = db.collection(CLAIM_REQUESTS).doc(claimId);
  const claimSnap = await claimRef.get();
  if (!claimSnap.exists) {
    console.error(`No claim_request with id ${claimId}.`);
    process.exit(1);
  }
  const claim = claimSnap.data();

  const businessRef = db.collection(BUSINESSES).doc(claim.business_id);
  const businessSnap = await businessRef.get();
  if (!businessSnap.exists) {
    console.error(`Claim points at businesses/${claim.business_id}, which does not exist.`);
    process.exit(1);
  }
  const business = businessSnap.data();

  const userRef = db.collection(USERS).doc(claim.applicant_user_id);
  const userSnap = await userRef.get();
  const user = userSnap.exists ? userSnap.data() : null;

  // Ownership must still be the applicant's, or this is not ours to undo.
  const expectedOwnerPath = `users/${claim.applicant_user_id}`;
  const actualOwnerPath = business.owner_ref ? business.owner_ref.path : null;
  if (actualOwnerPath !== expectedOwnerPath) {
    console.error(
      `Refusing: businesses/${claim.business_id} owner_ref is ${actualOwnerPath || '(unset)'}, `
      + `not ${expectedOwnerPath}.\n`
      + 'Ownership changed after this claim was approved - reverting could strip a\n'
      + 'legitimate owner. Resolve by hand.'
    );
    process.exit(1);
  }

  console.log(`\nClaim   : ${claimId}  (status=${claim.status}, source=${claim.source || 'app form'})`);
  console.log(`Business: ${business.business_name} (${claim.business_id})`);
  console.log(`Claimant: ${claim.claimant_name} <${claim.contact_email}>`);

  console.log('\nChanges to apply:');
  console.log(`  businesses/${claim.business_id}`);
  console.log(`    owner_ref          ${fmt(business.owner_ref)}  ->  (unset)`);
  console.log(`    is_claimed         ${fmt(business.is_claimed)}  ->  false`);
  console.log(`    claimed_by_user_id ${fmt(business.claimed_by_user_id)}  ->  (unset)`);
  console.log(`    is_verified        ${fmt(business.is_verified)}  ->  false`);
  console.log(`  users/${claim.applicant_user_id}`);
  console.log(`    owned_business     ${user ? fmt(user.owned_business) : '(user missing)'}  ->  (unset)`);
  console.log(`  claim_requests/${claimId}`);
  console.log(`    status             ${fmt(claim.status)}  ->  DELETED`);

  console.log('\nLeft untouched (not set by the claim):');
  console.log(`    is_black_owned            ${fmt(business.is_black_owned)}`);
  console.log(`    is_certified_black_owned  ${fmt(business.is_certified_black_owned)}`);
  console.log(`    certification_source      ${fmt(business.certification_source)}`);
  console.log(`    subscription_tier         ${fmt(business.subscription_tier)}`);
  console.log(`    is_premium                ${fmt(business.is_premium)}`);

  const results = {
    mode: isCommit ? 'commit' : 'dry-run',
    claim_id: claimId,
    business_id: claim.business_id,
    business_name: business.business_name,
    // Full prior state, so this reversal can itself be undone.
    prior_state: {
      business: {
        owner_ref: actualOwnerPath,
        is_claimed: business.is_claimed ?? null,
        claimed_by_user_id: business.claimed_by_user_id ?? null,
        is_verified: business.is_verified ?? null,
      },
      user: {
        uid: claim.applicant_user_id,
        owned_business: user && user.owned_business ? user.owned_business.path : null,
      },
      claim,
    },
  };

  if (!isCommit) {
    fs.writeFileSync(RESULTS_LOG_PATH, JSON.stringify(results, null, 2));
    console.log(`\nPlan written to ${RESULTS_LOG_PATH}`);
    console.log('Dry run only - re-run with --commit to apply.');
    return;
  }

  const del = admin.firestore.FieldValue.delete();
  const batch = db.batch();
  batch.update(businessRef, {
    owner_ref: del,
    is_claimed: false,
    claimed_by_user_id: del,
    is_verified: false,
  });
  if (userSnap.exists) {
    batch.update(userRef, { owned_business: del });
  }
  batch.delete(claimRef);
  await batch.commit();

  fs.writeFileSync(RESULTS_LOG_PATH, JSON.stringify(results, null, 2));
  console.log(`\nReverted. "${business.business_name}" is unclaimed and unverified again.`);
  console.log(`Prior state recorded in ${RESULTS_LOG_PATH}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
