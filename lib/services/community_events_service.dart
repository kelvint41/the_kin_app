import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Service for Community Events Board operations
class CommunityEventsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===== Event Types =====
  static const List<String> eventTypes = [
    'backpack_drive',
    'partnership',
    'volunteering',
    'workshop',
    'celebration',
    'other',
  ];

  static String eventTypeLabel(String type) {
    switch (type) {
      case 'backpack_drive':
        return '🎒 Backpack Drive';
      case 'partnership':
        return '🤝 Partnership';
      case 'volunteering':
        return '🙋 Volunteering';
      case 'workshop':
        return '📚 Workshop';
      case 'celebration':
        return '🎉 Celebration';
      default:
        return '📅 Event';
    }
  }

  // ===== Event Posting =====

  /// Create a new community event
  static Future<String> createEvent({
    required String businessRef,
    required String title,
    required String description,
    required String eventType,
    required String location,
    required DateTime eventDate,
    required GeoPoint? businessLocation,
    List<String> tags = const [],
  }) async {
    try {
      final docRef = await _firestore.collection('community_events').add({
        'businessRef': _firestore.collection('businesses').doc(businessRef),
        'title': title,
        'description': description,
        'eventType': eventType,
        'location': location,
        'eventDate': Timestamp.fromDate(eventDate),
        'businessLocation': businessLocation,
        'tags': tags,
        'status': 'draft',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'attendeeCount': 0,
        'partnerCount': 0,
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating event: $e');
      rethrow;
    }
  }

  /// Publish an event (make it visible to others)
  static Future<void> publishEvent(String eventId) async {
    try {
      await _firestore.collection('community_events').doc(eventId).update({
        'status': 'published',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error publishing event: $e');
      rethrow;
    }
  }

  /// Cancel an event
  static Future<void> cancelEvent(String eventId) async {
    try {
      await _firestore.collection('community_events').doc(eventId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error cancelling event: $e');
      rethrow;
    }
  }

  // ===== Event Discovery =====

  /// Get all published events (for browsing)
  static Stream<List<Map<String, dynamic>>> getAllPublishedEvents() {
    return _firestore
        .collection('community_events')
        .where('status', isEqualTo: 'published')
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    });
  }

  /// Get events by type
  static Stream<List<Map<String, dynamic>>> getEventsByType(String eventType) {
    return _firestore
        .collection('community_events')
        .where('status', isEqualTo: 'published')
        .where('eventType', isEqualTo: eventType)
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    });
  }

  /// Get upcoming events (for calendar)
  static Stream<List<Map<String, dynamic>>> getUpcomingEvents(
    {int days = 30}
  ) {
    final now = Timestamp.now();
    final futureDate = Timestamp.fromDate(
      DateTime.now().add(Duration(days: days)),
    );

    return _firestore
        .collection('community_events')
        .where('status', isEqualTo: 'published')
        .where('eventDate', isGreaterThanOrEqualTo: now)
        .where('eventDate', isLessThanOrEqualTo: futureDate)
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    });
  }

  /// Search nearby events
  static Future<List<Map<String, dynamic>>> searchNearbyEvents({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    String? eventType,
  }) async {
    try {
      // For now, return all published events
      // Production: Use Firestore geohashing or Google Places API
      final snapshot = await _firestore
          .collection('community_events')
          .where('status', isEqualTo: 'published')
          .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('Error searching nearby events: $e');
      return [];
    }
  }

  /// Get single event details
  static Future<Map<String, dynamic>?> getEventDetails(String eventId) async {
    try {
      final doc = await _firestore
          .collection('community_events')
          .doc(eventId)
          .get();

      if (doc.exists) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }
      return null;
    } catch (e) {
      debugPrint('Error getting event details: $e');
      return null;
    }
  }

  // ===== Business Events =====

  /// Get events posted by a business
  static Stream<List<Map<String, dynamic>>> getBusinessEvents(
    String businessRef,
  ) {
    return _firestore
        .collection('community_events')
        .where('businessRef',
            isEqualTo: _firestore.collection('businesses').doc(businessRef))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    });
  }

  // ===== Event Attendance =====

  /// User attends/registers for an event
  static Future<void> registerForEvent({
    required String eventId,
    required String userId,
  }) async {
    try {
      final attendeeRef = _firestore
          .collection('community_events')
          .doc(eventId)
          .collection('attendees')
          .doc(userId);

      await attendeeRef.set({
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'attended': false,
      });

      // Increment attendee count
      await _firestore.collection('community_events').doc(eventId).update({
        'attendeeCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error registering for event: $e');
      rethrow;
    }
  }

  /// Get attendees for an event
  static Stream<List<Map<String, dynamic>>> getEventAttendees(String eventId) {
    return _firestore
        .collection('community_events')
        .doc(eventId)
        .collection('attendees')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    });
  }

  // ===== Partnership Requests =====

  /// Request partnership for an event
  static Future<String> requestPartnership({
    required String fromBusinessId,
    required String toBusinessId,
    required String eventId,
    required String message,
  }) async {
    try {
      final docRef = await _firestore
          .collection('partnership_requests')
          .add({
        'fromBusinessRef':
            _firestore.collection('businesses').doc(fromBusinessId),
        'toBusinessRef':
            _firestore.collection('businesses').doc(toBusinessId),
        'eventRef': _firestore.collection('community_events').doc(eventId),
        'message': message,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error requesting partnership: $e');
      rethrow;
    }
  }

  /// Accept partnership request
  static Future<void> acceptPartnership(String requestId) async {
    try {
      await _firestore
          .collection('partnership_requests')
          .doc(requestId)
          .update({
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error accepting partnership: $e');
      rethrow;
    }
  }

  /// Decline partnership request
  static Future<void> declinePartnership(String requestId) async {
    try {
      await _firestore
          .collection('partnership_requests')
          .doc(requestId)
          .update({
        'status': 'declined',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error declining partnership: $e');
      rethrow;
    }
  }

  /// Get pending partnership requests for a business
  static Stream<List<Map<String, dynamic>>> getPendingPartnershipRequests(
    String businessId,
  ) {
    return _firestore
        .collection('partnership_requests')
        .where('toBusinessRef',
            isEqualTo: _firestore.collection('businesses').doc(businessId))
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    });
  }

  // ===== Event Comments =====

  /// Add comment to event
  static Future<void> addComment({
    required String eventId,
    required String userId,
    required String text,
  }) async {
    try {
      await _firestore
          .collection('community_events')
          .doc(eventId)
          .collection('comments')
          .add({
        'authorId': userId,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }

  /// Get comments on event
  static Stream<List<Map<String, dynamic>>> getEventComments(String eventId) {
    return _firestore
        .collection('community_events')
        .doc(eventId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    });
  }

  // ===== Metrics =====

  /// Get community events metrics (for admin dashboard)
  static Future<Map<String, dynamic>?> getCommunityEventsMetrics() async {
    try {
      final doc = await _firestore
          .collection('admin_metrics')
          .doc('community_events')
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting metrics: $e');
      return null;
    }
  }

  /// Stream community events metrics (live updates)
  static Stream<Map<String, dynamic>?> streamCommunityEventsMetrics() {
    return _firestore
        .collection('admin_metrics')
        .doc('community_events')
        .snapshots()
        .map((doc) => doc.data());
  }
}
