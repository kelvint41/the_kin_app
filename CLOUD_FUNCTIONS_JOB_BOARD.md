# Cloud Functions: Job Board Backend

**Status**: Implementation templates ready
**Language**: TypeScript (Node.js 18+)
**Location**: `firebase/functions/src/job-board/`

---

## Overview

Four Cloud Functions handle job board automation:

| Function | Trigger | Purpose | Frequency |
|----------|---------|---------|-----------|
| `expireJobPostings` | Scheduled (daily 2 AM UTC) | Mark old jobs as expired | Daily |
| `trackJobView` | Firestore onCreate/onUpdate | Increment view counter | Per view |
| `notifyOnJobApply` | Firestore onCreate | Send notification + email | Per application |
| `calculateJobBoardMetrics` | Scheduled (hourly) | Aggregate stats for admin dashboard | Hourly |

---

## Function 1: expireJobPostings

**Purpose**: Automatically mark job postings as expired when their expiration date passes.

**Trigger**: Scheduled (daily at 2:00 AM UTC)

**Implementation**:

```typescript
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

export const expireJobPostings = functions.pubsub
  .schedule("0 2 * * *") // Daily at 2 AM UTC
  .timeZone("UTC")
  .onRun(async (context) => {
    try {
      const now = admin.firestore.Timestamp.now();
      
      // Query all active jobs that have expired
      const expiredJobs = await db
        .collection("job_postings")
        .where("status", "==", "active")
        .where("expiresAt", "<=", now)
        .get();

      let expiredCount = 0;

      // Batch update to mark as expired
      const batch = db.batch();
      expiredJobs.docs.forEach((doc) => {
        batch.update(doc.ref, {
          status: "expired",
          updatedAt: now,
        });
        expiredCount++;
      });

      await batch.commit();

      console.log(`✓ Expired ${expiredCount} job postings`);

      return { success: true, expiredCount };
    } catch (error) {
      console.error("Error expiring jobs:", error);
      throw error;
    }
  });
```

**Test**:
```bash
# Manually trigger via Firebase Console or:
firebase functions:shell
> expireJobPostings()
```

---

## Function 2: trackJobView

**Purpose**: Increment view counter when a job is opened.

**Trigger**: Firestore onCall (called from app when job detail page loads)

**Implementation**:

```typescript
export const trackJobView = functions.https.onCall(
  async (data, context) => {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { jobId } = data;

    if (!jobId || typeof jobId !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "jobId is required"
      );
    }

    try {
      const jobRef = db.collection("job_postings").doc(jobId);
      const jobDoc = await jobRef.get();

      if (!jobDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Job not found");
      }

      // Increment viewCount using server timestamp
      await jobRef.update({
        viewCount: admin.firestore.FieldValue.increment(1),
        lastViewedAt: admin.firestore.Timestamp.now(),
      });

      // Return updated view count
      const updated = await jobRef.get();
      return { viewCount: updated.data()?.viewCount || 0 };
    } catch (error) {
      console.error("Error tracking job view:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to track view"
      );
    }
  }
);
```

**Usage from Flutter App**:
```dart
final functions = FirebaseFunctions.instance;

final result = await functions.httpsCallable('trackJobView').call({
  'jobId': jobId,
});

print('Views: ${result.data['viewCount']}');
```

---

## Function 3: notifyOnJobApply

**Purpose**: Send notification and email to business owner when someone applies.

**Trigger**: Firestore onCreate on `job_applications`

**Implementation**:

