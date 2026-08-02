# KIN Job Board Strategy

**Purpose**: Community-building feature enabling Black-owned business owners to post job openings and find employees. Available to all tiers (including Free), reinforcing KIN's mission to support Black business growth.

---

## The Opportunity

Mobile barbers, food truck owners, and service businesses often hire within their network. The job board formalizes this, making KIN a one-stop platform for:
- Business discovery
- Customer finding  
- **Employee hiring** (new)
- Community connection

---

## Feature Overview

### **Job Post Creation** (Free Tier Access)
```
Business Owner (Any Tier) → Posts Job Opening

Form fields:
- Job title (e.g., "Mobile Stylist Assistant")
- Company/business name (auto-filled from profile)
- Job type (Full-time, Part-time, Contract, Gig)
- Location/service area
- Hourly rate OR salary range
- Description (150+ characters)
- Required skills (tags)
- Contact method (Email, Phone, In-app)
- Posted date (auto)
- Expires in 30/60/90 days (owner selects)
```

**Who can post:**
- Any signed-in business owner (Free tier and up)
- No job posting limit
- Posts live for 30/60/90 days (renewable)

**Why accessible in Free tier:**
- Removes barrier to hiring
- Keeps business owners engaged on platform
- Tier upgrade incentive: "Boost your posting to reach more candidates"

---

## Job Board User Experience

### **For Business Owners (Job Posters)**
```
My Jobs Tab:
- Active postings (3)
- View count for each
- Applicants received (basic tier shows count, premium shows names)
- Edit/renew/delete options
- Contact applicant (email or in-app message)

One-tap job posting:
1. Title + rate + description
2. Select expiration (30/60/90 days)
3. Choose visibility (Free = community only, Founder+ = boosted)
4. Post live
```

### **For Job Seekers (Candidates)**
```
Browse Jobs:
- Filter by job type (Full-time, Part-time, Contract)
- Filter by location/service area
- Filter by business (e.g., "I only want to work for verified Black-owned")
- Search by keyword

Apply:
- One-tap apply (pre-fills contact info from profile)
- Message business directly
- Save for later
- Get notified when similar jobs posted

Profile visibility:
- Business owners can browse applicant profiles
- Applicants opt-in to "looking for work" badge
```

---

## Job Board Content

### **Sample Jobs on Day 1**

```
🧑‍💼 Mobile Stylist Assistant
By: Tasha's Mobile Salon
📍 San Antonio (mobile service)
💰 $18/hour
⏰ Part-time (flexible hours)
⭐ ⭐⭐⭐⭐ (4.9 stars)

"Help with client bookings and hair styling. 
Must have transportation. Flexible schedule 
for school/side gigs. We're all about 
supporting Black businesses!"

[Apply Now]  [Save]
```

```
🚗 Delivery Driver
By: Carmen's Catering
📍 Downtown San Antonio
💰 $20-24/hour + tips
⏰ Full-time

"Drive customers' catering orders. Must have 
valid license. We're hiring immediately for 
events this weekend!"

[Apply Now]  [Save]
```

```
🍔 Kitchen Staff
By: Soul Food Kitchen
📍 North Side
💰 $16/hour + meals
⏰ Full-time

"Line cook or kitchen prep. Experience helpful 
but we'll train. Work with a team that values 
you. Black-owned since 2010."

[Apply Now]  [Save]
```

---

## Tier-Based Visibility & Features

### **Free Tier**
- ✅ Post unlimited jobs
- ✅ Jobs visible in community board
- ✅ Basic applicant notifications
- ✅ Email/phone contact
- ❌ No applicant profile browsing
- ❌ No job post boosting
- **Display**: Community only, rotated visibility

### **Founder Tier ($29)**
- ✅ Everything from Free +
- ✅ View applicant profiles
- ✅ "Hiring" badge on business profile
- ✅ In-app messaging with candidates
- ❌ No job post boosting
- **Display**: Community + map (subtle indicator)

### **Founding Local+ ($59+)**
- ✅ Everything from Founder +
- ✅ **Boost job post** (featured in "Top Openings")
- ✅ Advanced search filters for candidates
- ✅ Bulk job posting
- **Display**: Featured in "Top Openings" carousel (1x/week rotation)

### **Premium Local+ ($99+)**
- ✅ Everything from Founding Local +
- ✅ Job post always boosted (while active)
- ✅ Priority candidate messages
- ✅ Job post analytics (views, applies, hires)
- **Display**: "Premium Employer" badge, featured rotation (3-4x/week)

### **Elite ($149+)**
- ✅ Everything from Premium Local +
- ✅ **Featured employer status** (always visible)
- ✅ Premium candidate matching
- ✅ Hiring analytics dashboard
- ✅ Co-hiring opportunities (connect with other businesses)
- **Display**: "Elite Employer" badge, top of job board rotation

