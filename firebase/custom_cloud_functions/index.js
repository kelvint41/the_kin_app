const admin = require("firebase-admin/app");
admin.initializeApp();

const checkAndExpireBeacons = require("./check_and_expire_beacons.js");
exports.checkAndExpireBeacons = checkAndExpireBeacons.checkAndExpireBeacons;

const kindexEngine = require("./kindex_engine.js");
exports.processUserEngagementEvent = kindexEngine.processUserEngagementEvent;

const aiMarketingOrchestrator = require("./ai_marketing_orchestrator.js");
exports.generateMarketingContent = aiMarketingOrchestrator.generateMarketingContent;
exports.logAiSuggestionEngagement = aiMarketingOrchestrator.logAiSuggestionEngagement;

const setBusinessSubscription = require("./set_business_subscription.js");
exports.setBusinessSubscription = setBusinessSubscription.setBusinessSubscription;

const powerHour = require("./power_hour.js");
exports.startPowerHour = powerHour.startPowerHour;
exports.stopPowerHour = powerHour.stopPowerHour;

const revenueCatWebhook = require("./revenue_cat_webhook.js");
exports.revenueCatWebhook = revenueCatWebhook.revenueCatWebhook;
