import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";

const db = admin.firestore();

// Configure email transporter
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.GMAIL_USER || "events@kinapp.com",
    pass: process.env.GMAIL_PASSWORD || "",
  },
});

// ===== FUNCTION 1: notifyEventPosted =====
// Triggered when business owner posts a new event
export const notifyEventPosted = functions.firestore
  .document("community_events/{eventId}")
  .onCreate(async (snap, context) => {
    try {
      const event = snap.data();
      const { eventId } = context.params;

      // Get business details
      const businessDoc = await event.businessRef.get();
      const business = businessDoc.data();

      if (!business) {
        console.warn(`Business ${event.businessRef.id} not found`);
        return;
      }

      // Get business owner
      const ownerRef = business.owner_ref;
      const ownerDoc = await ownerRef.get();
      const owner = ownerDoc.data();

      // Notify nearby users about new event (future: use geohash)
      const userSnapshot = await db
        .collection("users")
        .where("lookingForCommunityEvents", "==", true)
        .limit(50)
        .get();

      for (const userDoc of userSnapshot.docs) {
        await db.collection("notifications").add({
          userId: userDoc.id,
          type: "community_event_posted",
          title: `New ${event.eventType.replace(/_/g, " ")} event`,
          body: `${business.businessName} posted: ${event.title}`,
          data: {
            eventId: eventId,
            businessId: event.businessRef.id,
          },
          createdAt: admin.firestore.Timestamp.now(),
          read: false,
        });
      }

      console.log(`✓ Notified users about event ${eventId}`);
      return { success: true };
    } catch (error) {
      console.error("Error notifying event posted:", error);
      return { error: error };
    }
  });

// ===== FUNCTION 2: notifyPartnershipRequest =====
// Triggered when business sends partnership request for an event
export const notifyPartnershipRequest = functions.firestore
  .document("partnership_requests/{requestId}")
  .onCreate(async (snap, context) => {
    try {
      const request = snap.data();

      // Get sender business
      const senderDoc = await request.fromBusinessRef.get();
      const senderBusiness = senderDoc.data();

      // Get recipient business owner
      const recipientBizDoc = await request.toBusinessRef.get();
      const recipientBusiness = recipientBizDoc.data();

      if (!recipientBusiness || !recipientBusiness.owner_ref) {
        console.warn(
          `Recipient business ${request.toBusinessRef.id} not found`
        );
        return;
      }

      const recipientOwnerRef = recipientBusiness.owner_ref;
      const recipientOwnerDoc = await recipientOwnerRef.get();
      const recipientOwner = recipientOwnerDoc.data();

      // Send in-app notification
      await db.collection("notifications").add({
        userId: recipientOwnerRef.id,
        type: "partnership_request",
        title: "Partnership opportunity",
        body: `${senderBusiness.businessName} wants to partner on an event`,
        data: {
          requestId: snap.id,
          senderId: request.fromBusinessRef.id,
        },
        createdAt: admin.firestore.Timestamp.now(),
        read: false,
      });

      // Send email notification
      if (recipientOwner?.email) {
        const emailContent = `
          <h2>Partnership Request</h2>
          <p>Hi ${recipientOwner.displayName},</p>
          <p><strong>${senderBusiness.businessName}</strong> would like to partner with you on a community event!</p>
          <p>Review this request in the KIN app to accept or decline.</p>
          <p>Let's grow the community together!</p>
          <p>Best regards,<br/>The KIN Team</p>
        `;

        await transporter.sendMail({
          from: "events@kinapp.com",
          to: recipientOwner.email,
          subject: `${senderBusiness.businessName} wants to partner`,
          html: emailContent,
        });
      }

      console.log(
        `✓ Sent partnership request notification to ${recipientOwnerRef.id}`
      );
      return { success: true };
    } catch (error) {
      console.error("Error notifying partnership request:", error);
      return { error: error };
    }
  });

