/**
 * Grants or revokes the `is_admin` flag on a user document.
 *
 * Firestore rules deliberately block clients from writing `is_admin` to
 * themselves (see firebase/firestore.rules) - the Admin SDK is the only
 * way in, which is the point. That also makes this script the audit trail
 * for who has it, so it prints the before/after state rather than writing
 * silently.
 *
 *   node grant_admin.js <email>            # grant
 *   node grant_admin.js <email> --revoke   # revoke
 */
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const email = process.argv[2];
const revoke = process.argv.includes('--revoke');

if (!email) {
  console.error('Usage: node grant_admin.js <email> [--revoke]');
  process.exit(1);
}

(async () => {
  const snap = await db.collection('users').where('email', '==', email).get();

  if (snap.empty) {
    console.error(`No user document with email ${email}.`);
    process.exit(1);
  }
  if (snap.size > 1) {
    // Refuse rather than guess: granting admin to the wrong one of two
    // documents sharing an email is not a mistake worth making silently.
    console.error(`${snap.size} user documents share ${email}: ` +
      `${snap.docs.map((d) => d.id).join(', ')}. Resolve the duplicates first.`);
    process.exit(1);
  }

  const doc = snap.docs[0];
  const before = doc.data().is_admin;
  const after = !revoke;

  if (before === after) {
    console.log(`${email} (${doc.id}) already has is_admin=${after}. No write.`);
    process.exit(0);
  }

  await doc.ref.update({ is_admin: after });
  console.log(`${email} (${doc.id}): is_admin ${before} -> ${after}`);

  const all = await db.collection('users').where('is_admin', '==', true).get();
  console.log(`Admins now (${all.size}): ` +
    all.docs.map((d) => d.data().email || d.id).join(', '));
  process.exit(0);
})().catch((e) => { console.error(e); process.exit(1); });
