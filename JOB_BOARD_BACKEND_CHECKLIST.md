# Job Board Backend: Phase 1 Implementation Checklist

**Status**: Ready for implementation
**Estimated Duration**: 2-3 weeks
**Priority**: High (core community feature)

---

## Pre-Implementation Setup

### Dependencies & Tools
- [ ] Node.js 18+ installed (`node --version`)
- [ ] Firebase CLI installed (`firebase --version`)
- [ ] TypeScript knowledge (Cloud Functions written in TS)
- [ ] Firestore emulator working locally
- [ ] Admin SDK credentials configured

### Documentation Review
- [ ] Read `FIRESTORE_JOB_BOARD_SCHEMA.md` (data structure)
- [ ] Read `FIRESTORE_JOB_BOARD_SECURITY_RULES.md` (access control)
- [ ] Read `CLOUD_FUNCTIONS_JOB_BOARD.md` (backend logic)
- [ ] Review this checklist and timelines

---

## Week 1: Database Schema & Security

### Day 1: Firestore Collections Setup

**Tasks:**
- [ ] Create `job_postings` collection in Firestore
- [ ] Create `job_applications` collection in Firestore
- [ ] Create `job_messages` collection in Firestore
- [ ] Create `admin_metrics` collection (for dashboard)
- [ ] Add 5-10 sample job documents for testing

**Verification:**
- [ ] Collections appear in Firebase Console
- [ ] Sample data is visible and properly structured
- [ ] All required fields present in sample docs

**Time**: ~2 hours

### Day 2: Database Indexes

**Tasks:**
- [ ] Deploy composite index: `(businessRef, status, expiresAt)`
- [ ] Deploy composite index: `(status, expiresAt, postedAt)`
- [ ] Deploy composite index: `(status, jobType, location)`
- [ ] Deploy composite index: `(jobRef, appliedAt)` for applications
- [ ] Deploy composite index: `(applicantRef, status, appliedAt)`
- [ ] Deploy composite index: `(businessRef, status, respondedAt)`

**Verification:**
- [ ] All indexes show as "READY" in Console (may take 5-10 minutes)
- [ ] Run test queries to verify they work:
  ```
  db.collection('job_postings')
    .where('businessRef', '==', businessRef)
    .where('status', '==', 'active')
    .orderBy('postedAt', 'desc')
    .limit(10)
    .get()
  ```

**Time**: ~3 hours (including waiting for index creation)

### Days 3-4: Security Rules

**Tasks:**
- [ ] Write Firestore security rules (use template from `FIRESTORE_JOB_BOARD_SECURITY_RULES.md`)
- [ ] Deploy rules to development Firestore
- [ ] Write 20+ test cases to verify rules work:
  - Owner can create/read/edit own jobs
  - Other users can't edit jobs
  - Anonymous users blocked
  - Proper application access control
  - Message privacy enforced
  - Admins can moderate
- [ ] Run tests via Firestore emulator
- [ ] Fix any rule violations found in tests
- [ ] Deploy rules to production Firestore (when ready)

**Verification Checklist:**
```
CREATION RULES:
- [ ] Owner CAN create job with own businessRef
- [ ] Owner CANNOT create job with other businessRef
- [ ] Anonymous user CANNOT create job

READ RULES:
- [ ] Authenticated user CAN read all public jobs
- [ ] Owner CAN read own jobs (including deleted)
- [ ] Owner CANNOT read other owner's jobs
- [ ] Anonymous user CANNOT read any jobs

APPLICATION RULES:
- [ ] User CAN create own application
- [ ] Owner CAN read applications to own jobs
- [ ] Other users CANNOT read applications
- [ ] Applications CANNOT be deleted (soft delete only)

MESSAGE RULES:
- [ ] Participants CAN read their messages
- [ ] Non-participants CANNOT read
- [ ] Admin CAN read all messages
- [ ] Messages CANNOT be deleted
```

**Time**: ~8 hours (includes testing)

---

## Week 2: Cloud Functions

### Day 1: Set Up Functions Project

**Tasks:**
- [ ] Create `firebase/functions/` directory structure
- [ ] Initialize Firebase Functions project
- [ ] Install dependencies: `npm install firebase-admin firebase-functions`
- [ ] Configure TypeScript for Cloud Functions
- [ ] Set up local emulator testing

