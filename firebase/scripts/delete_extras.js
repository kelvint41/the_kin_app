const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// SET THIS TO FALSE WHEN YOU ARE READY TO DELETE FOR REAL
const DRY_RUN = false; 

async function cleanup() {
  const localData = JSON.parse(fs.readFileSync('my_data.json', 'utf8'));
  const localBusinessNames = new Set(localData.map(item => item.business_name));

  console.log(`Running in ${DRY_RUN ? 'DRY RUN' : 'DELETE'} mode...`);

  // Using the collection name you found: 'businesses'
  const snapshot = await db.collection('businesses').get();
  
  let count = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    if (!localBusinessNames.has(data.business_name)) {
      console.log(`${DRY_RUN ? '[Would Delete]' : 'Deleting'}: ${data.business_name}`);
      if (!DRY_RUN) {
        await doc.ref.delete();
      }
      count++;
    }
  }

  console.log(`${DRY_RUN ? 'Dry run complete' : 'Cleanup complete'}. Total items to remove: ${count}`);
  process.exit();
}

cleanup();