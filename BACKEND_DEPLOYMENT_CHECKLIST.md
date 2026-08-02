# Backend Deployment Checklist - Location Beacon Feature

**Status**: Ready to start backend work
**Frontend**: ✅ Complete (Phase 3)
**Backend**: ⏳ In Progress

---

## Section 1: Cloud Functions Deployment

### Location Beacon Functions
- [ ] **startLocationBeacon() Cloud Function**
  - [ ] Implement function to activate beacon
  - [ ] Verify user authentication
  - [ ] Check subscription tier (must be Founding Local+)
  - [ ] Validate business is mobile vendor (is_mobile_vendor == true)
  - [ ] Validate business is claimed (claimedBy != null)
  - [ ] Update BusinessesRecord fields:
    - [ ] `current_location` = location string
    - [ ] `current_location_expires_at` = expiry DateTime
    - [ ] `mobile_location_active` = true
  - [ ] Create Exchange post if autoPost == true
  - [ ] Log activity for analytics
  - [ ] Add error handling and validation
  - [ ] Test with various edge cases
  - [ ] Deploy to production

- [ ] **stopLocationBeacon() Cloud Function**
  - [ ] Implement function to deactivate beacon
  - [ ] Verify user owns the business
  - [ ] Update BusinessesRecord fields:
    - [ ] `mobile_location_active` = false
    - [ ] `current_location` = null
  - [ ] Log activity
  - [ ] Deploy to production

- [ ] **updateLocationBeacon() Cloud Function**
  - [ ] Implement function to update location while active
  - [ ] Verify beacon is currently active
  - [ ] Verify user owns business
  - [ ] Update `current_location` field
  - [ ] Optionally create update post in feed
  - [ ] Deploy to production

- [ ] **createLocationPost() Cloud Function**
  - [ ] Create Exchange feed post for beacon activation
  - [ ] Format: "🚨 We're live at [location]!"
  - [ ] Set postType = "location_beacon"
  - [ ] Link to business reference
  - [ ] Set auto-expiry when beacon expires
  - [ ] Deploy to production

### Business Discovery Functions
- [ ] **submitBusinessDiscovery() Cloud Function** (may already exist - verify)
  - [ ] Verify function exists and works correctly
  - [ ] Accept: businessName, address, category, latitude?, longitude?
  - [ ] Create business_submissions document
  - [ ] Set status = "pending_review"
  - [ ] Store submitter UID for reward tracking
  - [ ] Log submission for analytics
  - [ ] Verify it's already deployed

- [ ] **verifyBusinessDiscovery() Cloud Function** (admin-only)
  - [ ] Implement admin function to verify discovery
  - [ ] Accept: submissionId, isVerified (bool)
  - [ ] If verified:
    - [ ] Create new business in businesses collection
    - [ ] Award points to discoverer (10-25 KIN)
    - [ ] Mark business as verified
  - [ ] If disputed:
    - [ ] Mark as disputed in business_submissions
    - [ ] Optionally log reason
  - [ ] Create audit trail
  - [ ] Deploy to production

- [ ] **awardDiscoveryPoints() Cloud Function**
  - [ ] Award KIN points to customer for verified discovery
  - [ ] Add to user's kinQuestPoints
  - [ ] Create transaction record
  - [ ] Send notification to user (optional)
  - [ ] Deploy to production

---

## Section 2: Firestore Security Rules

### Beacon Operations Rules
- [ ] **startLocationBeacon() Authorization**
  - [ ] User must be authenticated (auth.uid != null)
  - [ ] User must own the business (businessOwner == auth.uid)
  - [ ] Business must be claimed (claimedBy != null)
  - [ ] Business must be mobile vendor (is_mobile_vendor == true)
  - [ ] User tier must be in allowedTiers (Founding Local+)
  - [ ] Write rule: `request.auth.uid == resource.data.claimedBy && ... tier check`

- [ ] **stopLocationBeacon() Authorization**
  - [ ] User must own business
  - [ ] Write rule implemented

- [ ] **updateLocationBeacon() Authorization**
  - [ ] User must own business
  - [ ] Beacon must be active
  - [ ] Can only update current_location field

### Business Discovery Rules
- [ ] **submitBusinessDiscovery() Permission**
  - [ ] Any authenticated user can submit (read/write to business_submissions)
  - [ ] No tier restriction (all customers can discover)
  - [ ] Rule: `request.auth.uid != null`

- [ ] **verifyBusinessDiscovery() Permission** (admin-only)
  - [ ] Only admin users can call
  - [ ] Verify isAdmin flag on user document
  - [ ] Rule: `request.auth.uid != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true`

