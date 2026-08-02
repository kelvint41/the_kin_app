# Firestore Job Board Schema

**Last Updated**: 2026-08-02
**Status**: Ready for implementation
**Database**: Firebase Cloud Firestore

---

## Collections Overview

```
firestore/
├── job_postings/
│   ├── {jobId}
│   │   ├── businessRef (reference)
│   │   ├── title (string)
│   │   ├── description (string)
│   │   ├── jobType (string: full-time, part-time, contract, gig)
│   │   ├── location (string)
│   │   ├── rateMin (number)
│   │   ├── rateMax (number)
│   │   ├── tags (array: skills, requirements)
│   │   ├── postedAt (timestamp)
│   │   ├── expiresAt (timestamp)
│   │   ├── status (string: active, expired, filled, draft)
│   │   ├── viewCount (number)
│   │   ├── applicationCount (number)
│   │   └── /applications (subcollection)
│   │
├── job_applications/
│   ├── {applicationId}
│   │   ├── jobRef (reference)
│   │   ├── applicantRef (reference)
│   │   ├── appliedAt (timestamp)
│   │   ├── status (string: pending, interested, rejected, hired)
│   │   ├── messageCount (number)
│   │   └── /messages (subcollection)
│   │
└── job_messages/
    ├── {messageId}
    │   ├── jobRef (reference)
    │   ├── applicationRef (reference)
    │   ├── fromRef (reference: user)
    │   ├── toRef (reference: user)
    │   ├── messageText (string)
    │   ├── sentAt (timestamp)
    │   └── read (boolean)
```

---

## Collection: job_postings

### Document Structure

```firestore
{
  // Required fields
  businessRef: reference → /businesses/{businessId},
  title: string,              // "Mobile Stylist" (50 char max)
  description: string,        // Full job description (150+ chars)
  jobType: string,            // enum: full-time|part-time|contract|gig
  location: string,           // City, state or "Mobile/Remote"
  rateMin: number,            // Hourly rate minimum (e.g., 18.00)
  rateMax: number,            // Hourly rate maximum (e.g., 25.00)
  tags: array<string>,        // ["flexible-hours", "transportation-required", "experience-helpful"]
  
  // Timestamps
  postedAt: timestamp,        // When job was posted (server timestamp)
  expiresAt: timestamp,       // When job expires (30/60/90 days from now)
  
  // Status & Visibility
  status: string,             // enum: draft|active|expired|filled
  isDraft: boolean,           // True = not yet published
  
  // Analytics
  viewCount: number,          // How many times viewed (incremented by trackJobView())
  applicationCount: number,   // How many applications received
  lastViewedAt: timestamp,    // When last viewed
  
  // Optional fields
  imageUrl: string,           // Optional hero image for job (nullable)
  benefits: array<string>,    // ["meals provided", "flexible schedule"]
  requirements: array<string>, // ["transportation", "valid ID"]
  
  // Metadata
  createdBy: reference,       // User who posted (for audit)
  updatedAt: timestamp,       // Last modified
  deletedAt: timestamp,       // Soft delete (nullable)
}
```

### Indexes Required

```
Composite Indexes:
- (businessRef, status, expiresAt) - Ascending
  Purpose: List active jobs for a business

- (status, expiresAt, postedAt) - [Ascending, Ascending, Descending]
  Purpose: Show active jobs, newest first

- (status, jobType, location) - [Ascending, Ascending, Ascending]
  Purpose: Filter jobs by type and location

Single Field Indexes (auto-created):
- status (Ascending) - For global status queries
- expiresAt (Ascending) - For expiration queries
- viewCount (Descending) - For "trending jobs"
- postedAt (Descending) - For "newest jobs"
```

### Subcollection: job_postings/{jobId}/applications

Links to `job_applications` for easy querying by job. Denormalized for performance.

