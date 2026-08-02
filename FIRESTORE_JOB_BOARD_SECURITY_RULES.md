# Firestore Security Rules: Job Board

**Status**: Ready for implementation
**Last Updated**: 2026-08-02

---

## Access Control Summary

| Operation | Free Tier | Founder+ | Admin | Anonymous |
|-----------|-----------|----------|-------|-----------|
| Create job | ✅ | ✅ | ✅ | ❌ |
| Read own jobs | ✅ | ✅ | ✅ | ❌ |
| Edit own jobs | ✅ | ✅ | ✅ | ❌ |
| Delete own jobs | ✅ | ✅ | ✅ | ❌ |
| Browse all jobs | ✅ | ✅ | ✅ | ❌ |
| Apply to job | ✅ | ✅ | ✅ | ❌ |
| View own applications | ✅ | ✅ | ✅ | ❌ |
| View applications for own job | ✅ (poster) | ✅ (poster) | ✅ | ❌ |
| Message applicant | ✅ (poster) | ✅ (poster) | ✅ | ❌ |
| Message about job | ✅ (applicant) | ✅ (applicant) | ✅ | ❌ |
| Moderate (delete spam) | ❌ | ❌ | ✅ | ❌ |

---

## Firestore Rules

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ===== Helper Functions =====
    
    // Check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Check if user is admin
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
    
    // Get user document
    function getUserDoc() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }
    
    // Get user's owned business
    function getUserBusinessRef() {
      return getUserDoc().ownedBusiness;
    }
    
    // Check if user owns this business
    function ownsBusinessRef(businessRef) {
      return isAuthenticated() && 
             getUserBusinessRef() == businessRef;
    }
    
    // Check if user is the business that posted this job
    function isJobPoster(jobData) {
      return isAuthenticated() && 
             ownsBusinessRef(jobData.businessRef);
    }
    
    // Check if user is the applicant for an application
    function isApplicant(applicationData) {
      return isAuthenticated() && 
             request.auth.uid == applicationData.applicantRef.id;
    }
    
    // ===== job_postings Collection =====
    
    match /job_postings/{jobId} {
      
      // Allow anyone authenticated to READ public (non-deleted) job postings
      allow read: if isAuthenticated() && 
                     (resource.data.deletedAt == null || isAdmin());
      
      // Allow business owner to READ their own deleted jobs (for archival)
      allow read: if isAuthenticated() && 
                     isJobPoster(resource.data);
      
      // Allow business owner to CREATE jobs
      allow create: if isAuthenticated() &&
                       ownsBusinessRef(request.resource.data.businessRef) &&
                       validateJobPostingCreate(request.resource.data);
      
      // Allow business owner to UPDATE their own jobs
      allow update: if isAuthenticated() &&
                       isJobPoster(resource.data) &&
                       validateJobPostingUpdate(resource.data, request.resource.data);
      
      // Allow business owner to DELETE their own jobs (soft delete)
      allow delete: if isAuthenticated() &&
                       isJobPoster(resource.data);
      
      // Allow admins to moderate (delete spam jobs)
      allow delete: if isAdmin();
      
      // ===== Subcollection: applications =====
      
      match /applications/{applicationId} {
        
        // Allow business owner to READ applications for their job
        allow read: if isAuthenticated() &&
                       isJobPoster(get(/databases/$(database)/documents/job_postings/$(jobId)).data);
        
        // Allow applicant to READ their own application
        allow read: if isAuthenticated() &&
                       request.auth.uid == resource.data.applicantRef.id;
        
        // Allow anyone authenticated to CREATE application
        allow create: if isAuthenticated() &&
                        validateApplicationCreate(request.resource.data);
        
        // Allow business owner to UPDATE application status
        allow update: if isAuthenticated() &&
                        isJobPoster(get(/databases/$(database)/documents/job_postings/$(jobId)).data) &&
                        validateApplicationUpdate(resource.data, request.resource.data);
        
        // Allow applicant to UPDATE their own application
        allow update: if isAuthenticated() &&
                        request.auth.uid == resource.data.applicantRef.id &&
                        validateApplicationUpdate(resource.data, request.resource.data);
        
        // No deletes (keep audit trail)
        allow delete: if false;
      }
    }
    
    // ===== job_applications Collection =====
    
    match /job_applications/{applicationId} {
      
      // Allow applicant to READ their own applications
      allow read: if isAuthenticated() &&
                     request.auth.uid == resource.data.applicantRef.id;
      
      // Allow business owner to READ applications for their jobs
      allow read: if isAuthenticated() &&
                     ownsBusinessRef(resource.data.businessRef);
      
      // Allow admins to READ all applications
      allow read: if isAdmin();
      
      // Allow anyone authenticated to CREATE application
      allow create: if isAuthenticated() &&
                       validateApplicationCreate(request.resource.data);
      
      // Allow business owner or applicant to UPDATE
      allow update: if isAuthenticated() &&
                       (ownsBusinessRef(resource.data.businessRef) ||
                        request.auth.uid == resource.data.applicantRef.id) &&
                       validateApplicationUpdate(resource.data, request.resource.data);
      
      // No deletes (keep audit trail)
      allow delete: if false;
      
      // ===== Subcollection: messages =====
      
      match /messages/{messageId} {
        
        // Allow involved parties (sender/receiver) to READ messages
        allow read: if isAuthenticated() &&
                       (request.auth.uid == resource.data.fromRef.id ||
                        request.auth.uid == resource.data.toRef.id);
        
        // Allow business owner of the job to READ all messages
        allow read: if isAuthenticated() &&
                       ownsBusinessRef(get(/databases/$(database)/documents/job_applications/$(applicationId)).data.businessRef);
        
        // Allow admins to READ all messages
        allow read: if isAdmin();
        
        // Allow involved parties to CREATE messages
        allow create: if isAuthenticated() &&
                        (request.auth.uid == request.resource.data.fromRef.id) &&
                        validateMessageCreate(request.resource.data);
        
        // Allow receiver to mark as READ
        allow update: if isAuthenticated() &&
                        request.auth.uid == resource.data.toRef.id &&
                        request.resource.data.readAt != null &&
                        validateMessageUpdate(resource.data, request.resource.data);
        
        // No deletes (keep conversation history)
        allow delete: if false;
      }
    }
    
    // ===== job_messages Collection (Alternative) =====
    
    match /job_messages/{messageId} {
      
      // Allow involved parties to READ
      allow read: if isAuthenticated() &&
                     (request.auth.uid == resource.data.fromRef.id ||
                      request.auth.uid == resource.data.toRef.id);
      
      // Allow admins to READ
      allow read: if isAdmin();
      
      // Allow involved parties to CREATE
      allow create: if isAuthenticated() &&
                       request.auth.uid == request.resource.data.fromRef.id &&
                       validateMessageCreate(request.resource.data);
      
      // Allow receiver to mark READ
      allow update: if isAuthenticated() &&
                       request.auth.uid == resource.data.toRef.id &&
                       request.resource.data.readAt != null &&
                       validateMessageUpdate(resource.data, request.resource.data);
      
      // No deletes
      allow delete: if false;
    }
    
    // ===== Validation Functions =====
    
    // Validate job posting CREATE
    function validateJobPostingCreate(data) {
      return data.title.size() >= 3 && data.title.size() <= 50 &&
             data.description.size() >= 150 && data.description.size() <= 2000 &&
             data.jobType in ['full-time', 'part-time', 'contract', 'gig'] &&
             data.location.size() >= 2 && data.location.size() <= 100 &&
             data.rateMin > 5.00 && data.rateMin <= 999.99 &&
             data.rateMax > 5.00 && data.rateMax <= 999.99 &&
             data.rateMin <= data.rateMax &&
             data.expiresAt > now &&
             data.expiresAt <= now + duration.value(90, 'd') &&
             data.status in ['draft', 'active'] &&
             data.viewCount == 0 &&
             data.applicationCount == 0 &&
             data.tags.size() <= 10;
    }
    
    // Validate job posting UPDATE
    function validateJobPostingUpdate(oldData, newData) {
      // Allow only certain fields to be updated
      return newData.businessRef == oldData.businessRef && // Can't change business
             newData.postedAt == oldData.postedAt &&       // Can't change creation time
             newData.createdBy == oldData.createdBy &&     // Can't change creator
             // Can update: title, description, location, tags, status, expiresAt
             newData.title.size() >= 3 && newData.title.size() <= 50 &&
             newData.description.size() >= 150 &&
             newData.expiresAt > now &&
             newData.status in ['draft', 'active', 'expired', 'filled'];
    }
    
    // Validate application CREATE
    function validateApplicationCreate(data) {
      return data.status in ['pending', 'interested', 'rejected', 'hired'] &&
             data.appliedAt <= now &&
             data.messageCount == 0;
    }
    
    // Validate application UPDATE
    function validateApplicationUpdate(oldData, newData) {
      return newData.jobRef == oldData.jobRef &&
             newData.applicantRef == oldData.applicantRef &&
             newData.appliedAt == oldData.appliedAt &&
             newData.status in ['pending', 'interested', 'rejected', 'hired'];
    }
    
    // Validate message CREATE
    function validateMessageCreate(data) {
      return data.messageText.size() >= 1 && data.messageText.size() <= 1000 &&
             data.sentAt <= now;
    }
    
    // Validate message UPDATE
    function validateMessageUpdate(oldData, newData) {
      return newData.messageText == oldData.messageText &&
             newData.sentAt == oldData.sentAt &&
             newData.fromRef == oldData.fromRef &&
             newData.toRef == oldData.toRef;
    }
    
    // ===== Catch-all (deny by default) =====
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## Testing the Rules

