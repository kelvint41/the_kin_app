# Job Board Implementation Roadmap

**Status**: Strategy complete, ready for Phase 1 implementation
**Priority**: High (core community feature, drives engagement & retention)
**Estimated Timeline**: 4-6 weeks for full rollout

---

## Files Created (Ready)

✅ **Strategy Documents**
- `JOB_BOARD_STRATEGY.md` — Complete feature strategy, UI flows, metrics
- `JOB_BOARD_IMPLEMENTATION_ROADMAP.md` — This file

✅ **Components**
- `lib/components/admin_job_board_metrics_card.dart` — Admin dashboard metrics display

---

## Remaining Implementation Tasks

### **Phase 1: Backend Infrastructure** (Week 1-2)

**Firestore Collections:**
- [ ] Create `job_postings` collection
  - Fields: businessRef, title, description, jobType, location, rateMin, rateMax, tags, postedAt, expiresAt, status, viewCount, applicationCount
  - Indexes: businessRef, status, expiresAt (for sorting/filtering)

- [ ] Create `job_applications` collection
  - Fields: jobRef, applicantRef, appliedAt, status, messagesSent, updatedAt
  - Indexes: jobRef (for "applications for this job"), applicantRef (for "applications I've sent")

- [ ] Create `job_messages` collection (reuse Exchange messaging or create new)
  - Fields: jobRef, fromRef, toRef, messageText, sentAt, read

**Cloud Functions:**
- [ ] `expireJobPostings()` — Nightly: mark postings as expired if past expiresAt
- [ ] `trackJobView()` — Increment viewCount when job is opened
- [ ] `notifyOnJobApply()` — Send notification to business owner when someone applies
- [ ] `calculateJobBoardMetrics()` — Aggregate stats for admin dashboard (hourly)

**Firestore Security Rules:**
- [ ] Only business owners can create/edit/delete their own job postings
- [ ] Everyone (signed in) can view job postings
- [ ] Only applicants and business owner can see applications/messages
- [ ] Admins can moderate jobs (delete spam/violations)

---

### **Phase 2: UI Components** (Week 2-3)

**New Widgets to Create:**

1. **`JobBoardTabPage`** (Main jobs listing page)
   - [ ] Job listing with filters (type, location, rate range)
   - [ ] Search bar
   - [ ] Featured jobs carousel (Founding Local+ promotions)
   - [ ] "Looking for work" badge toggle for users

2. **`JobPostingDetailWidget`** (Job detail page)
   - [ ] Full job description
   - [ ] Business info + link to profile
   - [ ] "Apply Now" button
   - [ ] Message/contact business
   - [ ] Save job button
   - [ ] Related jobs carousel

3. **`JobPostFormWidget`** (Owner creates/edits job)
   - [ ] Title, job type, location, rate range
   - [ ] Description (150+ chars)
   - [ ] Tags (Full-time, Part-time, Contract, Gig)
   - [ ] Expiration selector (30/60/90 days)
   - [ ] Preview before posting

4. **`MyJobPostingsPanel`** (Owner dashboard section)
   - [ ] List of active jobs
   - [ ] View applications button
   - [ ] Edit/delete/renew actions
   - [ ] Job stats (views, applications)

5. **`JobApplicationListWidget`** (Owner views applications)
   - [ ] Applicant name, profile pic, summary
   - [ ] View full profile
   - [ ] Message applicant
   - [ ] Accept/reject buttons
   - [ ] Mark as hired

6. **`LookingForWorkBadge`** (Customer profile indicator)
   - [ ] Toggle "I'm looking for work"
   - [ ] Shows in profile + job board search

7. **`AdminJobBoardMetricsCard`** (DONE)
   - ✅ Active postings, weekly rate, applications
   - ✅ Top hiring businesses
   - ✅ Engagement metrics

---

### **Phase 3: Integration Points** (Week 3-4)

**Bottom Navigation Update:**
- [ ] Add "Jobs" tab (3rd position, between Directory and Exchange)
- [ ] Icon: briefcase or job-related icon
- [ ] Route to `JobBoardTabPage`

**Owner Profile Integration:**
- [ ] Add "My Job Postings" section to `OwnerProfileWidget`
- [ ] Show active job count
- [ ] "Post a Job" button (expands `JobPostFormWidget`)
- [ ] Link to "Manage Postings" (opens `MyJobPostingsPanel`)