---

## Job Board Revenue Model

### **Direct Revenue** (Optional - implement later)
- Job post premium: $5-10 per boost (already baked into tier)
- Featured employer sponsorship: $50/month
- Recruiter tools: $99/month (API access to job data)

### **Indirect Revenue** (Primary)
- **Tier upgrade driver**: "Want to hire faster? Boost to Founder tier"
- **Platform stickiness**: Owners come back to check applications
- **Word-of-mouth**: Job seekers join KIN to find openings
- **Ecosystem lock-in**: Owner + employee both on platform = more posts, more spending

---

## Integration Points Across App

### **Navigation**
```
Bottom Nav Update:
- Map (existing)
- Directory (existing)
- Jobs (NEW - Tab 3) ← PROMINENT, everyone can browse/apply
- Exchange (existing)
- Profile (existing)

Hamburger menu: "Browse Jobs" link
Owner Profile: "My Job Postings" section (post/edit/manage)
```

**Access Control:**
- ✅ **Business owners**: Can post, edit, delete their own jobs (any tier)
- ✅ **Customers**: Can browse all jobs + apply
- ✅ **Both roles**: Can bookmark/save jobs
- ❌ **Customers**: Cannot post jobs (owner-only feature)

### **Business Profile Page (Owner View)**
```
Owner Dashboard section:
┌────────────────────────────┐
│ 💼 My Job Postings         │
│                            │
│ Active: 3 • Applications: 8│
│                            │
│ [Post a Job]               │
│ [View All]                 │
│                            │
│ Recent postings:           │
│ • Mobile Stylist (5 apps)  │
│ • Driver (2 apps)          │
│ • Kitchen Staff (1 app)    │
│                            │
│ [Manage Postings]          │
└────────────────────────────┘

Features for owner:
- Post new job (1-tap from dashboard)
- View applications (see who applied)
- Message candidates
- Mark as filled/closed
- Renew expiration
- View job analytics (views, applies)
```

### **Business Profile Page (Customer View)**
```
Customer sees:
- "Hiring Now" badge (if active jobs)
- "[View Open Positions]" link
- 1-2 featured open roles with apply CTA
```

### **Customer Profile Page**
```
Customer can:
- Toggle "I'm looking for work" badge
- Browse local job opportunities
- Apply directly from profile page
- Get job recommendations based on skills
```

### **Exchange Feed**
```
Occasional carousel card:
"🎯 Help Us Grow!
We're hiring mobile stylists, 
delivery drivers, and kitchen staff.

[Browse Open Positions]"
```

### **KIN Quest Integration**
```
Quest objective idea:
"Find a Black-owned business that's hiring"
- Customers explore jobs
- Post a job if they own a business
- Get +25 KIN points for posting
- Get +50 KIN points for hiring first employee
```

---

## Content Moderation

### **What Gets Posted**
✅ Legitimate job openings
✅ Internships, apprenticeships, gigs
✅ Volunteer opportunities (tagged)
✅ Collaborative work opportunities

### **What Doesn't**
❌ MLM/pyramid schemes
❌ Discrimination ("No X people")
❌ Scams or fake opportunities
❌ Adult/explicit content
❌ Commercial spam

### **Moderation Process**
1. Auto-filters for keywords (MLM, spam phrases)
2. Manual review for flagged posts
3. Community reporting: Users can flag inappropriate posts
4. Admin review: Deleted within 24 hours if violation confirmed
5. Repeat violators: Business profile suspended from job board

---

## Job Board Features (Phase Rollout)

### **Phase 1: Basic Job Board** (Week 1-2)
- [ ] Job posting form (title, rate, description, expiration)
- [ ] Job listing page (filter by type, location)
- [ ] Apply via email/phone
- [ ] Moderation system (keyword filtering)
- [ ] Basic analytics (view count)

### **Phase 2: Messaging & Matching** (Week 3-4)
- [ ] In-app messaging (owner ↔ candidate)
- [ ] Applicant profile browsing
- [ ] "Looking for work" badge for candidates
- [ ] Search filters (job type, rate, skills)
- [ ] Save jobs for later

### **Phase 3: Tier-Based Features** (Week 5-6)
- [ ] Job post boosting (Founder+ tier)
- [ ] "Hiring" badge on business profiles
- [ ] Featured "Top Openings" carousel
- [ ] Job post analytics dashboard
- [ ] Bulk job posting tool

### **Phase 4: Community & Growth** (Week 7-8)
- [ ] Job board leaderboard (most active hirers)
- [ ] "Hire from KIN" badge for businesses
- [ ] KIN Quest job board challenges
- [ ] Job referral bonuses (earn points for successful hire)
- [ ] Employer spotlight profiles

