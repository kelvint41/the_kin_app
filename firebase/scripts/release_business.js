// Releases a claimed business back to unclaimed, so a different person can
// claim it correctly through the normal in-app Claim Business flow. Same
// setup and safety conventions as approve_claim.js: dry run by default,
// --commit required to write, service account key from this directory.
//
// Why this exists:
//   approve_claim.js refuses to approve a claim onto a business that
//   already has an owner_ref - by design, so a claim can never silently
//   clobber an existing owner. When a business was claimed by the wrong
//   account (a placeholder, a mixed-up test account, someone who signed up
//   before the actual owner did), there was no script to undo that and
//   hand it back to "unclaimed" - this is that release step.
//
// What it does NOT do:
//   It does not assign a new owner. Ownership is deliberately left empty
//   so the real owner claims it themselves through the app's Claim
//   Business flow (attesting ownership), which is what actually creates
//   the audit trail (claim_requests) - this script only undoes the wrong
//   claim.
//
// Usage:
//   node release_business.js <businessId>              # dry run
//   node release_business.js <businessId> --commit      # apply it

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS
  || path.join(__dirname, 'serviceAccountKey.json');
const BUSINESSES = 'businesses';
const USERS = 'users';

const args = process.argv.slice(2);
const isCommit = args.includes('--commit');
const businessId = args.find((a) => !a.startsWith('--'));

function loadServiceAccount() {
  if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error(`Missing service account key at ${SERVICE_ACCOUNT_PATH}.`);
    process.exit(1);
  }
  return require(SERVICE_ACCOUNT_PATH);
}

function fmt(value) {
  if (value === null || value === undefined) return '(unset)';
  if (value && value.path) return `-> ${value.path}`;
  return String(value);
}

async function main() {
  if (!businessId) {
    console.error('Usage: node release_business.js <businessId> [--commit]');
    process.exit(1);
  }

  const serviceAccount = loadServiceAccount();
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  const db = admin.firestore();

  console.log(`Project: ${serviceAccount.project_id}`);
  console.log(`Mode: ${isCommit ? 'COMMIT (will write)' : 'DRY RUN (no writes)'}`);
  console.log('');

  const businessRef = db.collection(BUSINESSES).doc(businessId);
  const businessSnap = await businessRef.get();
  if (!businessSnap.exists) {
    console.error(`No business with id ${businessId}.`);
    process.exit(1);
  }
  const business = businessSnap.data();

  if (!business.owner_ref) {
    console.error(`"${business.business_name}" has no owner_ref - it's already unclaimed. Nothing to release.`);
    process.exit(1);
  }

  const ownerRef = business.owner_ref;
  const ownerSnap = await ownerRef.get();
  const owner = ownerSnap.exists ? ownerSnap.data() : null;

  console.log(`Business: ${business.business_name} (${businessId})`);
  console.log(`Current owner: ${ownerRef.path}${owner ? ` <${owner.email || 'no email'}>` : ' (user doc missing)'}`);
  console.log('');
  console.log('Changes to apply:');
  console.log(`  businesses/${businessId}`);
  console.log(`    owner_ref          ${fmt(business.owner_ref)}  ->  (unset)`);
  console.log(`    is_claimed         ${fmt(business.is_claimed)}  ->  false`);
  console.log(`    claimed_by_user_id ${fmt(business.claimed_by_user_id)}  ->  (unset)`);
  if (owner && ownerSnap.exists) {
    console.log(`  ${ownerRef.path}`);
    console.log(`    owned_business     ${fmt(owner.owned_business)}  ->  (unset)`);
  } else {
    console.log(`  (owner user doc ${ownerRef.path} does not exist - skipping its owned_business field)`);
  }

  if (!isCommit) {
    console.log('\nDry run only - re-run with --commit to apply.');
    return;
  }

  const batch = db.batch();
  batch.update(businessRef, {
    owner_ref: admin.firestore.FieldValue.delete(),
    is_claimed: false,
    claimed_by_user_id: admin.firestore.FieldValue.delete(),
  });
  if (owner && ownerSnap.exists) {
    batch.update(ownerRef, {
      owned_business: admin.firestore.FieldValue.delete(),
    });
  }
  await batch.commit();

  console.log('\nReleased.');
  console.log(`"${business.business_name}" is unclaimed and can now be claimed through the app's Claim Business flow.`);
}

main().catch((err) => {
  console.error('Failed:', err);
  process.exit(1);
});
