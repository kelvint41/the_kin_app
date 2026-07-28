const fs = require('fs');

const csvData = fs.readFileSync('National_Directory - FlutterFlow_Import.csv', 'utf8');
const rows = csvData.split('\n');
const results = [];

rows.forEach((line) => {
    const row = line.split(',');
    if (row.length > 1) {
        const obj = {}; 
        obj.business_name = row[0];
        obj.address = row[1];
        obj.phone_number = row[2];
        obj.city = row[3];
        results.push(obj);
    }
});

fs.writeFileSync('my_data.json', JSON.stringify(results, null, 2));
console.log(`Successfully created my_data.json with ${results.length} records.`);