```firestore
{
  jobRef: reference → /job_postings/{jobId},
  applicantRef: reference → /users/{userId},
  appliedAt: timestamp,
  status: string,  // pending|interested|rejected|hired
}
```

---

## Collection: job_applications

### Document Structure

```firestore
{
  // References
  jobRef: reference → /job_postings/{jobId},
  applicantRef: reference → /users/{userId},
  businessRef: reference → /businesses/{businessId},  // Denormalized for security rules
  
  // Timeline
  appliedAt: timestamp,       // When application submitted
  respondedAt: timestamp,     // When business first responded (nullable)
  hiredAt: timestamp,         // When hired (nullable)
  
  // Status
  status: string,             // enum: pending|interested|rejected|hired
  
  // Communication
  messageCount: number,       // How many messages exchanged
  lastMessageAt: timestamp,   // When last message sent (nullable)
  
  // Metadata
  createdAt: timestamp,
  updatedAt: timestamp,
  deletedAt: timestamp,       // Soft delete (nullable)
}
```

### Indexes Required

```
Composite Indexes:
- (jobRef, appliedAt) - Descending
  Purpose: Show applications for a job, newest first

- (applicantRef, status, appliedAt) - [Ascending, Ascending, Descending]
  Purpose: Show all applications sent by user

- (businessRef, status, respondedAt) - [Ascending, Ascending, Descending]
  Purpose: Show applications for a business owner to review

Single Field Indexes:
- status (Ascending) - For filtering pending/hired
- appliedAt (Descending) - For sorting
```

### Subcollection: job_applications/{applicationId}/messages

Contains conversation between applicant and business owner.

```firestore
{
  jobRef: reference,
  applicationRef: reference,
  fromRef: reference → /users/{userId},
  toRef: reference → /users/{userId},
  messageText: string,
  sentAt: timestamp,
  read: boolean,
}
```

---

## Collection: job_messages

### Document Structure (Alternative to subcollection)

Use this if messages need to be queried globally (e.g., "all my job-related messages").

```firestore
{
  // Context
  jobRef: reference → /job_postings/{jobId},
  applicationRef: reference → /job_applications/{applicationId},
  
  // Participants
  fromRef: reference → /users/{userId},  // Who sent
  toRef: reference → /users/{userId},    // Who receives
  
  // Message
  messageText: string,        // Message body (max 1000 chars)
  attachmentUrl: string,      // Optional file/image (nullable)
  
  // Metadata
  sentAt: timestamp,
  readAt: timestamp,          // When recipient read it (nullable)
  deletedAt: timestamp,       // Soft delete (nullable)
}
```

### Indexes Required

```
Composite Indexes:
- (toRef, readAt, sentAt) - [Ascending, Ascending, Descending]
  Purpose: Get unread messages for a user, newest first

- (fromRef, sentAt) - Descending
  Purpose: Get all messages sent by a user

- (applicationRef, sentAt) - Descending
  Purpose: Get conversation for an application
```

---

## Data Validation Rules

### job_postings

```
- title: 
  - min length: 3 chars
  - max length: 50 chars
  - required: true
  
- description:
  - min length: 150 chars
  - max length: 2000 chars
  - required: true
  
- jobType:
  - enum: [full-time, part-time, contract, gig]
  - required: true
  
- location:
  - min length: 2 chars
  - max length: 100 chars
  - required: true
  
- rateMin / rateMax:
  - min value: 5.00 (minimum wage floor)
  - max value: 999.99
  - constraint: rateMin <= rateMax
  - required: true
  
- expiresAt:
  - must be: >= now + 1 day, <= now + 90 days
  - required: true
  
- tags:
  - max items: 10
  - max length per item: 30 chars
```

### job_applications

```
- status:
  - enum: [pending, interested, rejected, hired]
  - required: true
  
- appliedAt:
  - must be: <= now
  - required: true
```

### job_messages

```
- messageText:
  - min length: 1 char
  - max length: 1000 chars
  - required: true
  
- sentAt:
  - must be: <= now
  - required: true
```