### Read Rules
- [ ] **Customers can read active beacons**
  - [ ] Query: `mobile_location_active == true`
  - [ ] Read access to exchange posts with postType == "location_beacon"
  - [ ] Rule: Any authenticated user

- [ ] **Admins can read metrics**
  - [ ] Access to business_submissions collection
  - [ ] Access to activity_logs for analytics
  - [ ] Admin-only read rules

---

## Section 3: Firestore Collections & Schemas

### Verify Existing Collections
- [ ] **businesses Collection**
  - [ ] `is_mobile_vendor` field exists (bool, default: false)
  - [ ] `current_location` field exists (string, nullable)
  - [ ] `current_location_expires_at` field exists (timestamp, nullable)
  - [ ] `mobile_location_active` field exists (bool, default: false)
  - [ ] `claimedBy` field exists (user reference)
  - [ ] All fields properly indexed for queries
  - [ ] Run migration to add fields to existing docs if needed

- [ ] **exchange_posts Collection**
  - [ ] `postType` field exists (string: "regular" or "location_beacon")
  - [ ] `businessReference` field exists (reference to business)
  - [ ] `postText` field exists (string)
  - [ ] `createdAt` field exists (timestamp)
  - [ ] `mobile_location_active` field for filtering expired posts
  - [ ] Index on `postType` and `createdAt`

- [ ] **users Collection**
  - [ ] `subscriptionTier` field exists (string)
  - [ ] `isAdmin` field exists (bool, default: false)
  - [ ] `kinQuestPoints` field exists (int, default: 0)
  - [ ] `currentBusinessReference` field (for owner access)

### Create New Collections
- [ ] **business_submissions Collection**
  - [ ] Fields:
    - [ ] `businessName` (string, required)
    - [ ] `address` (string, required)
    - [ ] `category` (string, optional)
    - [ ] `latitude` (number, optional)
    - [ ] `longitude` (number, optional)
    - [ ] `submittedBy` (user reference)
    - [ ] `status` (string: "pending_review", "verified", "disputed")
    - [ ] `createdAt` (timestamp, server-generated)
    - [ ] `reviewedBy` (user reference, optional)
    - [ ] `reviewedAt` (timestamp, optional)
    - [ ] `verificationReason` (string, optional - why verified or disputed)
  - [ ] Indexes: `status`, `createdAt`, `submittedBy`

- [ ] **beacon_activity_logs Collection** (optional, for analytics)
  - [ ] Fields:
    - [ ] `businessId` (reference)
    - [ ] `action` (string: "started", "stopped", "updated")
    - [ ] `location` (string)
    - [ ] `duration` (number - minutes)
    - [ ] `autoPosted` (bool)
    - [ ] `timestamp` (server timestamp)
    - [ ] `viewCount` (number, incremented when viewed)
  - [ ] Used for admin dashboard metrics

- [ ] **discovery_rewards_log Collection** (optional, for tracking rewards)
  - [ ] Fields:
    - [ ] `discoveryId` (reference to business_submissions)
    - [ ] `userId` (user reference)
    - [ ] `pointsAwarded` (number: 10-25)
    - [ ] `awardedAt` (timestamp)
    - [ ] `status` (string: "pending", "awarded", "failed")

---

## Section 4: Third-Party Services & APIs

### Google Places API
- [ ] **API Key Configuration**
  - [ ] Verify Google Places API is enabled in Firebase
  - [ ] Check API key restrictions:
    - [ ] Android restriction (app package name)
    - [ ] iOS restriction (iOS bundle ID)
  - [ ] Set usage quotas/limits
  - [ ] Monitor API usage and costs
  - [ ] Set up billing alerts

- [ ] **API Limits**
  - [ ] Verify daily request limits
  - [ ] Check rate limiting configuration
  - [ ] Plan for high-volume usage (many beacons)

### RevenueCat Configuration
- [ ] **Replace Fake Key with Production Key**
  - [ ] Current: Fake test key needs to be replaced
  - [ ] Get production RevenueCat API key
  - [ ] Configure in Firebase config or environment variables
  - [ ] Set up product IDs:
    - [ ] "founding_local" - $59/month
    - [ ] "founding_local_plus" - $99/month
    - [ ] "elite_tier" - custom pricing
  - [ ] Map subscription tiers in BeaconTierChecker

- [ ] **Subscription Entitlements**
  - [ ] Verify Founding Local tier includes Location Beacon
  - [ ] Verify Founding Local+ tier includes Location Beacon
  - [ ] Verify Community tier does NOT include Location Beacon
  - [ ] Test tier verification logic