**Customer Profile Integration:**
- [ ] Add "Looking for Work" badge toggle
- [ ] Shows on profile to potential employers
- [ ] Filterable in job applications

**Executive Dashboard Integration:**
- [ ] Import `AdminJobBoardMetricsCard`
- [ ] Add to dashboard after Location Beacon metrics
- [ ] Pass mock data during development

**Hamburger Menu Integration:**
- [ ] Add "Browse Jobs" link in main menu
- [ ] Routes to `JobBoardTabPage`

---

### **Phase 4: Tier-Based Features** (Week 4-5)

**Free Tier:**
- [ ] Post jobs (unlimited)
- [ ] View job applications (count only, no profiles)
- [ ] Email/phone contact only

**Founder Tier ($29):**
- [ ] View applicant profiles
- [ ] In-app messaging with applicants
- [ ] "Hiring" badge on business profile

**Founding Local+ ($59+):**
- [ ] Boost job post (featured in "Top Openings")
- [ ] Advanced search for candidates
- [ ] Job post analytics

**Premium Local+ ($99+):**
- [ ] Job posts always boosted (premium rotation)
- [ ] Priority candidate messaging
- [ ] Job board analytics dashboard

**Elite ($149+):**
- [ ] "Featured Employer" badge
- [ ] Premium candidate matching
- [ ] Hiring analytics + insights

---

### **Phase 5: Polish & Launch** (Week 5-6)

**Content & Copy:**
- [ ] Sample jobs (seed data for launch day)
- [ ] Help text for job posting form
- [ ] Empty state messaging ("No jobs yet")
- [ ] In-app notifications for job updates

**Moderation:**
- [ ] Spam/fraud filters (keywords, patterns)
- [ ] Admin job review queue
- [ ] Flag/report button for users

**Analytics & Testing:**
- [ ] Track job board events (post, apply, view)
- [ ] Test tier-based visibility
- [ ] Load testing (thousands of jobs)

---

## Implementation Checklist

### Week 1-2 (Backend)
- [ ] Firestore collections designed + created
- [ ] Security rules written + tested
- [ ] Cloud Functions deployed
- [ ] Test data seeding

### Week 2-3 (Frontend Components)
- [ ] All 7 widgets built + locally tested
- [ ] Bottom nav updated with Jobs tab
- [ ] Navigation routing configured

### Week 3-4 (Integration)
- [ ] Owner profile: "My Job Postings" section added
- [ ] Customer profile: "Looking for Work" badge added
- [ ] Admin dashboard: metrics card integrated
- [ ] Hamburger menu: Jobs link added

### Week 4-5 (Tier Features)
- [ ] Tier-based visibility logic implemented
- [ ] Job boost/promotion feature working
- [ ] Tier-specific UI showing correct access levels

### Week 5-6 (Launch)
- [ ] Content seeding (sample jobs + employers)
- [ ] Moderation system active
- [ ] User testing with beta group
- [ ] Analytics tracking live

---

## Success Criteria

**Soft Launch (Beta)**
- 10+ businesses posting jobs
- 5+ active job seekers with badges
- Zero moderation issues (no spam)
- 20+ applications total

**Full Launch (Public)**
- 50+ active job postings
- 100+ "looking for work" badges
- 3+ documented hires through platform
- Admin dashboard metrics tracking correctly

---

## Risk Mitigation

**Risk**: Spam/scam job postings
**Mitigation**: Auto-filters + admin review queue before posting goes live

**Risk**: Low initial job supply
**Mitigation**: Partner with 10 businesses to seed jobs before launch

**Risk**: Low candidate engagement
**Mitigation**: Marketing push in Exchange feed, embedded promotions on map

**Risk**: Technical issues with applications/messaging
**Mitigation**: Thorough testing, fallback to email/phone contact

---

## Notes for Next Steps

1. **Database schema** needs Kelvin approval before Firestore setup
2. **Sample job content** should be representative of KIN target businesses
3. **Launch day coordination** needed with marketing (promote in Exchange, social)
4. **Moderation team** needed from day 1 (part-time contract OK initially)
5. **Hiring success stories** should be collected and promoted (word-of-mouth)
