const admin = require("firebase-admin/app");
admin.initializeApp();

const checkAndExpireBeacons = require("./check_and_expire_beacons.js");
exports.checkAndExpireBeacons = checkAndExpireBeacons.checkAndExpireBeacons;

const kindexEngine = require("./kindex_engine.js");
exports.processUserEngagementEvent = kindexEngine.processUserEngagementEvent;

const showcaseInterest = require("./showcase_interest.js");
exports.recordItemInterest = showcaseInterest.recordItemInterest;

const exchangeReactionCounts = require("./exchange_reaction_counts.js");
exports.recordExchangeReactionCounts =
  exchangeReactionCounts.recordExchangeReactionCounts;

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

// Maintains community_impact_stats/aggregate off spend_logs writes - see
// firestore.rules' spend_logs comment for why this exists: the only path
// a community-wide total is allowed to leave that owner-only collection.
const spendLogAggregate = require("./spend_log_aggregate.js");
exports.recordSpendLogAggregate = spendLogAggregate.recordSpendLogAggregate;
exports.removeSpendLogAggregate = spendLogAggregate.removeSpendLogAggregate;

const visitVerification = require("./visit_verification.js");
exports.recordVerifiedVisit = visitVerification.recordVerifiedVisit;

const aiMarketingOrchestrator = require("./ai_marketing_orchestrator.js");
exports.generateMarketingContent = aiMarketingOrchestrator.generateMarketingContent;
exports.logAiSuggestionEngagement = aiMarketingOrchestrator.logAiSuggestionEngagement;

const appStudioLogoGenerator = require("./app_studio_logo_generator.js");
exports.generateAppStudioLogos = appStudioLogoGenerator.generateAppStudioLogos;

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
exports.resolveBusinessSubmissionReview =
  businessDiscovery.resolveBusinessSubmissionReview;
exports.resolveBusinessSubmission =
  businessDiscovery.resolveBusinessSubmission;

const mysteryRewardEngine = require("./mystery_reward_engine.js");
exports.generateMysteryReward = mysteryRewardEngine.generateMysteryReward;
exports.redeemReward = mysteryRewardEngine.redeemReward;

const businessGeohashOnCreate = require("./business_geohash_on_create.js");
exports.setBusinessGeohashOnCreate = businessGeohashOnCreate.setBusinessGeohashOnCreate;

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

// Never registered before this session - existed in the codebase but had
// never actually been deployed, so the Executive Dashboard's KIN Quest
// Activity card (admin_kin_quest_metrics_card.dart) is its first caller.
const operationsStats = require("./operations_stats.js");
exports.getOperationsStats = operationsStats.getOperationsStats;

const claimNotifications = require("./claim_notifications.js");
exports.notifyClaimApproved = claimNotifications.notifyClaimApproved;
exports.notifyClaimRejected = claimNotifications.notifyClaimRejected;

const claimReview = require("./claim_review.js");
exports.resolveClaimRequest = claimReview.resolveClaimRequest;

const questActivityFeed = require("./quest_activity_feed.js");
exports.syncQuestActivityFeed = questActivityFeed.syncQuestActivityFeed;

const sendPasswordReset = require("./send_password_reset.js");
exports.sendPasswordReset = sendPasswordReset.sendPasswordReset;

const moderateImageUpload = require("./moderate_image_upload.js");
exports.moderateImageUpload = moderateImageUpload.moderateImageUpload;

const jobBoard = require("./job_board.js");
exports.trackJobView = jobBoard.trackJobView;
exports.notifyOnJobApply = jobBoard.notifyOnJobApply;
exports.expireJobPostings = jobBoard.expireJobPostings;
exports.calculateJobBoardMetrics = jobBoard.calculateJobBoardMetrics;

const communityEvents = require("./community_events.js");
exports.notifyPartnershipRequest = communityEvents.notifyPartnershipRequest;
