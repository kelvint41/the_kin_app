const admin = require("firebase-admin/app");
admin.initializeApp();

const checkAndExpireBeacons = require("./check_and_expire_beacons.js");
exports.checkAndExpireBeacons = checkAndExpireBeacons.checkAndExpireBeacons;

const kindexEngine = require("./kindex_engine.js");
exports.processUserEngagementEvent = kindexEngine.processUserEngagementEvent;

const aiMarketingOrchestrator = require("./ai_marketing_orchestrator.js");
exports.generateMarketingContent = aiMarketingOrchestrator.generateMarketingContent;
exports.logAiSuggestionEngagement = aiMarketingOrchestrator.logAiSuggestionEngagement;

const launchSubscribers = require("./launch_subscribers.js");
exports.subscribeToLaunch = launchSubscribers.subscribeToLaunch;
exports.confirmLaunchSubscription = launchSubscribers.confirmLaunchSubscription;

const webProjection = require("./web_projection.js");
exports.publishWebProjection = webProjection.publishWebProjection;
exports.publishSignupFlash = webProjection.publishSignupFlash;
