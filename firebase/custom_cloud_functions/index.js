const admin = require("firebase-admin/app");
admin.initializeApp();

const checkAndExpireBeacons = require("./check_and_expire_beacons.js");
exports.checkAndExpireBeacons = checkAndExpireBeacons.checkAndExpireBeacons;

const kindexEngine = require("./kindex_engine.js");
exports.processUserEngagementEvent = kindexEngine.processUserEngagementEvent;

const aiMarketingOrchestrator = require("./ai_marketing_orchestrator.js");
exports.generateMarketingContent = aiMarketingOrchestrator.generateMarketingContent;
exports.logAiSuggestionEngagement = aiMarketingOrchestrator.logAiSuggestionEngagement;

const marketingEngine = require("./marketing_engine.js");
exports.getOrCreateReferralCode = marketingEngine.getOrCreateReferralCode;
exports.redeemReferralCode = marketingEngine.redeemReferralCode;
exports.processReferral = marketingEngine.processReferral;
exports.logCampaignEvent = marketingEngine.logCampaignEvent;
exports.expireCampaigns = marketingEngine.expireCampaigns;