---

## Security Rules Summary

See `FIRESTORE_JOB_BOARD_SECURITY_RULES.md` for complete rules.

**Key Principles:**
- Only job posters (business owners) can create/edit/delete their own jobs
- All authenticated users can view job listings
- Only applicants and job poster can see application details
- Only involved parties can message each other
- Admins can moderate (delete spam, ban users)

---

## Query Examples

### Get Active Jobs for a Business

```
db.collection('job_postings')
  .where('businessRef', '==', businessRef)
  .where('status', '==', 'active')
  .orderBy('postedAt', 'desc')
  .get()
```

### Get All Applications for a Job

```
db.collection('job_postings')
  .doc(jobId)
  .collection('applications')
  .orderBy('appliedAt', 'desc')
  .get()
```

### Get Applications I've Submitted

```
db.collection('job_applications')
  .where('applicantRef', '==', userRef)
  .orderBy('appliedAt', 'desc')
  .get()
```

### Get Messages for an Application

```
db.collection('job_applications')
  .doc(applicationId)
  .collection('messages')
  .orderBy('sentAt', 'desc')
  .get()
```

### Find Jobs in a Location (Text Search)

```
// Requires full-text search extension or workaround
db.collection('job_postings')
  .where('status', '==', 'active')
  .where('location', '==', 'San Antonio, TX')
  .orderBy('postedAt', 'desc')
  .get()
```

---

## Performance Considerations

### Write Operations
- Job post creation: ~5ms (single write)
- Application submission: ~10ms (2 writes: job_applications + job_postings.applicationCount++)
- Message send: ~5ms (single write)

### Read Operations
- List jobs: 100-500ms (depends on result size, 100-500 docs)
- Get single job: ~5ms
- Get applications for job: 50-200ms (10-100 docs)
- Get unread messages: 20-100ms (5-50 docs)

### Optimization Strategies
- Use denormalized fields (applicationCount on job_postings)
- Paginate large result sets (25 jobs per page)
- Cache frequently accessed data (active jobs list)
- Use Cloud CDN for popular jobs

---

## Soft Delete Strategy

Instead of permanently deleting jobs/applications, use `deletedAt` timestamp:

```
// "Delete" a job
db.collection('job_postings').doc(jobId).update({
  deletedAt: serverTimestamp()
})

// Query only non-deleted jobs
db.collection('job_postings')
  .where('deletedAt', '==', null)
  .where('status', '==', 'active')
  .get()
```

**Benefits:**
- Preserve application history
- Ability to undelete
- Audit trail
- GDPR compliance (soft deletes are easier to track)

---

## Testing Data

### Sample Job Posting

```firestore
{
  businessRef: ref('businesses/tasha_salon'),
  title: "Mobile Stylist Assistant",
  description: "Help with client bookings and hair styling. Must have transportation. Flexible schedule for school or side gigs. We're all about supporting Black businesses!",
  jobType: "part-time",
  location: "San Antonio, TX",
  rateMin: 18.00,
  rateMax: 22.00,
  tags: ["flexible-hours", "transportation-required", "experience-helpful"],
  postedAt: <timestamp>,
  expiresAt: <timestamp + 30 days>,
  status: "active",
  isDraft: false,
  viewCount: 47,
  applicationCount: 8,
  createdBy: ref('users/tasha_owner'),
  updatedAt: <timestamp>
}
```

---

## Data Migration Plan

If migrating from existing job data:
1. Export existing jobs to CSV
2. Transform to schema (map old fields to new fields)
3. Batch import to Firestore (using Admin SDK)
4. Validate all documents match schema
5. Run test queries to verify indexes work

---

## Next Steps

1. ✅ Schema defined (this document)
2. 🔄 Create Firestore security rules
3. 🔄 Implement Cloud Functions
4. 🔄 Create database indexes
5. 🔄 Integration with Flutter app backend
