const functions = require("firebase-functions");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}
const { createNotification } = require("./notifications.js");

/**
 * Job Board server side.
 *
 * These handlers previously existed only as TypeScript under
 * firebase/functions/src/, which nothing ever compiled or deployed - the
 * `functions` codebase deploys index.js and never requires ./src. They are
 * ported here because custom_cloud_functions is the codebase that actually
 * ships, and rewritten rather than copied: the originals wrote a
 * camelCase `notifications` shape (userId/read/data) that does not match
 * the app's inbox schema, and fanned out on `lookingForWork` /
 * `lookingForCommunityEvents` user fields that do not exist anywhere in
 * this codebase.
 *
 * Field names on job_postings/job_applications are camelCase because
 * JobBoardService writes them that way; the businesses doc they point at
 * still uses snake_case (owner_ref), hence the mix below.
 */

/**
 * Increments a posting's view counter.
 *
 * Callable rather than a client write so viewCount can't be inflated from
 * a device - firestore.rules lets an owner update their own posting, which
 * would otherwise let them pump their own view count.
 */
exports.trackJobView = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const jobId = request.data && request.data.jobId;
  if (!jobId || typeof jobId !== "string") {
    throw new HttpsError("invalid-argument", "jobId is required.");
  }

  const db = admin.firestore();
  const jobRef = db.collection("job_postings").doc(jobId);
  const snap = await jobRef.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Job not found.");
  }

  await jobRef.update({
    viewCount: admin.firestore.FieldValue.increment(1),
    lastViewedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { success: true };
});

/**
 * Tells a business owner someone applied, and keeps applicationCount true.
 *
 * The count lives on the posting so the browse list can show "N applied"
 * without reading the applications subcollection (which customers can't
 * read - applications carry the applicant's contact details).
 */
exports.notifyOnJobApply = onDocumentCreated(
  "job_applications/{applicationId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return null;
    const application = snap.data();
    const db = admin.firestore();

    const jobRef = application.jobRef;
    if (!jobRef) {
      console.log(
        `job_applications/${event.params.applicationId} has no jobRef - skipping.`,
      );
      return null;
    }

    const jobSnap = await jobRef.get();
    const job = jobSnap.exists ? jobSnap.data() : null;
    if (!job) {
      console.log(`Job ${jobRef.id} not found - skipping notification.`);
      return null;
    }

    // Counter first: it drives visible UI, so it should land even if the
    // owner lookup below turns out to be incomplete.
    await jobRef.update({
      applicationCount: admin.firestore.FieldValue.increment(1),
    });

    const businessRef = job.businessRef;
    const businessSnap = businessRef ? await businessRef.get() : null;
    const ownerRef = businessSnap && businessSnap.exists
      ? businessSnap.data().owner_ref
      : null;
    if (!ownerRef) {
      console.log(
        `No owner_ref for business on job ${jobRef.id} - counted the application but sent no notification.`,
      );
      return null;
    }

    const applicantName = application.applicantName || "Someone";
    await createNotification(db, {
      userRef: ownerRef,
      type: "job_application",
      title: `New application for "${job.title || "your job"}"`,
      body: `${applicantName} applied. Open Manage Jobs to review and message them.`,
      routeName: "JobManagement",
    });

    return null;
  },
);

/**
 * Daily sweep that retires postings past their expiresAt.
 *
 * Browse filters on status == 'active' (see JobBoardService.getAllActiveJobs),
 * so flipping status here is what actually removes a stale posting from the
 * board.
 */
exports.expireJobPostings = functions.pubsub
  .schedule("0 2 * * *")
  .timeZone("UTC")
  .onRun(async () => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    const expired = await db
      .collection("job_postings")
      .where("status", "==", "active")
      .where("expiresAt", "<=", now)
      .get();

    if (expired.empty) {
      console.log("No job postings to expire.");
      return null;
    }

    const batch = db.batch();
    expired.docs.forEach((doc) => {
      batch.update(doc.ref, { status: "expired", updatedAt: now });
    });
    await batch.commit();

    console.log(`Expired ${expired.size} job postings.`);
    return null;
  });

/**
 * Hourly rollup for the admin Job Board card.
 *
 * The original also reported a "candidates looking for work" count off a
 * users.lookingForWork field. Nothing in the app ever sets that field, so
 * the metric would have been a permanent zero presented as real - dropped
 * rather than shipped.
 */
exports.calculateJobBoardMetrics = functions.pubsub
  .schedule("0 * * * *")
  .timeZone("UTC")
  .onRun(async () => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    const oneWeekAgo = new admin.firestore.Timestamp(
      now.seconds - 604800,
      now.nanoseconds,
    );

    const activeSnap = await db
      .collection("job_postings")
      .where("status", "==", "active")
      .get();
    const activePostings = activeSnap.size;

    const weeklySnap = await db
      .collection("job_postings")
      .where("postedAt", ">=", oneWeekAgo)
      .get();
    const weeklyPostings = weeklySnap.size;

    const applicationsResult = await db
      .collection("job_applications")
      .count()
      .get();
    const totalApplications = applicationsResult.data().count;

    let totalAppCount = 0;
    activeSnap.docs.forEach((doc) => {
      totalAppCount += doc.data().applicationCount || 0;
    });
    const avgApplicationsPerJob = activePostings
      ? Math.round((totalAppCount / activePostings) * 10) / 10
      : 0;

    // Top hirers, by accepted applications.
    const hired = await db
      .collection("job_applications")
      .where("status", "==", "accepted")
      .get();
    const byBusiness = new Map();
    hired.docs.forEach((doc) => {
      const ref = doc.data().businessRef;
      if (!ref) return;
      byBusiness.set(ref.id, (byBusiness.get(ref.id) || 0) + 1);
    });

    const topHiringBusinesses = [];
    for (const [businessId, hires] of byBusiness) {
      const bizSnap = await db.collection("businesses").doc(businessId).get();
      if (bizSnap.exists) {
        topHiringBusinesses.push({
          name: bizSnap.data().business_name || "Unknown",
          hires,
        });
      }
    }
    topHiringBusinesses.sort((a, b) => b.hires - a.hires);
    topHiringBusinesses.splice(3);

    await db.collection("admin_metrics").doc("job_board").set(
      {
        activePostings,
        weeklyPostings,
        totalApplications,
        avgApplicationsPerJob,
        topHiringBusinesses,
        calculatedAt: now,
        lastUpdated: now,
      },
      { merge: true },
    );

    console.log("Calculated job board metrics.");
    return null;
  });