### **Phase 5: Advanced Tools** (Week 9-10)
- [ ] Premium candidate matching AI
- [ ] Job board API (for third-party integrations)
- [ ] Hiring analytics (salary trends, time-to-hire)
- [ ] Multi-location job posting (for growing businesses)
- [ ] Integration with payroll/HR tools

---

## Success Metrics & Admin Dashboard

Track these KPIs (displayed on admin dashboard):

```
Job Posting Metrics:
- Total active job postings (right now)
- Jobs posted this week/month
- Jobs posted by tier (Free vs. Founder vs. Founding Local+)
- Average time to hire
- Job post expiration/renewal rate

Engagement Metrics:
- Total applications received
- Applications per posting (avg)
- Profile views (owner ← candidate)
- In-app messages sent
- Bookmarks/saves per job
- Job board page views/session count

Business Metrics:
- Tier upgrade attributed to job board
- Retention (owners using job board vs. not)
- New user acquisition (via job seeker discovery)
- Businesses that hired through KIN (conversions)

Community Metrics:
- "Looking for work" badge adoption rate
- Success stories (hires documented)
- Most active hiring businesses
```

### **Admin Dashboard Card: Job Board Metrics**
```
📊 Job Board Activity

Active Postings: 127
This Week: +23 new jobs
Applications: 456 total
  • Avg 3.6 per posting
  • Response time: 8.2 hrs

Top Hiring Businesses:
  1. Tasha's Mobile Salon (12 jobs, 8 hires)
  2. Soul Food Kitchen (8 jobs, 3 hires)
  3. Carmen's Catering (6 jobs, 4 hires)

Candidate Engagement:
  • "Looking for work" badges: 234
  • Bookmarks: 567
  • Messages sent: 1,204
```

---

## Example User Journey

### **Mobile Barber (Hiring via Free Tier)**
```
1. Tasha posts on KIN: "Need 2 mobile stylists, $18/hr, flexible"
2. Gets 5 applications in 48 hours
3. Meets 2 candidates via in-app messaging
4. Hires 1 candidate, both now on KIN
5. New hire starts referring other stylists
6. Tasha sees job board is working → upgrades to Founder tier
7. Posts job boost → gets 3 more qualified candidates
8. Hires 2nd employee → business grows
9. Now considers Premium Local tier for other business features
```

### **Job Seeker (Finding Opportunity)**
```
1. Marcus joins KIN app to discover Black-owned businesses
2. Browses businesses for discovery (Quest)
3. Sees "Jobs" tab → browses openings
4. Finds Tasha's Mobile Salon hiring
5. Applies in-app + message back and forth
6. Gets hired, starts work
7. Now discovers new businesses, pays it forward
8. Invites friends to apply → referral loop
```

---

## Why This Works for KIN

✅ **Solves real problem**: Mobile barbers need hiring flexibility
✅ **Drives engagement**: Owners check applications daily
✅ **Builds community**: Job seekers become customers, then owners
✅ **Revenue indirect**: Tier upgrades for better hiring features
✅ **Aligned with mission**: Supports Black business growth at every stage
✅ **Viral loop**: Employee → becomes customer → becomes owner → posts jobs
✅ **Sticky**: Job board creates recurring daily habit

---

## Implementation Notes

### **Technical Considerations**
- Job posting collection in Firestore
  - Fields: title, businessRef, jobType, location, rateMin/Max, description, tags, expiresAt, status, applicationCount
  - Indexes: businessRef, expiresAt, status (for "active jobs")
- Search/filter indexing (location, job type, rate range)
- Application tracking (applicantRef, jobRef, timestamp, status)
- Messaging system (leverage existing Exchange messaging)
- Moderation queue (admin dashboard)
- Analytics tracking (views, applications, hires)
- Admin Dashboard Card: `admin_job_board_metrics_card` (new component)
  - Shows: active postings, weekly postings, top hiring businesses, engagement metrics

### **Content Seeding (Day 1)**
- Partner with 5-10 local Black-owned businesses to post sample jobs
- Recruit 20-30 job seekers in beta (friends/family of early users)
- Collect success stories for marketing

### **Moderation Team Needs**
- 1 FTE for first 6 months (part-time contract acceptable)
- Clear community guidelines
- Appeal process for rejected postings

---

## Summary

**Job Board = Community Infrastructure**

Not a monetization feature, but a **business enablement feature** that:
- Helps owners hire (solves real problem)
- Helps seekers find work (grows community)
- Drives tier upgrades (financial incentive for better tools)
- Builds stickiness (daily recurring engagement)
- Aligns with KIN mission (support Black business growth)

**Result**: KIN becomes essential infrastructure, not just a discovery app. 🚀
