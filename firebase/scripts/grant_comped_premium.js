// Grants a business the same entitlement fields a real Elite-tier purchase
// would (see KinServices.upgradeBusinessTier in kin_services.dart), without
// going through RevenueCat/billing. Same dry-run/commit pattern as
// approve_claim.js and release_business.js.
//
// Fields mirror upgradeBusinessTier exactly:
//   subscription_tier   'Elite' - the top of kSubscriptionTierOrder
//                        (subscription_tiers.dart), so every tierAtLeast()
//                        gate in the app unlocks.
//   is_premium           true - what business_kindex_nightly.js reads for
//                        the 850-point tier baseline (vs 500 standard).
//   is_priority_pinned   true - premium map/search placement.
//   has_flash_beacon     true - Location Beacon feature gate.
//   trial_status         'converted' - matches a real purchase; keeps the
//                        14-day trial sweep (founding_local_trial.js) from
//                        ever touching this business.
//   trial_reminder_stage '' - clears any trial-ending reminder banner.
//
// Usage:
//   node grant_comped_premium.js <businessId>            # dry run
//   node grant_comped_premium.js <businessId> --commit    # apply it

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS
  || path.join(__dirname, 'serviceAccountKey.json');
const BUSINESSES = 'businesses';

const args = process.argv.slice(2);
const isCommit = args.includes('--commit');
const businessId = args.find((a) => !a.startsWith('--'));

const GRANT = {
  subscription_tier: 'Elite',
  is_premium: true,
  is_priority_pinned: true,
  has_flash_beacon: true,
  trial_status: 'converted',
  trial_reminder_stage: '',
};

function loadServiceAccount() {
  if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error(`Missing service account key at ${SERVICE_ACCOUNT_PATH}.`);
    process.exit(1);
  }
  return require(SERVICE_ACCOUNT_PATH);
}

function fmt(value) {
  if (value === null || value === undefined) return '(unset)';
  return String(value);
}

async function main() {
  if (!businessId) {
    console.error('Usage: node grant_comped_premium.js <businessId> [--commit]');
    process.exit(1);
  }

  const serviceAccount = loadServiceAccount();
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  const db = admin.firestore();

  console.log(`Project: ${serviceAccount.project_id}`);
  console.log(`Mode: ${isCommit ? 'COMMIT (will write)' : 'DRY RUN (no writes)'}`);
  console.log('');

  const businessRef = db.collection(BUSINESSES).doc(businessId);
  const snap = await businessRef.get();
  if (!snap.exists) {
    console.error(`No business with id ${businessId}.`);
    process.exit(1);
  }
  const business = snap.data();

  console.log(`Business: ${business.business_name} (${businessId})`);
  console.log('');
  console.log('Changes to apply:');
  for (const [key, value] of Object.entries(GRANT)) {
    console.log(`    ${key}  ${fmt(business[key])}  ->  ${fmt(value)}`);
  }

  if (!isCommit) {
    console.log('\nDry run only - re-run with --commit to apply.');
    return;
  }

  await businessRef.update(GRANT);
  console.log('\nGranted.');
  console.log(`"${business.business_name}" now has the same access as a real Elite subscriber, at no charge.`);
}

main().catch((err) => {
  console.error('Failed:', err);
  process.exit(1);
});
