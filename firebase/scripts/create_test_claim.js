// Creates a claim_requests document directly, for exercising the approval
// path without going through the in-app form.
//
// Why this exists: the Claim Business form writes claim_requests from the
// client, but reaching a specific business's profile depends on tapping its
// map pin, and several businesses share exact coordinates (The Big Bib and
// Techesive sit on the same point), so a given listing is not always
// reachable. This lets an operator stage a claim for a named business.
//
// This is NOT a substitute for the real form. A claim created here records
// source: 'operator-test' so it can never be mistaken for a genuine public
// submission, and so these can be found and removed later.
//
// Usage:
//   node create_test_claim.js <businessId>            # dry run
//   node create_test_claim.js <businessId> --commit   # writes the claim
//
// Safety:
//   - Defaults to dry run; --commit is required to write.
//   - Refuses if the business already has an owner, or if a pending claim
//     for it already exists.

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS
  || path.join(__dirname, 'serviceAccountKey.json');
const BUSINESSES = 'businesses';
const CLAIM_REQUESTS = 'claim_requests';
const USERS = 'users';

const args = process.argv.slice(2);
const isCommit = args.includes('--commit');
const businessId = args.find((a) => !a.startsWith('--'));

const APPLICANT_UID = process.env.CLAIM_APPLICANT_UID
  || 'kYpDYaJXD2RlmyDrv7Up8vFjIjs2';

function loadServiceAccount() {
  if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error(`Missing service account key at ${SERVICE_ACCOUNT_PATH}.`);
    process.exit(1);
  }
  return require(SERVICE_ACCOUNT_PATH);
}

async function main() {
  if (!businessId) {
    console.error('Usage: node create_test_claim.js <businessId> [--commit]');
    process.exit(1);
  }

  const serviceAccount = loadServiceAccount();
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  const db = admin.firestore();

  console.log(`Project: ${serviceAccount.project_id}`);
  console.log(`Mode: ${isCommit ? 'COMMIT (will write)' : 'DRY RUN (no writes)'}`);

  const businessRef = db.collection(BUSINESSES).doc(businessId);
  const businessSnap = await businessRef.get();
  if (!businessSnap.exists) {
    console.error(`No business with id ${businessId}.`);
    process.exit(1);
  }
  const business = businessSnap.data();

  if (business.owner_ref) {
    console.error(`Refusing: "${business.business_name}" is already owned by ${business.owner_ref.path}.`);
    process.exit(1);
  }

  const existing = await db.collection(CLAIM_REQUESTS)
    .where('business_id', '==', businessId)
    .where('status', '==', 'pending')
    .get();
  if (!existing.empty) {
    console.error(`Refusing: a pending claim for this business already exists (${existing.docs[0].id}).`);
    process.exit(1);
  }

  const userSnap = await db.collection(USERS).doc(APPLICANT_UID).get();
  if (!userSnap.exists) {
    console.error(`No user with uid ${APPLICANT_UID}.`);
    process.exit(1);
  }
  const user = userSnap.data();

  const claim = {
    business_id: businessId,
    business_name: business.business_name,
    applicant_user_id: APPLICANT_UID,
    claimant_name: user.display_name || user.email || 'KIN operator',
    claimant_role: 'Owner',
    contact_email: user.email || '',
    contact_phone: business.phone_number || '',
    verification_proof_link: '',
    attested: true,
    attested_at: admin.firestore.FieldValue.serverTimestamp(),
    declared_black_owned: business.is_certified_black_owned === true,
    declared_veteran: false,
    status: 'pending',
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    // Marks this as operator-staged rather than a public submission.
    source: 'operator-test',
  };

  console.log(`\nBusiness: ${business.business_name} (${business.city})`);
  console.log(`  ticker=${business.ticker_symbol} tier=${business.subscription_tier}`);
  console.log(`  owner_ref=${business.owner_ref || 'none'} is_verified=${business.is_verified}`);
  console.log('\nClaim to create:');
  Object.entries(claim).forEach(([k, v]) => {
    const shown = (v && v.constructor && v.constructor.name === 'FieldValue')
      ? '<serverTimestamp>' : JSON.stringify(v);
    console.log(`  ${k} = ${shown}`);
  });

  if (!isCommit) {
    console.log('\nDry run only - re-run with --commit to create it.');
    return;
  }

  const ref = await db.collection(CLAIM_REQUESTS).add(claim);
  console.log(`\nCreated claim ${ref.id}`);
  console.log(`Next: node approve_claim.js ${ref.id}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
