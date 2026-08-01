const functions = require("firebase-functions");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

// Delivery windows agreed for the App Studio pricing ladder (see the
// App Studio pricing proposal). Values are the *upper* bound of each
// window in days, because the product goal is to under-promise and
// over-deliver, not to average it out.
//
// "Advanced" is deliberately absent: its own timeframe ("6+ months") was
// chosen to stay open-ended rather than commit to a false ceiling, so it
// is not auto-scheduled here - an admin sets target_delivery_date for it
// by hand once scope is actually known.
const DELIVERY_WINDOW_DAYS = {
  "Single page": 14, // 1-2 wks
  "Business site": 28, // 2-4 wks
  "Site with booking": 42, // 4-6 wks
  "Essential": 70, // 6-10 wks
  "Professional": 150, // 3-5 months
};

function computeTargetDeliveryDate(tierLevel, fromMs) {
  const windowDays = DELIVERY_WINDOW_DAYS[tierLevel];
  if (!windowDays) return null;
  return admin.firestore.Timestamp.fromMillis(
    fromMs + windowDays * 24 * 60 * 60 * 1000,
  );
}

exports.scheduleAgencyQueueTarget = functions.firestore
  .document("agency_queue/{requestId}")
  .onCreate(async (snapshot) => {
    const data = snapshot.data();

    // Redelivery-safe: a re-run of this trigger for the same doc must not
    // clobber a date an admin may have already hand-set in the interim.
    if (data.target_delivery_date) return;

    const target = computeTargetDeliveryDate(
      data.tier_level,
      Date.now(),
    );
    if (!target) return;

    await snapshot.ref.update({ target_delivery_date: target });
  });

exports._internals = {
  DELIVERY_WINDOW_DAYS,
  computeTargetDeliveryDate,
};
