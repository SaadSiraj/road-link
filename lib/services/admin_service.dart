import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get total number of users (excluding admins)
  Future<int> getTotalUsers() async {
    try {
      // Get all users first, then filter out admins
      // This handles cases where isAdmin field might not exist
      final snapshot = await _firestore.collection('users').get();
      
      int userCount = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Count as user if isAdmin is false or doesn't exist (defaults to false)
        final isAdmin = data['isAdmin'] as bool? ?? false;
        if (!isAdmin) {
          userCount++;
        }
      }
      
      return userCount;
    } catch (e) {
      _logEvent(
        event: 'get_total_users_error',
        detail: e.toString(),
      );
      return 0;
    }
  }

  /// Get total number of cars across all users
  Future<int> getTotalCars() async {
    try {
      int totalCars = 0;
      final usersSnapshot = await _firestore.collection('users').get();
      
      for (var userDoc in usersSnapshot.docs) {
        final carsSnapshot = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('cars')
            .get();
        totalCars += carsSnapshot.docs.length;
      }
      
      return totalCars;
    } catch (e) {
      _logEvent(
        event: 'get_total_cars_error',
        detail: e.toString(),
      );
      return 0;
    }
  }

  /// Get number of pending car requests
  Future<int> getPendingRequests() async {
    try {
      int pendingCount = 0;
      final usersSnapshot = await _firestore.collection('users').get();
      
      for (var userDoc in usersSnapshot.docs) {
        final carsSnapshot = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('cars')
            .where('status', isEqualTo: 'pending')
            .get();
        pendingCount += carsSnapshot.docs.length;
      }
      
      return pendingCount;
    } catch (e) {
      _logEvent(
        event: 'get_pending_requests_error',
        detail: e.toString(),
      );
      return 0;
    }
  }

  /// Get number of approved cars
  Future<int> getApprovedCars() async {
    try {
      int approvedCount = 0;
      final usersSnapshot = await _firestore.collection('users').get();
      
      for (var userDoc in usersSnapshot.docs) {
        final carsSnapshot = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('cars')
            .where('status', isEqualTo: 'approved')
            .get();
        approvedCount += carsSnapshot.docs.length;
      }
      
      return approvedCount;
    } catch (e) {
      _logEvent(
        event: 'get_approved_cars_error',
        detail: e.toString(),
      );
      return 0;
    }
  }

  /// Get number of rejected cars
  Future<int> getRejectedCars() async {
    try {
      int rejectedCount = 0;
      final usersSnapshot = await _firestore.collection('users').get();
      
      for (var userDoc in usersSnapshot.docs) {
        final carsSnapshot = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('cars')
            .where('status', isEqualTo: 'rejected')
            .get();
        rejectedCount += carsSnapshot.docs.length;
      }
      
      return rejectedCount;
    } catch (e) {
      _logEvent(
        event: 'get_rejected_cars_error',
        detail: e.toString(),
      );
      return 0;
    }
  }

  /// Get all pending car requests with user information
  Future<List<Map<String, dynamic>>> getPendingCarRequests() async {
    try {
      final List<Map<String, dynamic>> pendingRequests = [];
      final usersSnapshot = await _firestore.collection('users').get();
      
      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final isAdmin = userData['isAdmin'] as bool? ?? false;
        
        // Skip admin users
        if (isAdmin) continue;
        
        final carsSnapshot = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('cars')
            .where('status', isEqualTo: 'pending')
            .get();
        
        for (var carDoc in carsSnapshot.docs) {
          final carData = carDoc.data();
          pendingRequests.add({
            'userId': userDoc.id,
            'userName': userData['name'] ?? 'Unknown',
            'userPhone': userData['phone'] ?? '',
            'carId': carDoc.id,
            'plateNumber': carData['plateNumber'] ?? '',
            'make': carData['make'] ?? '',
            'model': carData['model'] ?? '',
            'year': carData['year'] ?? '',
            'color': carData['color'] ?? '',
            'status': carData['status'] ?? 'pending',
            'createdAt': carData['createdAt'],
          });
        }
      }
      
      // Sort by createdAt (most recent first)
      pendingRequests.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      
      return pendingRequests;
    } catch (e) {
      _logEvent(
        event: 'get_pending_car_requests_error',
        detail: e.toString(),
      );
      return [];
    }
  }

  /// Get user details with all their cars
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        return null;
      }
      
      final userData = userDoc.data()!;
      
      // Get all cars for this user
      final carsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cars')
          .get();
      
      final cars = carsSnapshot.docs.map((doc) {
        final carData = doc.data();
        return {
          'carId': doc.id,
          'plateNumber': carData['plateNumber'] ?? '',
          'make': carData['make'] ?? '',
          'model': carData['model'] ?? '',
          'year': carData['year'] ?? '',
          'color': carData['color'] ?? '',
          'status': carData['status'] ?? 'pending',
          'createdAt': carData['createdAt'],
        };
      }).toList();
      
      // Sort cars by createdAt (most recent first)
      cars.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      
      return {
        'userId': userId,
        'name': userData['name'] ?? 'Unknown',
        'phone': userData['phone'] ?? '',
        'photoUrl': userData['photoUrl'] ?? '',
        'cars': cars,
        'carsCount': cars.length,
        'createdAt': userData['createdAt'],
      };
    } catch (e) {
      _logEvent(
        event: 'get_user_details_error',
        detail: e.toString(),
      );
      return null;
    }
  }

  /// Get all cars from all users with owner information
  Future<List<Map<String, dynamic>>> getAllCars() async {
    try {
      final List<Map<String, dynamic>> allCars = [];
      final usersSnapshot = await _firestore.collection('users').get();
      
      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final isAdmin = userData['isAdmin'] as bool? ?? false;
        
        // Skip admin users
        if (isAdmin) continue;
        
        final userName = userData['name'] ?? 'Unknown';
        
        // Get all cars for this user
        final carsSnapshot = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('cars')
            .get();
        
        for (var carDoc in carsSnapshot.docs) {
          final carData = carDoc.data();
          allCars.add({
            'userId': userDoc.id,
            'userName': userName,
            'carId': carDoc.id,
            'plateNumber': carData['plateNumber'] ?? '',
            'make': carData['make'] ?? '',
            'model': carData['model'] ?? '',
            'year': carData['year'] ?? '',
            'color': carData['color'] ?? '',
            'status': carData['status'] ?? 'pending',
            'createdAt': carData['createdAt'],
          });
        }
      }
      
      // Sort by createdAt (most recent first)
      allCars.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      
      return allCars;
    } catch (e) {
      _logEvent(
        event: 'get_all_cars_error',
        detail: e.toString(),
      );
      return [];
    }
  }

  /// Get all users with their car counts (excluding admins)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final List<Map<String, dynamic>> users = [];
      final usersSnapshot = await _firestore.collection('users').get();
      
      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final isAdmin = userData['isAdmin'] as bool? ?? false;
        
        // Skip admin users
        if (isAdmin) continue;
        
        // Get car count for this user
        final carsSnapshot = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('cars')
            .get();
        
        users.add({
          'userId': userDoc.id,
          'name': userData['name'] ?? 'Unknown',
          'phone': userData['phone'] ?? '',
          'photoUrl': userData['photoUrl'] ?? '',
          'carsCount': carsSnapshot.docs.length,
          'createdAt': userData['createdAt'],
        });
      }
      
      // Sort by name alphabetically
      users.sort((a, b) {
        final aName = (a['name'] as String? ?? '').toLowerCase();
        final bName = (b['name'] as String? ?? '').toLowerCase();
        return aName.compareTo(bName);
      });
      
      return users;
    } catch (e) {
      _logEvent(
        event: 'get_all_users_error',
        detail: e.toString(),
      );
      return [];
    }
  }

  /// Get all dashboard statistics in one call
  Future<Map<String, int>> getDashboardStats() async {
    try {
      final stats = await Future.wait([
        getTotalUsers(),
        getTotalCars(),
        getPendingRequests(),
        getApprovedCars(),
        getRejectedCars(),
      ]);

      return {
        'totalUsers': stats[0],
        'totalCars': stats[1],
        'pendingRequests': stats[2],
        'approvedCars': stats[3],
        'rejectedCars': stats[4],
      };
    } catch (e) {
      _logEvent(
        event: 'get_dashboard_stats_error',
        detail: e.toString(),
      );
      return {
        'totalUsers': 0,
        'totalCars': 0,
        'pendingRequests': 0,
        'approvedCars': 0,
        'rejectedCars': 0,
      };
    }
  }

  /// Approve a car request
  Future<void> approveCarRequest({
    required String userId,
    required String carId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cars')
          .doc(carId)
          .update({'status': 'approved'});
      
      _logEvent(
        event: 'car_request_approved',
        detail: 'User: $userId, Car: $carId',
      );
    } catch (e) {
      _logEvent(
        event: 'approve_car_request_error',
        detail: e.toString(),
      );
      rethrow;
    }
  }

  /// Reject a car request
  Future<void> rejectCarRequest({
    required String userId,
    required String carId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cars')
          .doc(carId)
          .update({'status': 'rejected'});
      
      _logEvent(
        event: 'car_request_rejected',
        detail: 'User: $userId, Car: $carId',
      );
    } catch (e) {
      _logEvent(
        event: 'reject_car_request_error',
        detail: e.toString(),
      );
      rethrow;
    }
  }

  void _logEvent({
    required String event,
    String? detail,
  }) {
    developer.log(
      'AdminService $event${detail != null ? ': $detail' : ''}',
      name: 'AdminService',
    );
  }
}

