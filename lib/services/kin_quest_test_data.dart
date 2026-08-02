import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/backend.dart';

/// Test data helper for KIN Quest gamification feature
/// Use this to populate test businesses and discoveries for demo/testing
class KinQuestTestData {
  static final _firestore = FirebaseFirestore.instance;

  /// Add sample Black-owned businesses for testing the discovery map
  /// Call this once to populate test data
  static Future<void> addSampleBusinesses() async {
    try {
      final batch = _firestore.batch();

      // Sample businesses in San Antonio area with various categories
      final sampleBusinesses = [
        {
          'businessName': 'Soul Food Kitchen',
          'description': 'Authentic soul food restaurant',
          'category': 'Restaurant',
          'isBlackOwned': true,
          'businessLocation': const GeoPoint(29.4241, -98.4936), // Alamo area
          'address': '100 Alamo Plaza, San Antonio, TX',
          'phone': '(210) 555-0001',
        },
        {
          'businessName': 'Rhythm & Blues Lounge',
          'description': 'Live music venue and bar',
          'category': 'Entertainment',
          'isBlackOwned': true,
          'businessLocation': const GeoPoint(29.4265, -98.4888), // River Walk
          'address': '123 River Walk, San Antonio, TX',
          'phone': '(210) 555-0002',
        },
        {
          'businessName': 'Crown Beauty Salon',
          'description': 'Full-service beauty and hair salon',
          'category': 'Beauty',
          'isBlackOwned': true,
          'businessLocation': const GeoPoint(29.4180, -98.4950), // Southtown
          'address': '456 South Alamo, San Antonio, TX',
          'phone': '(210) 555-0003',
        },
        {
          'businessName': 'Heritage Coffee Co',
          'description': 'Specialty coffee roaster and café',
          'category': 'Café',
          'isBlackOwned': true,
          'businessLocation': const GeoPoint(29.4210, -98.4920), // Downtown
          'address': '789 Commerce St, San Antonio, TX',
          'phone': '(210) 555-0004',
        },
        {
          'businessName': 'Unity Fitness Studio',
          'description': 'Full fitness and wellness center',
          'category': 'Fitness',
          'isBlackOwned': true,
          'businessLocation': const GeoPoint(29.4310, -98.4870), // Pearl District
          'address': '321 Pearl Parkway, San Antonio, TX',
          'phone': '(210) 555-0005',
        },
        {
          'businessName': 'Afrobeat Catering',
          'description': 'African fusion catering services',
          'category': 'Catering',
          'isBlackOwned': true,
          'businessLocation': const GeoPoint(29.4100, -98.5000), // East Side
          'address': '555 East Houston, San Antonio, TX',
          'phone': '(210) 555-0006',
        },
        {
          'businessName': "Queen's Bakery",
          'description': 'Fresh baked goods and pastries',
          'category': 'Bakery',
          'isBlackOwned': true,
          'businessLocation': const GeoPoint(29.4350, -98.4850), // North Star
          'address': '111 North Star Mall, San Antonio, TX',
          'phone': '(210) 555-0007',
        },
        {
          'businessName': 'Black Excellence Bookstore',
          'description': 'Independent bookstore and reading community space',
          'category': 'Retail',
          'isBlackOwned': true,
          'businessLocation': const GeoPoint(29.4240, -98.4910), // Downtown
          'address': '222 Main Plaza, San Antonio, TX',
          'phone': '(210) 555-0008',
        },
        {
          'businessName': 'Ancestor Herbs & Wellness',
          'description': 'Natural wellness and herbal medicine shop',
          'category': 'Health & Wellness',
          'isBlackOwned': true,
          'businessLocation': const GeoPoint(29.4150, -98.4980), // Southtown
          'address': '333 South Flores, San Antonio, TX',
          'phone': '(210) 555-0009',
        },
        {
          'businessName': 'Jazz & Java Lounge',
          'description': 'Jazz club and premium coffee bar',
          'category': 'Café',
          'isBlackOwned': true,
          'businessLocation': const GeoPoint(29.4270, -98.4900), // River Walk
          'address': '444 River North, San Antonio, TX',
          'phone': '(210) 555-0010',
        },
      ];

      int index = 0;
      for (final business in sampleBusinesses) {
        final docRef = _firestore.collection('businesses').doc('test_biz_$index');
        batch.set(docRef, {
          ...business,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        index++;
      }

      await batch.commit();
      print('✓ Added ${sampleBusinesses.length} test businesses');
    } catch (e) {
      print('Error adding test businesses: $e');
      rethrow;
    }
  }

  /// Add sample discovered businesses for a test user
  /// This simulates a user who has already discovered some businesses
  static Future<void> addSampleDiscoveries(String userId) async {
    try {
      final batch = _firestore.batch();

      // Sample discoveries (first 5 businesses)
      final discoveries = [
        {
          'businessName': 'Soul Food Kitchen',
          'category': 'Restaurant',
          'discoveredAt': FieldValue.serverTimestamp(),
          'verified': false,
          'points': 50,
        },
        {
          'businessName': 'Crown Beauty Salon',
          'category': 'Beauty',
          'discoveredAt': FieldValue.serverTimestamp(),
          'verified': false,
          'points': 50,
        },
        {
          'businessName': 'Heritage Coffee Co',
          'category': 'Café',
          'discoveredAt': FieldValue.serverTimestamp(),
          'verified': false,
          'points': 50,
        },
      ];

      int index = 0;
      for (final discovery in discoveries) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('discovered_businesses')
            .doc('test_biz_$index');
        batch.set(docRef, discovery);
        index++;
      }

      // Update user's KIN balance
      batch.update(_firestore.collection('users').doc(userId), {
        'kinBalance': FieldValue.increment(150), // 3 discoveries × 50 points
      });

      await batch.commit();
      print('✓ Added ${discoveries.length} test discoveries for user $userId');
      print('✓ Awarded 150 KIN points');
    } catch (e) {
      print('Error adding test discoveries: $e');
      rethrow;
    }
  }

  /// Clear all test data (useful for resetting between tests)
  static Future<void> clearTestData() async {
    try {
      final batch = _firestore.batch();

      // Delete test businesses
      final businessesSnapshot = await _firestore
          .collection('businesses')
          .where(FieldPath.documentId, whereIn: [
        'test_biz_0',
        'test_biz_1',
        'test_biz_2',
        'test_biz_3',
        'test_biz_4',
        'test_biz_5',
        'test_biz_6',
        'test_biz_7',
        'test_biz_8',
        'test_biz_9',
      ])
          .get();

      for (final doc in businessesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✓ Cleared test data');
    } catch (e) {
      print('Error clearing test data: $e');
      rethrow;
    }
  }

  /// Debug helper to print all test businesses
  static Future<void> printTestBusinesses() async {
    try {
      final snapshot = await _firestore
          .collection('businesses')
          .where('isBlackOwned', isEqualTo: true)
          .limit(20)
          .get();

      print('\n📍 Businesses in database:');
      for (final doc in snapshot.docs) {
        final data = doc.data();
        print('  - ${data['businessName']} (${data['category']})');
      }
      print('Total: ${snapshot.docs.length}\n');
    } catch (e) {
      print('Error printing businesses: $e');
    }
  }

  /// Debug helper to print user's discoveries
  static Future<void> printUserDiscoveries(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('discovered_businesses')
          .get();

      print('\n🎮 Discoveries for user $userId:');
      for (final doc in snapshot.docs) {
        final data = doc.data();
        print('  - ${data['businessName']} (+${data['points']} points)');
      }
      print('Total discovered: ${snapshot.docs.length}\n');
    } catch (e) {
      print('Error printing discoveries: $e');
    }
  }
}