// ===== FUNCTION 3: calculateCommunityEventMetrics =====
// Scheduled hourly to calculate event metrics for admin dashboard
export const calculateCommunityEventMetrics = functions.pubsub
  .schedule("0 * * * *")
  .timeZone("UTC")
  .onRun(async (context) => {
    try {
      const now = admin.firestore.Timestamp.now();
      const sevenDaysAgo = new admin.firestore.Timestamp(
        now.seconds - 604800,
        now.nanoseconds
      );

      // Metric 1: Active events (published and upcoming)
      const activeEventsResult = await db
        .collection("community_events")
        .where("status", "==", "published")
        .where("eventDate", ">=", now)
        .count()
        .get();

      const activeEvents = activeEventsResult.data().count;

      // Metric 2: Events this week
      const weeklyEventsResult = await db
        .collection("community_events")
        .where("status", "==", "published")
        .where("eventDate", ">=", sevenDaysAgo)
        .where("eventDate", "<=", now)
        .count()
        .get();

      const weeklyEvents = weeklyEventsResult.data().count;

      // Metric 3: Events by type
      const eventTypeSnapshot = await db
        .collection("community_events")
        .where("status", "==", "published")
        .get();

      const eventsByType: { [key: string]: number } = {};
      eventTypeSnapshot.docs.forEach((doc) => {
        const type = doc.data().eventType;
        eventsByType[type] = (eventsByType[type] || 0) + 1;
      });

      // Metric 4: Total attendees across events
      let totalAttendees = 0;
      for (const eventDoc of eventTypeSnapshot.docs) {
        const attendeesSnapshot = await eventDoc.ref
          .collection("attendees")
          .count()
          .get();
        totalAttendees += attendeesSnapshot.data().count;
      }

      // Metric 5: Partnership requests (pending)
      const partnershipResult = await db
        .collection("partnership_requests")
        .where("status", "==", "pending")
        .count()
        .get();

      const pendingPartnerships = partnershipResult.data().count;

      // Store metrics
      const metricsRef = db.collection("admin_metrics").doc("community_events");
      await metricsRef.set(
        {
          activeEvents,
          weeklyEvents,
          eventsByType,
          totalAttendees,
          pendingPartnerships,
          calculatedAt: now,
          lastUpdated: now,
        },
        { merge: true }
      );

      console.log("✓ Calculated community events metrics");
      return { success: true };
    } catch (error) {
      console.error("Error calculating metrics:", error);
      throw error;
    }
  });

// ===== FUNCTION 4: autoCompleteEvents =====
// Scheduled daily to mark past events as "completed"
export const autoCompleteEvents = functions.pubsub
  .schedule("0 1 * * *")
  .timeZone("UTC")
  .onRun(async (context) => {
    try {
      const now = admin.firestore.Timestamp.now();

      const pastEventsResult = await db
        .collection("community_events")
        .where("status", "==", "published")
        .where("eventDate", "<", now)
        .get();

      let completedCount = 0;
      const batch = db.batch();

      pastEventsResult.docs.forEach((doc) => {
        batch.update(doc.ref, {
          status: "completed",
          updatedAt: now,
        });
        completedCount++;
      });

      if (completedCount > 0) {
        await batch.commit();
      }

      console.log(`✓ Marked ${completedCount} events as completed`);
      return { success: true, completedCount };
    } catch (error) {
      console.error("Error completing events:", error);
      throw error;
    }
  });

// ===== FUNCTION 5: searchNearbyEvents =====
// Callable function to find events near a location
export const searchNearbyEvents = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { latitude, longitude, radiusKm = 5, eventType = null } = data;

    if (!latitude || !longitude || typeof latitude !== "number" || typeof longitude !== "number") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "latitude and longitude required"
      );
    }

    try {
      // Simple radius search (production: use Firestore geohashing)
      const radiusMeters = radiusKm * 1000;

      let query = db
        .collection("community_events")
        .where("status", "==", "published");

      if (eventType) {
        query = query.where("eventType", "==", eventType);
      }

      const snapshot = await query.get();

      // Filter by distance (basic implementation)
      const nearby = snapshot.docs
        .map((doc) => {
          const event = doc.data();
          const businessLoc = event.businessLocation;

          // Calculate distance (simplified)
          const dLat = businessLoc?.latitude - latitude || 999;
          const dLng = businessLoc?.longitude - longitude || 999;
          const distance = Math.sqrt(dLat * dLat + dLng * dLng) * 111; // rough km conversion

          return { id: doc.id, ...event, distance };
        })
        .filter((e) => e.distance <= radiusMeters / 1000)
        .sort((a, b) => a.distance - b.distance);

      return { success: true, events: nearby, count: nearby.length };
    } catch (error) {
      console.error("Error searching nearby events:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to search events"
      );
    }
  }
);
