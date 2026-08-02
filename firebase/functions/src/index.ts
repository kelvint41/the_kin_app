import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";

// Initialize Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();

// Configure email transporter (update with your email provider)
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.GMAIL_USER || "jobs@kinapp.com",
    pass: process.env.GMAIL_PASSWORD || "",
  },
});

// ===== FUNCTION 1: expireJobPostings =====
// Runs daily at 2 AM UTC to mark expired jobs
export const expireJobPostings = functions.pubsub
  .schedule("0 2 * * *")
  .timeZone("UTC")
  .onRun(async (context) => {
    try {
      const now = admin.firestore.Timestamp.now();

      const expiredJobs = await db
        .collection("job_postings")
        .where("status", "==", "active")
        .where("expiresAt", "<=", now)
        .get();

      let expiredCount = 0;
      const batch = db.batch();

      expiredJobs.docs.forEach((doc) => {
        batch.update(doc.ref, {
          status: "expired",
          updatedAt: now,
        });
        expiredCount++;
      });

      if (expiredCount > 0) {
        await batch.commit();
      }

      console.log(`✓ Expired ${expiredCount} job postings`);
      return { success: true, expiredCount };
    } catch (error) {
      console.error("Error expiring jobs:", error);
      throw error;
    }
  });

// ===== FUNCTION 2: trackJobView =====
// Called from app when user opens a job detail page
export const trackJobView = functions.https.onCall(
  async (data, context) => {
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

      await jobRef.update({
        viewCount: admin.firestore.FieldValue.increment(1),
        lastViewedAt: admin.firestore.Timestamp.now(),
      });

      const updated = await jobRef.get();
      return { success: true, viewCount: updated.data()?.viewCount || 0 };
    } catch (error) {
      console.error("Error tracking job view:", error);
      throw new functions.https.HttpsError("internal", "Failed to track view");
    }
  }
);

// ===== FUNCTION 3: notifyOnJobApply =====
// Triggered when someone applies to a job
export const notifyOnJobApply = functions.firestore
  .document("job_applications/{applicationId}")
  .onCreate(async (snap, context) => {
    try {
      const application = snap.data();
      const { applicationId } = context.params;
      const jobId = application.jobRef.id;

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

      // Get business details
      const businessRef = job.businessRef;
      const businessDoc = await businessRef.get();
      const business = businessDoc.data();

      // Get owner user
      const ownerRef = business?.ownerRef || business?.owner_ref;
      if (!ownerRef) {
        console.warn(`No owner found for business ${businessRef.id}`);
        return;
      }

      const ownerDoc = await ownerRef.get();
      const owner = ownerDoc.data();

      // Send in-app notification
      await db.collection("notifications").add({
        userId: ownerRef.id,
        type: "job_application",
        title: `New application for "${job.title}"`,
        body: `${applicant?.displayName || "Someone"} applied for your job.`,
        data: {
          jobId: jobId,
          applicationId: applicationId,
          applicantId: applicantRef.id,
        },
        createdAt: admin.firestore.Timestamp.now(),
        read: false,
      });

      // Send email notification
      const emailContent = `
        <h2>New Job Application</h2>
        <p>Hi ${owner?.displayName || "Business Owner"},</p>
        <p><strong>${applicant?.displayName || "Someone"}</strong> applied for your job posting:</p>
        <h3>${job.title}</h3>
        <p><strong>Location:</strong> ${job.location}</p>
        <p><strong>Rate:</strong> $${job.rateMin} - $${job.rateMax}/hr</p>

        <p><strong>Applicant Contact:</strong></p>
        <p>Email: ${applicant?.email || "Not provided"}</p>
        <p>Phone: ${applicant?.phone || "Not provided"}</p>

        <p><a href="https://kinapp.com/jobs/${jobId}/applications/${applicationId}">
          View Application & Message
        </a></p>

        <p>Best regards,<br/>The KIN Team</p>
      `;

      if (owner?.email) {
        await transporter.sendMail({
          from: "jobs@kinapp.com",
          to: owner.email,
          subject: `New application for "${job.title}"`,
          html: emailContent,
        });
      }

      // Increment application count on job
      await jobDoc.ref.update({
        applicationCount: admin.firestore.FieldValue.increment(1),
      });

      console.log(
        `✓ Notified owner of new application to job ${jobId}`
      );

      return { success: true };
    } catch (error) {
      console.error("Error notifying on job apply:", error);
      // Don't throw - log and continue
    }
  });

// ===== FUNCTION 4: calculateJobBoardMetrics =====
// Runs hourly to calculate metrics for admin dashboard
export const calculateJobBoardMetrics = functions.pubsub
  .schedule("0 * * * *")
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

      // Metric 1: Active job postings
      const activeJobsResult = await db
        .collection("job_postings")
        .where("status", "==", "active")
        .count()
        .get();

      const activePostings = activeJobsResult.data().count;

      // Metric 2: Jobs posted this week
      const weeklyJobsResult = await db
        .collection("job_postings")
        .where("postedAt", ">=", oneWeekAgo)
        .where("status", "!=", "draft")
        .count()
        .get();

      const weeklyPostings = weeklyJobsResult.data().count;

      // Metric 3: Total applications
      const totalApplicationsResult = await db
        .collection("job_applications")
        .count()
        .get();

      const totalApplications = totalApplicationsResult.data().count;

      // Metric 4: Average applications per job
      const jobStats = await db
        .collection("job_postings")
        .where("status", "==", "active")
        .get();

      let totalAppCount = 0;
      jobStats.docs.forEach((doc) => {
        totalAppCount += doc.data().applicationCount || 0;
      });

      const avgApplicationsPerJob =
        jobStats.docs.length > 0
          ? Math.round((totalAppCount / jobStats.docs.length) * 10) / 10
          : 0;

      // Metric 5: Top hiring businesses
      const hiredApplications = await db
        .collection("job_applications")
        .where("status", "==", "hired")
        .get();

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

      const topHirers: Array<{
        name: string;
        jobCount: number;
        hires: number;
      }> = [];

      for (const [businessId, stats] of businessMap) {
        try {
          const businessDoc = await db
            .collection("businesses")
            .doc(businessId)
            .get();
          if (businessDoc.exists) {
            topHirers.push({
              name: businessDoc.data()?.businessName || "Unknown",
              jobCount: stats.jobCount,
              hires: stats.hires,
            });
          }
        } catch (e) {
          console.warn(`Could not fetch business ${businessId}:`, e);
        }
      }

      topHirers.sort((a, b) => b.hires - a.hires);
      topHirers.splice(3); // Keep top 3

      // Metric 6: Candidates looking for work
      const withBadgesResult = await db
        .collection("users")
        .where("lookingForWork", "==", true)
        .count()
        .get();

      const candidatesLookingForWork = withBadgesResult.data().count;

      // Store metrics
      const metricsRef = db.collection("admin_metrics").doc("job_board");
      await metricsRef.set(
        {
          activePostings,
          weeklyPostings,
          totalApplications,
          avgApplicationsPerJob,
          topHiringBusinesses: topHirers,
          candidatesLookingForWork,
          calculatedAt: now,
          lastUpdated: now,
        },
        { merge: true }
      );

      console.log("✓ Calculated job board metrics");
      return { success: true };
    } catch (error) {
      console.error("Error calculating metrics:", error);
      throw error;
    }
  });