### Email Service (Password Reset Emails)
- [ ] **Fix Spam-Filtered Emails** (mentioned in launch blockers)
  - [ ] Investigate why reset emails are being filtered
  - [ ] Options:
    - [ ] Configure SendGrid/Firebase email settings
    - [ ] Use verified sender email domain
    - [ ] Add DKIM/SPF records
    - [ ] Update email templates
  - [ ] Test password reset flow

### Image Moderation Service
- [ ] **Set Up Image Moderation** (mentioned as unmoderated uploads)
  - [ ] Integrate moderation for business discovery uploads
  - [ ] Options:
    - [ ] Google Cloud Vision API
    - [ ] AWS Rekognition
    - [ ] Third-party service (Sightengine, etc.)
  - [ ] Implement auto-rejection of flagged images
  - [ ] Create manual review queue for borderline images
  - [ ] Log moderation decisions

---

## Section 5: Data Migration & Setup

### Backfill Existing Data
- [ ] **Add is_mobile_vendor Field to Existing Businesses**
  - [ ] Create migration script
  - [ ] Identify existing mobile vendors in system (if any)
  - [ ] Set `is_mobile_vendor = false` by default for all
  - [ ] Manually mark known mobile vendors as true
  - [ ] Verify migration completed successfully
  - [ ] Backup data before migration

- [ ] **Initialize New Fields**
  - [ ] Set `current_location = null` for all businesses
  - [ ] Set `current_location_expires_at = null` for all businesses
  - [ ] Set `mobile_location_active = false` for all businesses
  - [ ] Add indexes for new fields

### Data Validation
- [ ] **Add Validation Rules**
  - [ ] Validate subscription tier string values
  - [ ] Validate location string format
  - [ ] Validate expiry times are in future
  - [ ] Validate business references exist
  - [ ] Add constraints to prevent invalid states

---

## Section 6: Admin Features & Workflows

### Business Discovery Review Dashboard
- [ ] **Admin Workflow for Verifying Discoveries**
  - [ ] Create admin view showing pending discoveries
  - [ ] Implement verification/dispute buttons
  - [ ] Track which admin reviewed each discovery
  - [ ] Add notes/reason field for decisions
  - [ ] Auto-award points when verified
  - [ ] Send notifications to discoverer

### Metrics Queries Optimization
- [ ] **Optimize Executive Dashboard Queries**
  - [ ] Query for active beacons: `mobile_location_active == true`
  - [ ] Query for beacon activity (24h): Filter by timestamp
  - [ ] Query for discovery status: Group by status field
  - [ ] Create compound indexes for complex queries
  - [ ] Cache frequently accessed metrics (optional)

### Reporting
- [ ] **Admin Reports**
  - [ ] Weekly beacon activity report
  - [ ] Discovery verification stats
  - [ ] Revenue impact from Location Beacon feature (optional)

---

## Section 7: Testing & Monitoring

### Backend Testing
- [ ] **Unit Tests for Cloud Functions**
  - [ ] Test startLocationBeacon() with valid data
  - [ ] Test startLocationBeacon() with invalid tier
  - [ ] Test startLocationBeacon() with non-mobile business
  - [ ] Test stopLocationBeacon()
  - [ ] Test updateLocationBeacon()
  - [ ] Test business discovery submission
  - [ ] Test discovery verification
  - [ ] Test points award system

- [ ] **Integration Tests**
  - [ ] End-to-end beacon activation flow
  - [ ] End-to-end discovery submission and verification
  - [ ] Test tier restrictions
  - [ ] Test concurrent beacon activations
  - [ ] Test expiry logic

- [ ] **Security Tests**
  - [ ] Verify non-owners can't stop beacons
  - [ ] Verify Community tier can't activate beacons
  - [ ] Verify non-admins can't verify discoveries
  - [ ] Verify Firestore rules are enforced
  - [ ] Test injection attacks on discovery fields

### Monitoring & Logging
- [ ] **Error Tracking Setup**
  - [ ] Configure Sentry or Firebase Crashlytics
  - [ ] Set up alerts for Cloud Function errors
  - [ ] Monitor Firestore quota usage
  - [ ] Set up alerts for quota overages

- [ ] **Analytics Logging**
  - [ ] Log beacon activations
  - [ ] Log beacon expirations
  - [ ] Log beacon updates
  - [ ] Log discovery submissions
  - [ ] Log discovery verifications
  - [ ] Track metrics: active beacons, avg duration, discovery rate

