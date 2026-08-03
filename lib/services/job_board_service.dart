import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

/// Service for Job Board operations
class JobBoardService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // ===== Job Posting Operations =====

  /// How a posting expresses pay. Every posting must carry one - KIN's
  /// promise is that every job on the board says what it pays, and the
  /// moment a "negotiable" option exists it becomes the default and the
  /// promise is gone.
  ///
  /// The type exists because a single min/max hourly pair can't describe a
  /// salaried manager, a commission stylist, or a server on base + tips.
  /// Same two numbers, relabelled by type.
  static const payTypes = <String, String>{
    'hourly': 'Hourly rate',
    'salary': 'Annual salary',
    'commission': 'Commission',
    'base_tips': 'Base + tips',
  };

  /// Where the work happens. Drives whether a street address is required -
  /// demanding one for a remote role makes no sense.
  static const workLocations = <String, String>{
    'on_site': 'On-site',
    'hybrid': 'Hybrid',
    'remote': 'Remote',
  };

  /// How a candidate reaches the business.
  ///
  /// Deliberately no resume upload anywhere in this flow. Resumes carry
  /// legal name, home address, phone and work history; storing them would
  /// put KIN on the hook for retention, deletion and breach handling for
  /// data it has no need to hold. The owner receives applications through
  /// their own channel instead.
  static const applyMethods = <String, String>{
    'in_app': 'Message in KIN',
    'email': 'Email the business',
    'website': 'Apply on their website',
  };

  /// Human-readable pay for a posting, e.g. "\$15-18/hr" or "\$45,000/yr".
  ///
  /// Shared by the browse card and the detail page so the two can't drift
  /// into describing the same posting differently.
  static String formatPay(Map<String, dynamic> job) {
    final type = job['payType'] as String? ?? 'hourly';
    final min = (job['rateMin'] as num?)?.toDouble() ?? 0;
    final max = (job['rateMax'] as num?)?.toDouble() ?? 0;
    final single = job['isSingleRate'] == true || max <= min;

    String amount(double v) => type == 'salary'
        ? '\$${v.round().toString().replaceAllMapped(
              RegExp(r'(\d)(?=(\d{3})+$)'),
              (m) => '${m[1]},',
            )}'
        : '\$${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2)}';

    final range = single ? amount(min) : '${amount(min)}-${amount(max)}';
    switch (type) {
      case 'salary':
        return '$range/yr';
      case 'commission':
        return '$range commission';
      case 'base_tips':
        return '$range/hr + tips';
      default:
        return '$range/hr';
    }
  }

  /// Create a new job posting.
  ///
  /// [address] may be empty only when [workLocation] is 'remote'; the form
  /// enforces that, and the security rules enforce the pay fields.
  static Future<String> createJobPosting({
    required String businessRef,
    required String title,
    required String description,
    required String jobType,
    required String workLocation,
    required String address,
    required String payType,
    required double rateMin,
    required double rateMax,
    required bool isSingleRate,
    required String applyMethod,
    String requirements = '',
    String applyEmail = '',
    String applyUrl = '',
    List<String> tags = const [],
    DateTime? expiresAt,
  }) async {
    try {
      final docRef = await _firestore.collection('job_postings').add({
        'businessRef': _firestore.collection('businesses').doc(businessRef),
        'title': title,
        'description': description,
        'requirements': requirements,
        'jobType': jobType,
        'workLocation': workLocation,
        // Kept as `location` rather than renamed: the browse card, the
        // detail page and the indexes all already read this field.
        'location': address,
        'payType': payType,
        'rateMin': rateMin,
        'rateMax': rateMax,
        'isSingleRate': isSingleRate,
        'applyMethod': applyMethod,
        'applyEmail': applyEmail,
        'applyUrl': applyUrl,
        'tags': tags,
        'postedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
            expiresAt ?? DateTime.now().add(const Duration(days: 30))),
        'status': 'active',
        'isDraft': false,
        'viewCount': 0,
        'applicationCount': 0,
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
  ///
  /// Deliberately does NOT filter on `deletedAt == null`: in Firestore an
  /// equality-to-null clause only matches documents where the field is
  /// present and null, and createJobPosting never writes the field, so
  /// adding it here matched zero documents and the board was always empty.
  /// `status` is the real gate - deleteJob sets it to 'deleted'.
  static Stream<List<Map<String, dynamic>>> getAllActiveJobs() {
    return _firestore
        .collection('job_postings')
        .where('status', isEqualTo: 'active')
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
  ///
  /// Also flips `status` off 'active' - the browse query filters on status,
  /// not on deletedAt (see getAllActiveJobs), so without this a "deleted"
  /// job would keep showing up on the public board.
  static Future<void> deleteJob(String jobId) async {
    try {
      await _firestore.collection('job_postings').doc(jobId).update({
        'status': 'deleted',
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
    required String applicantName,
    required String applicantEmail,
    required String applicantPhone,
    required String coverLetter,
  }) async {
    try {
      final docRef = await _firestore.collection('job_applications').add({
        'jobRef': _firestore.collection('job_postings').doc(jobId),
        'applicantRef': _firestore.collection('users').doc(applicantId),
        'businessRef': _firestore.collection('businesses').doc(businessId),
        'applicantName': applicantName,
        'applicantEmail': applicantEmail,
        'applicantPhone': applicantPhone,
        'coverLetter': coverLetter,
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
