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

const visitVerification = require("./visit_verification.js");
exports.recordVerifiedVisit = visitVerification.recordVerifiedVisit;

const aiMarketingOrchestrator = require("./ai_marketing_orchestrator.js");
exports.generateMarketingContent = aiMarketingOrchestrator.generateMarketingContent;
exports.logAiSuggestionEngagement = aiMarketingOrchestrator.logAiSuggestionEngagement;