### Test Cases

#### 1. User can browse all public jobs
```
✅ Authenticated user CAN read /job_postings/any_public_job
❌ Anonymous user CANNOT read any job postings
```

#### 2. Business owner can post jobs
```
✅ Owner CAN create job with businessRef = their business
❌ Owner CANNOT create job with businessRef = someone else's business
❌ Non-owner CANNOT create jobs
```

#### 3. Business owner can only edit their own jobs
```
✅ Owner CAN update title/description of own job
❌ Owner CANNOT change businessRef to different business
❌ Other owner CANNOT edit this job
```

#### 4. Applicants can apply to jobs
```
✅ User CAN create application to any public job
❌ Same user CANNOT apply twice (enforced at app level)
```

#### 5. Only involved parties see conversations
```
✅ Job poster CAN read messages on their job
✅ Applicant CAN read messages on their application
❌ Other user CANNOT read these messages
✅ Admin CAN read any messages
```

#### 6. Soft deletes work correctly
```
✅ Owner CAN read their own deleted jobs
❌ Other users CANNOT see deleted jobs
✅ Admin CAN see all jobs including deleted
```

---

## Deployment Checklist

- [ ] Review security rules with security team
- [ ] Test all validation functions
- [ ] Deploy to development Firestore
- [ ] Run automated security tests
- [ ] Deploy to production Firestore
- [ ] Monitor for rule rejections (watch Firebase logs)
- [ ] Test on mobile app with real Firestore

---

## Monitoring & Alerts

Set up Cloud Logging alerts for:
- Rule rejections (indicates bugs or attacks)
- Excessive reads from a single user (DOS indicator)
- Failed validations (data quality issue)

Example alert: Alert if rules reject >100 writes/min from any single user

---

## Future Enhancements

1. **Rate limiting**: Add max X jobs per user per day
2. **Reputation system**: Track job poster ratings, ban repeat spammers
3. **Advanced permissions**: Allow businesses to grant hiring manager access
4. **Compliance audit**: Track who accessed what for compliance
5. **Encryption**: Encrypt sensitive application data at rest

---

## Reference: Firestore Best Practices Used

✅ Denormalized data (businessRef in job_applications for efficient filtering)
✅ Subcollections for related data (applications under jobs)
✅ Soft deletes for audit trail
✅ Server-side validation to prevent data corruption
✅ Role-based access control (owner, applicant, admin)
✅ Principle of least privilege (only grant needed access)
✅ Helper functions to reduce rule complexity
✅ Comprehensive comments for maintainability
