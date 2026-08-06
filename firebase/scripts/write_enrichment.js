const admin = require('firebase-admin');
admin.initializeApp();

(async () => {
  const db = admin.firestore();
  const rows = require('/private/tmp/claude-501/-Users-jasmineknowles-taylor-KINVEST-Development-the-kin-app-2/3f51cc0c-7ad9-4678-a893-6c7f31106036/scratchpad/norbcc_enriched.json');

  let updated = 0;
  const CHUNK = 200;
  for (let start = 0; start < rows.length; start += CHUNK) {
    const chunk = rows.slice(start, start + CHUNK);
    const batch = db.batch();
    for (const r of chunk) {
      const update = {};
      if (r.website) update.website = r.website;
      if (typeof r.rating === 'number') update.review_score = r.rating;
      if (r.opening_time) update.opening_time = r.opening_time;
      if (Object.keys(update).length === 0) continue;
      batch.update(db.collection('businesses').doc(r.docId), update);
      updated += 1;
    }
    await batch.commit();
    console.log(`Committed ${Math.min(start + CHUNK, rows.length)}/${rows.length}`);
  }
  console.log(`Updated ${updated} businesses.`);
})();
