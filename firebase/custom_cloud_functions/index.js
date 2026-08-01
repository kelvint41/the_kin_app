const admin = require("firebase-admin/app");
admin.initializeApp();

const checkAndExpireBeacons = require("./check_and_expire_beacons.js");
exports.checkAndExpireBeacons = checkAndExpireBeacons.checkAndExpireBeacons;

const kindexEngine = require("./kindex_engine.js");
exports.processUserEngagementEvent = kindexEngine.processUserEngagementEvent;

// Business-side Kindex scoring moved from a reactive onCreate trigger on
// `reviews/{reviewId}` to a nightly recompute. The old reactive engine
// (processBusinessReview) applied a fixed delta per review with no
// verified-visit requirement and no per-customer cap, so repeated reviews
// from one account could move a score without bound. Scoring now runs once
// a night over verified visits only - see the anti-manipulation redesign.
//
// NOTE: processBusinessReview is deliberately no longer exported. If it was
// previously deployed, `firebase deploy --only functions` will DELETE it
// from the project (the CLI prompts to confirm). That is intended.
const businessKindexNightly = require("./business_kindex_nightly.js");
exports.recomputeBusinessKindexScores =
  businessKindexNightly.recomputeBusinessKindexScores;

const customerKindexNightly = require("./customer_kindex_nightly.js");
exports.recomputeCustomerKindexScores =
  customerKindexNightly.recomputeCustomerKindexScores;

const visitVerification = require("./visit_verification.js");
exports.recordVerifiedVisit = visitVerification.recordVerifiedVisit;

const aiMarketingOrchestrator = require("./ai_marketing_orchestrator.js");
exports.generateMarketingContent = aiMarketingOrchestrator.generateMarketingContent;
exports.logAiSuggestionEngagement = aiMarketingOrchestrator.logAiSuggestionEngagement;

// Read side of the same logs, for the Executive Dashboard. Separate file
// because it shares no state with the orchestrator - only the collection -
// and because the orchestrator holds the Gemini secret binding, which a
// pure aggregation callable has no business loading.
const aiMarketingStats = require("./ai_marketing_stats.js");
exports.getAiMarketingStats = aiMarketingStats.getAiMarketingStats;

const agencyQueueScheduling = require("./agency_queue_scheduling.js");
exports.scheduleAgencyQueueTarget =
  agencyQueueScheduling.scheduleAgencyQueueTarget;

const signupFeedSync = require("./signup_feed_sync.js");
exports.syncSignupFeed = signupFeedSync.syncSignupFeed;

const businessDiscovery = require("./business_discovery.js");
exports.submitBusinessDiscovery = businessDiscovery.submitBusinessDiscovery;
exports.submitCustomerBusinessDiscovery =
  businessDiscovery.submitCustomerBusinessDiscovery;
exports.findMatchingBusinessSubmission =
  businessDiscovery.findMatchingBusinessSubmission;
exports.resolveBusinessSubmission =
  businessDiscovery.resolveBusinessSubmission;

const mysteryRewardEngine = require("./mystery_reward_engine.js");
exports.generateMysteryReward = mysteryRewardEngine.generateMysteryReward;
exports.redeemReward = mysteryRewardEngine.redeemReward;

const exchangePostTools = require("./exchange_post_tools.js");
exports.cleanUpPostText = exchangePostTools.cleanUpPostText;

const foundingLocalTrial = require("./founding_local_trial.js");
exports.startFoundingLocalTrial = foundingLocalTrial.startFoundingLocalTrial;
exports.processFoundingLocalTrials =
  foundingLocalTrial.processFoundingLocalTrials;

const supportChat = require("./support_chat.js");
exports.sendSupportChatMessage = supportChat.sendSupportChatMessage;

const supportChatStats = require("./support_chat_stats.js");
exports.getSupportChatStats = supportChatStats.getSupportChatStats;

const claimNotifications = require("./claim_notifications.js");
exports.notifyClaimApproved = claimNotifications.notifyClaimApproved;