- [ ] **Performance Monitoring**
  - [ ] Monitor Cloud Function execution time
  - [ ] Monitor Firestore read/write latency
  - [ ] Set up performance alerts
  - [ ] Optimize slow queries

---

## Section 8: Configuration & Secrets

### Environment Variables
- [ ] **Create .env or firebase config**
  - [ ] Google Places API key
  - [ ] RevenueCat API key (production)
  - [ ] Image moderation service key
  - [ ] Email service credentials
  - [ ] Firebase project ID
  - [ ] Other third-party service keys

- [ ] **Secure Secrets Management**
  - [ ] Use Firebase Secret Manager or similar
  - [ ] Never commit secrets to git
  - [ ] Rotate keys regularly
  - [ ] Audit access logs

### Firebase Project Setup
- [ ] **Firestore Database**
  - [ ] Verify in production mode (not test mode)
  - [ ] Backup strategy in place
  - [ ] Retention policies configured

- [ ] **Cloud Functions**
  - [ ] Set memory/timeout appropriately
  - [ ] Configure VPC if needed
  - [ ] Set up logging

- [ ] **Billing & Quotas**
  - [ ] Enable billing for Firebase project
  - [ ] Set spending limits
  - [ ] Configure quota alerts
  - [ ] Estimate costs for Location Beacon usage

---

## Section 9: Pre-Launch Checklist

### Final Testing
- [ ] **Full End-to-End Testing**
  - [ ] Activate beacon as mobile vendor
  - [ ] See beacon in Exchange feed
  - [ ] See beacon badge on business cards
  - [ ] See beacon on map (when implemented)
  - [ ] Beacon expires at correct time
  - [ ] Submit business discovery as customer
  - [ ] Review discovery in admin panel
  - [ ] Verify discovery awards points
  - [ ] Test all tier restrictions
  - [ ] Test error scenarios

- [ ] **Performance Testing**
  - [ ] Test with multiple concurrent beacons
  - [ ] Test with high volume of discoveries
  - [ ] Load test Cloud Functions
  - [ ] Monitor database performance

### Documentation
- [ ] **Admin Documentation**
  - [ ] How to review business discoveries
  - [ ] How to troubleshoot beacon issues
  - [ ] FAQ for business owners
  - [ ] FAQ for customers

- [ ] **API Documentation** (internal)
  - [ ] Document all Cloud Functions
  - [ ] Document Firestore schemas
  - [ ] Document security rules
  - [ ] Document error codes and responses

### Communication
- [ ] **Notify Stakeholders**
  - [ ] Notify support team about new feature
  - [ ] Prepare customer support guide
  - [ ] Prepare marketing materials
  - [ ] Prepare in-app announcements

---

## Section 10: Post-Launch Monitoring

### Week 1
- [ ] Monitor all error logs
- [ ] Track feature adoption rate
- [ ] Monitor performance metrics
- [ ] Quick patch/fix issues if needed

### Ongoing
- [ ] Weekly metrics review
- [ ] Monthly performance analysis
- [ ] Regular backup verification
- [ ] Security audit quarterly

---

## Priority Ordering

**CRITICAL (Block Launch)**:
1. Deploy all Location Beacon Cloud Functions
2. Configure Firestore security rules
3. Set up Firestore collections and fields
4. Replace fake RevenueCat key
5. Full end-to-end testing

**HIGH (Should have before launch)**:
1. Image moderation service
2. Email service fix (spam filtering)
3. Admin discovery review dashboard
4. Error tracking/monitoring
5. Analytics logging

**MEDIUM (Nice to have, can add after launch)**:
1. Beacon activity analytics dashboard
2. Advanced admin reporting
3. Performance optimization
4. Automated cleanup of expired beacons

**LOW (Future enhancement)**:
1. Beacon notifications to nearby customers
2. Photo verification system enhancements
3. Machine learning for fraud detection

---

## Estimated Timeline

- **Critical Items**: 2-3 weeks
- **High Priority Items**: 1-2 weeks
- **Testing & QA**: 1-2 weeks
- **Documentation & Launch Prep**: 1 week

**Total estimated backend work**: 5-8 weeks

---

## Notes

- This checklist assumes you have Firebase and Cloud Functions already set up
- Adjust timelines based on your team size and experience level
- Security rules should be reviewed by security team before launch
- Consider staging environment testing before production deployment
- Communicate launch date to customers early

**Questions? Refer back to PHASE_3_COMPLETE_IMPLEMENTATION_REPORT.md for frontend context.**