**Verification:**
```bash
firebase emulators:start --only functions
# Should run without errors
```

**Time**: ~2 hours

### Day 2: Implement Core Functions

**Tasks:**
- [ ] Implement `expireJobPostings` function (copy from `CLOUD_FUNCTIONS_JOB_BOARD.md`)
- [ ] Implement `trackJobView` function
- [ ] Implement `notifyOnJobApply` function (with email setup)
- [ ] Implement `calculateJobBoardMetrics` function

**Verification:**
- [ ] Each function compiles without errors
- [ ] Firebase emulator runs all functions successfully
- [ ] Test function locally with sample data

**Time**: ~6 hours

### Day 3: Configure Email Service

**Tasks:**
- [ ] Set up SendGrid OR Gmail SMTP for sending emails
- [ ] Configure email templates (job application notification)
- [ ] Test sending email from `notifyOnJobApply` function
- [ ] Store email credentials in Firebase Secrets Manager

**Verification:**
```bash
# Test email function
firebase functions:shell
> notifyOnJobApply({jobId: 'test'}, {auth: {uid: 'user1'}})
# Check email was received
```

**Time**: ~3 hours

### Days 4-5: Testing & Deployment

**Tasks:**
- [ ] Write unit tests for each function:
  - Test expireJobPostings marks jobs as expired
  - Test trackJobView increments counter
  - Test notifyOnJobApply sends notifications
  - Test calculateJobBoardMetrics aggregates correctly
- [ ] Run test suite: `npm test`
- [ ] Deploy functions to development Firebase
- [ ] Run integration tests against real Firestore
- [ ] Deploy functions to production Firebase

**Verification:**
```bash
firebase deploy --only functions
firebase functions:log # Check for errors

# Monitor:
firebase console > Functions > Logs
```

**Time**: ~8 hours

---

## Week 3: Integration & QA

### Day 1: Flutter App Integration

**Tasks:**
- [ ] Create Dart service class for job board backend calls
- [ ] Implement `trackJobView` call when opening job detail
- [ ] Implement job creation form submission
- [ ] Implement application submission
- [ ] Wire up notification display

**Sample Code:**
```dart
class JobBoardService {
  final functions = FirebaseFunctions.instance;
  
  Future<void> trackJobView(String jobId) async {
    await functions.httpsCallable('trackJobView').call({'jobId': jobId});
  }
  
  Future<void> applyToJob(String jobId) async {
    await FirebaseFirestore.instance
      .collection('job_applications')
      .add({
        'jobRef': FirebaseFirestore.instance.collection('job_postings').doc(jobId),
        'applicantRef': FirebaseFirestore.instance.collection('users').doc(userId),
        'appliedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
  }
}
```

**Time**: ~6 hours

### Day 2: Admin Dashboard Integration

**Tasks:**
- [ ] Create admin metrics card component (use `admin_job_board_metrics_card.dart`)
- [ ] Wire up metrics data from `admin_metrics/job_board`
- [ ] Display on Executive Dashboard
- [ ] Test metrics update hourly

**Verification:**
- [ ] Metrics card shows on admin dashboard
- [ ] Numbers update periodically
- [ ] Click-through to job listings works

**Time**: ~4 hours

### Days 3-5: QA & Bug Fixes

**Tasks:**
- [ ] End-to-end testing:
  - [ ] Create a job (as business owner)
  - [ ] Browse jobs (as customer)
  - [ ] Apply to job (as customer)
  - [ ] View applications (as business owner)
  - [ ] Message applicant (as business owner)
  - [ ] Receive email notification
  - [ ] Admin sees metrics updated
- [ ] Test edge cases:
  - [ ] Apply twice to same job (should fail)
  - [ ] Delete job while applications exist (soft delete works)
  - [ ] Job auto-expires after date
  - [ ] Security rules prevent unauthorized access
- [ ] Load testing (100+ concurrent users)
- [ ] Performance profiling
- [ ] Bug fixes and optimization

