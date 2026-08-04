const admin = require("firebase-admin");
const sa = require("./serviceAccountKey.json");
admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();

async function main() {
  const snap = await db.collection("businesses").get();
  const matches = [];
  for (const doc of snap.docs) {
    const d = doc.data();
    const name = (d.business_name || "").toLowerCase();
    if (name.includes("haus") || name.includes("hair") || name.includes("harris")) {
      matches.push({
        id: doc.id,
        name: d.business_name,
        owner_ref: d.owner_ref ? d.owner_ref.path : null,
        is_claimed: d.is_claimed,
        claimed_by_user_id: d.claimed_by_user_id || null,
        is_verified: d.is_verified,
        is_black_owned: d.is_black_owned,
      });
    }
  }
  console.log("Business matches:\n", JSON.stringify(matches, null, 2));

  const usersSnap = await db.collection("users").where("email", "==", "kelvin@kinvestguidance.com").get();
  for (const doc of usersSnap.docs) {
    const d = doc.data();
    console.log("\nKelvin user doc:", doc.id);
    console.log("  email:", d.email);
    console.log("  display_name:", d.display_name || d.name || null);
    console.log("  owned_business:", d.owned_business ? d.owned_business.path : null);
  }
  process.exit(0);
}

main().catch((e) => { console.error(e); process.exit(1); });