```typescript
import * as nodemailer from "nodemailer";

// Configure email (using SendGrid or Gmail)
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: functions.config().email.address,
    pass: functions.config().email.password,
  },
});

export const notifyOnJobApply = functions.firestore
  .document("job_applications/{applicationId}")
  .onCreate(async (snap, context) => {
    try {
      const application = snap.data();
      const { jobId } = context.params;

      // Get job details
      const jobDoc = await db.collection("job_postings").doc(jobId).get();
      const job = jobDoc.data();

      if (!job) {
        console.warn(`Job ${jobId} not found`);
        return;
      }

      // Get applicant details
      const applicantRef = application.applicantRef;
      const applicantDoc = await applicantRef.get();
      const applicant = applicantDoc.data();

      // Get business owner details
      const businessRef = job.businessRef;
      const businessDoc = await businessRef.get();
      const business = businessDoc.data();

      // Get owner user (who owns the business)
      const ownerRef = business.ownerRef || business.owner_ref;
      const ownerDoc = await ownerRef.get();
      const owner = ownerDoc.data();

      // Send in-app notification (update a notifications collection)
      await db.collection("notifications").add({
        userId: ownerRef.id, // Business owner's user ID
        type: "job_application",
        title: `New application for "${job.title}"`,
        body: `${applicant.displayName} applied for your job.`,
        data: {
          jobId: jobId,
          applicationId: snap.id,
          applicantId: applicantRef.id,
        },
        createdAt: admin.firestore.Timestamp.now(),
        read: false,
      });

      // Send email notification
      const emailContent = `
        <h2>New Job Application</h2>
        <p>Hi ${owner.displayName},</p>
        <p><strong>${applicant.displayName}</strong> applied for your job posting:</p>
        <h3>${job.title}</h3>
        <p><strong>Location:</strong> ${job.location}</p>
        <p><strong>Rate:</strong> $${job.rateMin} - $${job.rateMax}/hr</p>
        
        <p><strong>Applicant Details:</strong></p>
        <p>Email: ${applicant.email}</p>
        <p>Phone: ${applicant.phone || "Not provided"}</p>
        
        <p><a href="https://kinapp.com/jobs/${jobId}/applications/${snap.id}">
          View Application & Message
        </a></p>
        
        <p>Best regards,<br/>The KIN Team</p>
      `;

      await transporter.sendMail({
        from: "jobs@kinapp.com",
        to: owner.email,
        subject: `New application for "${job.title}"`,
        html: emailContent,
      });

      console.log(
        `✓ Notified owner of new application to job ${jobId}`
      );

      // Increment application count on job
      await jobDoc.ref.update({
        applicationCount: admin.firestore.FieldValue.increment(1),
      });

      return { success: true };
    } catch (error) {
      console.error("Error notifying on job apply:", error);
      // Don't throw - log and continue (don't fail the write)
    }
  });
```

---

## Function 4: calculateJobBoardMetrics

**Purpose**: Calculate and store aggregated metrics for the admin dashboard.

**Trigger**: Scheduled (hourly)

**Implementation**:

```typescript
export const calculateJobBoardMetrics = functions.pubsub
  .schedule("0 * * * *") // Every hour
  .timeZone("UTC")
  .onRun(async (context) => {
    try {
      const now = admin.firestore.Timestamp.now();
      const oneDayAgo = new admin.firestore.Timestamp(
        now.seconds - 86400,
        now.nanoseconds
      );
      const oneWeekAgo = new admin.firestore.Timestamp(
        now.seconds - 604800,
        now.nanoseconds
      );

      // Metric 1: Active job postings (right now)
      const activeJobs = await db
        .collection("job_postings")
        .where("status", "==", "active")
        .count()
        .get();

      // Metric 2: Jobs posted this week
      const weeklyJobs = await db
        .collection("job_postings")
        .where("postedAt", ">=", oneWeekAgo)
        .where("status", "!=", "draft")
        .count()
        .get();

      // Metric 3: Total applications
      const totalApplications = await db
        .collection("job_applications")
        .count()
        .get();

      // Metric 4: Average applications per job
      const jobStats = await db
        .collection("job_postings")
        .where("status", "==", "active")
        .get();

      let totalAppCount = 0;
      jobStats.docs.forEach((doc) => {
        totalAppCount += doc.data().applicationCount || 0;
      });

      const avgAppsPerJob =
        jobStats.docs.length > 0
          ? totalAppCount / jobStats.docs.length
          : 0;

      // Metric 5: Top hiring businesses (by applications)
      const topHirers: Array<{
        name: string;
        jobCount: number;
        hires: number;
      }> = [];

      const hiredApplications = await db
        .collection("job_applications")
        .where("status", "==", "hired")
        .get();

      // Group by business
      const businessMap = new Map<
        string,
        { jobCount: number; hires: number }
      >();
      hiredApplications.docs.forEach((doc) => {
        const businessRef = doc.data().businessRef.id;
        const current = businessMap.get(businessRef) || {
          jobCount: 0,
          hires: 0,
        };
        current.hires++;
        businessMap.set(businessRef, current);
      });

      // Fetch business names and sort
      for (const [businessId, stats] of businessMap) {
        const businessDoc = await db
          .collection("businesses")
          .doc(businessId)
          .get();
        if (businessDoc.exists) {
          topHirers.push({
            name: businessDoc.data().businessName,
            jobCount: stats.jobCount,
            hires: stats.hires,
          });
        }
      }
      topHirers.sort((a, b) => b.hires - a.hires);
      topHirers.splice(3); // Keep top 3

      // Metric 6: Candidate engagement
      const withBadges = await db
        .collection("users")
        .where("lookingForWork", "==", true)
        .count()
        .get();

      // Store metrics in a dedicated collection
      const metricsRef = db.collection("admin_metrics").doc("job_board");
      await metricsRef.set(
        {
          activePostings: activeJobs.data().count,
          weeklyPostings: weeklyJobs.data().count,
          totalApplications: totalApplications.data().count,
          avgApplicationsPerJob: Math.round(avgAppsPerJob * 10) / 10,
          topHiringBusinesses: topHirers,
          candidatesLookingForWork: withBadges.data().count,
          calculatedAt: now,
          lastUpdated: now,
        },
        { merge: true }
      );

      console.log("✓ Calculated job board metrics");

      return { success: true, metrics: { activeJobs } };
    } catch (error) {
      console.error("Error calculating metrics:", error);
      throw error;
    }
  });
```