**Verification Checklist:**
```
HAPPY PATH:
- [ ] Can create job posting
- [ ] Can browse and filter jobs
- [ ] Can apply to job
- [ ] Owner sees applications
- [ ] Can message applicant
- [ ] Email sent to owner
- [ ] Admin sees metrics

EDGE CASES:
- [ ] Soft deletes work correctly
- [ ] Auto-expiration works
- [ ] Double-apply prevention
- [ ] Permission checks pass
- [ ] Metrics calculate correctly

PERFORMANCE:
- [ ] Job creation: < 2 seconds
- [ ] Job view tracking: < 200ms
- [ ] Application submission: < 1 second
- [ ] Metrics calculation: < 10 seconds
```

**Time**: ~12 hours

---

## Deployment Checklist

### Pre-Deployment
- [ ] All tests passing
- [ ] Code reviewed by team
- [ ] Security audit completed
- [ ] Performance profiling shows acceptable latency
- [ ] Backup plan for rollback ready

### Deployment Steps
```bash
# 1. Deploy to staging/development first
firebase deploy --only firestore:rules --project kin-app-dev
firebase deploy --only functions --project kin-app-dev

# 2. Test on staging thoroughly
# 3. When ready, deploy to production
firebase deploy --only firestore:rules --project kin-app-prod
firebase deploy --only functions --project kin-app-prod

# 4. Monitor logs for errors
firebase functions:log --project kin-app-prod
```

### Post-Deployment
- [ ] Monitor error rates in Cloud Functions logs
- [ ] Monitor Firestore for rule rejections
- [ ] Monitor emails being sent successfully
- [ ] Verify metrics updating hourly
- [ ] Check user feedback for issues

---

## Success Criteria

Phase 1 is complete when:

✅ **Database** - All collections, fields, and indexes deployed
✅ **Security** - Rules enforced, no unauthorized access possible
✅ **Functions** - All 4 functions working, notifications sent
✅ **App Integration** - Job creation, application, messaging working
✅ **Admin Dashboard** - Metrics displaying correctly
✅ **Testing** - All test cases passing
✅ **Performance** - Operations completing within latency budgets
✅ **Monitoring** - Logs, errors, and alerts configured

---

## Timeline Summary

| Week | Days | Tasks | Status |
|------|------|-------|--------|
| 1 | 1 | Collections setup | ⏳ |
| 1 | 2 | Database indexes | ⏳ |
| 1 | 3-4 | Security rules | ⏳ |
| 2 | 1 | Functions project setup | ⏳ |
| 2 | 2 | Implement functions | ⏳ |
| 2 | 3 | Email configuration | ⏳ |
| 2 | 4-5 | Testing & deployment | ⏳ |
| 3 | 1 | App integration | ⏳ |
| 3 | 2 | Admin dashboard | ⏳ |
| 3 | 3-5 | QA & bug fixes | ⏳ |

**Total**: ~2-3 weeks

---

## Resources

**Documentation Files:**
- `FIRESTORE_JOB_BOARD_SCHEMA.md` - Data structure
- `FIRESTORE_JOB_BOARD_SECURITY_RULES.md` - Security rules
- `CLOUD_FUNCTIONS_JOB_BOARD.md` - Cloud Functions code
- `JOB_BOARD_STRATEGY.md` - Feature overview

**Firebase Docs:**
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/start)
- [Cloud Functions for Firestore](https://firebase.google.com/docs/functions/firestore-events)
- [Firestore Indexes](https://firebase.google.com/docs/firestore/query-data/index-overview)

**Next Phase:**
After Phase 1 is complete, start Phase 2 (Frontend UI components):
- Job posting form
- Job listing page
- Application management
- Messaging interface

---

## Questions & Support

If stuck on:
- **Firestore rules**: Check Firebase docs on security rules, test in emulator
- **Cloud Functions**: Check logs in Cloud Console, test locally first
- **Email delivery**: Check SendGrid/Gmail credentials and test separately
- **Performance**: Profile with Firebase Profiler, check indexes

---

## Approval Sign-Off

- [ ] Product: Phase 1 scope approved
- [ ] Engineering: Technical design approved
- [ ] Security: Security rules reviewed and approved
- [ ] DevOps: Deployment plan reviewed

Ready to start Phase 1 implementation! 🚀
