import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:flutter/material.dart';

/// Service for Job Board operations
class JobBoardService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // ===== Job Posting Operations =====

  /// Create a new job posting
  static Future<String> createJobPosting({
    required String businessRef,
    required String title,
    required String description,
    required String jobType,
    required String location,
    required double rateMin,
    required double rateMax,
    required List<String> tags,
    required DateTime expiresAt,
  }) async {
    try {
      final docRef = await _firestore.collection('job_postings').add({
        'businessRef': _firestore.collection('businesses').doc(businessRef),
        'title': title,
        'description': description,
        'jobType': jobType,
        'location': location,
        'rateMin': rateMin,
        'rateMax': rateMax,
        'tags': tags,
        'postedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'status': 'active',
        'isDraft': false,
        'viewCount': 0,
        'applicationCount': 0,
        'createdBy': _firestore.collection('users').doc('CURRENT_USER'),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating job posting: $e');
      rethrow;
    }
  }

  /// Get active jobs for a business
  static Stream<List<Map<String, dynamic>>> getBusinessJobs(
    String businessRef,
  ) {
    return _firestore
        .collection('job_postings')
        .where('businessRef',
            isEqualTo: _firestore.collection('businesses').doc(businessRef))
        .where('status', isEqualTo: 'active')
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    });
  }

  /// Get all active jobs (for browsing/searching)
  static Stream<List<Map<String, dynamic>>> getAllActiveJobs() {
    return _firestore
        .collection('job_postings')
        .where('status', isEqualTo: 'active')
        .where('deletedAt', isEqualTo: null)
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    });
  }

  /// Get jobs by type and location
  static Stream<List<Map<String, dynamic>>> getJobsByFilter({
    String? jobType,
    String? location,
  }) {
    var query = _firestore
        .collection('job_postings')
        .where('status', isEqualTo: 'active')
        .where('deletedAt', isEqualTo: null);

    if (jobType != null) {
      query = query.where('jobType', isEqualTo: jobType);
    }

    if (location != null) {
      query = query.where('location', isEqualTo: location);
    }

    return query.orderBy('postedAt', descending: true).snapshots().map(
        (snapshot) {
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    });
  }

  /// Get single job details
  static Future<Map<String, dynamic>?> getJobDetails(String jobId) async {
    try {
      final doc = await _firestore.collection('job_postings').doc(jobId).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }
      return null;
    } catch (e) {
      debugPrint('Error getting job details: $e');
      return null;
    }
  }

  /// Track job view (increments view count)
  static Future<void> trackJobView(String jobId) async {
    try {
      await _functions.httpsCallable('trackJobView').call({'jobId': jobId});
    } catch (e) {
      debugPrint('Error tracking job view: $e');
    }
  }

  /// Update job status
  static Future<void> updateJobStatus(String jobId, String status) async {
    try {
      await _firestore.collection('job_postings').doc(jobId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating job status: $e');
      rethrow;
    }
  }

  /// Delete job (soft delete)
  static Future<void> deleteJob(String jobId) async {
    try {
      await _firestore.collection('job_postings').doc(jobId).update({
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error deleting job: $e');
      rethrow;
    }
  }

  // ===== Application Operations =====

  /// Apply to a job
  static Future<String> applyToJob({
    required String jobId,
    required String applicantId,
    required String businessId,
  }) async {
    try {
      final docRef = await _firestore.collection('job_applications').add({
        'jobRef': _firestore.collection('job_postings').doc(jobId),
        'applicantRef': _firestore.collection('users').doc(applicantId),
        'businessRef': _firestore.collection('businesses').doc(businessId),
        'appliedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'messageCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error applying to job: $e');
      rethrow;
    }
  }

  /// Get applications for a job (for business owner)
  static Stream<List<Map<String, dynamic>>> getJobApplications(String jobId) {
    return _firestore
        .collection('job_applications')
        .where('jobRef',
            isEqualTo: _firestore.collection('job_postings').doc(jobId))
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    });
  }

  /// Get user's applications (for job seeker)
  static Stream<List<Map<String, dynamic>>> getUserApplications(
    String userId,
  ) {
    return _firestore
        .collection('job_applications')
        .where('applicantRef',
            isEqualTo: _firestore.collection('users').doc(userId))
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    });
  }

  /// Update application status
  static Future<void> updateApplicationStatus(
    String applicationId,
    String status,
  ) async {
    try {
      await _firestore
          .collection('job_applications')
          .doc(applicationId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating application status: $e');
      rethrow;
    }
  }

  // ===== Messaging Operations =====

  /// Send message in a job application conversation
  static Future<void> sendMessage({
    required String applicationId,
    required String fromUserId,
    required String toUserId,
    required String messageText,
  }) async {
    try {
      await _firestore
          .collection('job_applications')
          .doc(applicationId)
          .collection('messages')
          .add({
        'fromRef': _firestore.collection('users').doc(fromUserId),
        'toRef': _firestore.collection('users').doc(toUserId),
        'messageText': messageText,
        'sentAt': FieldValue.serverTimestamp(),
        'readAt': null,
      });

      // Increment message count
      await _firestore
          .collection('job_applications')
          .doc(applicationId)
          .update({
        'messageCount': FieldValue.increment(1),
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  /// Get conversation messages
  static Stream<List<Map<String, dynamic>>> getApplicationMessages(
    String applicationId,
  ) {
    return _firestore
        .collection('job_applications')
        .doc(applicationId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    });
  }

  /// Mark message as read
  static Future<void> markMessageAsRead(
    String applicationId,
    String messageId,
  ) async {
    try {
      await _firestore
          .collection('job_applications')
          .doc(applicationId)
          .collection('messages')
          .doc(messageId)
          .update({
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  // ===== Metrics Operations =====

  /// Get job board metrics (for admin dashboard)
  static Future<Map<String, dynamic>?> getJobBoardMetrics() async {
    try {
      final doc =
          await _firestore.collection('admin_metrics').doc('job_board').get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting job board metrics: $e');
      return null;
    }
  }

  /// Stream job board metrics for live updates
  static Stream<Map<String, dynamic>?> streamJobBoardMetrics() {
    return _firestore
        .collection('admin_metrics')
        .doc('job_board')
        .snapshots()
        .map((doc) => doc.data());
  }
}