**Fetch metrics in Flutter**:
```dart
final metricsDoc = await FirebaseFirestore.instance
  .collection('admin_metrics')
  .doc('job_board')
  .get();

final activePostings = metricsDoc.data()?['activePostings'] ?? 0;
```

---

## Deployment

### 1. Create Firebase Functions Project

```bash
cd firebase/functions
npm install
```

### 2. Configure Environment Variables

```bash
# .env.local
GMAIL_USER=jobs@kinapp.com
GMAIL_PASSWORD=<app-password>

# Or use SendGrid
SENDGRID_API_KEY=<key>
```

### 3. Deploy Functions

```bash
firebase deploy --only functions

# Or specific function:
firebase deploy --only functions:expireJobPostings
```

### 4. Test Functions

```bash
# Emulator mode
firebase emulators:start --only functions

# Logs
firebase functions:log
```

---

## Monitoring & Logging

### View Logs

```bash
# Recent logs
firebase functions:log --limit=100

# Filter by function
firebase functions:log --limit=100 expireJobPostings

# Real-time logs
firebase functions:log --follow
```

### Set Alerts

In Cloud Console, create alerts for:
- Function errors (alert if error rate > 5%)
- Function execution time (alert if avg > 5 seconds)
- Memory usage (alert if > 500MB)

---

## Performance Considerations

### Optimization Strategies

1. **Batch Operations**: Use `batch.commit()` for multiple writes
2. **Indexing**: Ensure proper Firestore indexes for queries
3. **Caching**: Cache frequently accessed data (e.g., top hirers)
4. **Pagination**: Process metrics in chunks if dataset is large

### Expected Performance

- `expireJobPostings`: ~2-5 seconds (scales with job count)
- `trackJobView`: ~100-200ms (instant)
- `notifyOnJobApply`: ~1-2 seconds (includes email)
- `calculateJobBoardMetrics`: ~5-10 seconds (scales with data)

---

## Cost Estimation (Monthly)

```
Function Invocations:
- expireJobPostings: 30 calls × 0.40 writes/call = $0.12
- trackJobView: 10,000 calls × 1 read/call = $0.50
- notifyOnJobApply: 500 calls × 2 writes/call = $0.20
- calculateJobBoardMetrics: 730 calls × 100 reads/call = $3.65

Total estimated: ~$4.47/month (negligible)
```

---

## Testing Checklist

- [ ] `expireJobPostings` correctly marks old jobs as expired
- [ ] `trackJobView` increments counter without duplicates
- [ ] `notifyOnJobApply` sends both in-app notification and email
- [ ] `calculateJobBoardMetrics` aggregates data correctly
- [ ] All functions handle errors gracefully
- [ ] Functions scale to production data volume
- [ ] Logs are comprehensive for debugging

---

## Future Enhancements

1. **Job Recommendations**: ML to suggest relevant jobs to users
2. **Auto-close**: Automatically mark jobs as "filled" after X hires
3. **Scheduled Messages**: Send reminder messages to non-responders
4. **Analytics Export**: Export metrics to BigQuery for analysis
5. **Webhooks**: Send job posting events to external systems
