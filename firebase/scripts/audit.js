const fs = require('fs');

function runAudit() {
    const masterData = JSON.parse(fs.readFileSync('my_data.json', 'utf8'));
    const firestoreData = JSON.parse(fs.readFileSync('migration_data.json', 'utf8'));

    // Use "business_name" instead of "name"
    const masterNames = new Set(masterData.map(item => item.business_name));
    
    // Find records in Firestore that are NOT in the Master List
    const extraRecords = firestoreData.filter(item => !masterNames.has(item.business_name));

    console.log(`\n--- Audit Results ---`);
    console.log(`Master List (CSV): ${masterData.length} records`);
    console.log(`Firestore List: ${firestoreData.length} records`);
    console.log(`Extra records in Firestore: ${extraRecords.length}`);

    if (extraRecords.length > 0) {
        console.log('\nList of extra records in Firestore:');
        extraRecords.slice(0, 10).forEach(item => console.log(`- ${item.business_name}`));
        if (extraRecords.length > 10) console.log('... (and more)');
    }
}

runAudit();