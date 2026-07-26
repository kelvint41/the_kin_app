const admin = require("firebase-admin/app");
admin.initializeApp();

const checkAndExpireBeacons = require("./check_and_expire_beacons.js");
exports.checkAndExpireBeacons = checkAndExpireBeacons.checkAndExpireBeacons;
const ffPrivateApiCall = require("./ff_private_api_call.js");
exports.ffPrivateApiCall = ffPrivateApiCall.ffPrivateApiCall;
