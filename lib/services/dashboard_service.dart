import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get user data stream
  Stream<DocumentSnapshot<Map<String, dynamic>>>? getUserStream(String? uid) {
    if (uid == null) return null;
    try {
      return _firestore.collection('users').doc(uid).snapshots();
    } catch (e) {
      _logEvent(event: 'get_user_stream_error', detail: e.toString());
      return null;
    }
  }

  /// Get user profile photo URL
  String? getUserPhotoUrl(DocumentSnapshot<Map<String, dynamic>>? userDoc) {
    if (userDoc == null || !userDoc.exists) {
      // Fallback to Firebase Auth photoURL
      return _auth.currentUser?.photoURL;
    }

    final photoUrl = userDoc.data()?['photoUrl'] as String?;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return photoUrl;
    }

    // Fallback to Firebase Auth photoURL
    return _auth.currentUser?.photoURL;
  }

  /// Get user name
  String getUserName(
    DocumentSnapshot<Map<String, dynamic>>? userDoc,
    String fallbackName,
  ) {
    if (userDoc == null || !userDoc.exists) {
      return fallbackName;
    }

    final nameFromDb = userDoc.data()?['name'] as String?;
    return (nameFromDb?.trim().isNotEmpty ?? false)
        ? nameFromDb!.trim()
        : fallbackName;
  }

  /// Get approved cars stream
  Stream<QuerySnapshot<Map<String, dynamic>>>? getApprovedCarsStream(String? uid) {
    if (uid == null) return null;
    try {
      return _firestore
          .collection('users')
          .doc(uid)
          .collection('cars')
          .where('status', isEqualTo: 'approved')
          .snapshots();
    } catch (e) {
      _logEvent(event: 'get_approved_cars_stream_error', detail: e.toString());
      return null;
    }
  }

  /// Get all approved cars as list
  List<Map<String, dynamic>> getAllApprovedCars(
      QuerySnapshot<Map<String, dynamic>>? carsSnapshot) {
    if (carsSnapshot == null || carsSnapshot.docs.isEmpty) {
      return [];
    }

    return carsSnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Get car info string from car data
  String formatCarInfo(Map<String, dynamic> carData) {
    final make = carData['make'] as String? ?? '';
    final model = carData['model'] as String? ?? '';
    final plateNumber = carData['plateNumber'] as String? ?? '';

    if (make.isNotEmpty && model.isNotEmpty) {
      return plateNumber.isNotEmpty
          ? '$make $model | $plateNumber'
          : '$make $model';
    }

    return plateNumber.isNotEmpty ? plateNumber : 'No car registered';
  }

  /// Get first approved car info (for backward compatibility)
  String getCarInfo(QuerySnapshot<Map<String, dynamic>>? carsSnapshot) {
    final cars = getAllApprovedCars(carsSnapshot);
    if (cars.isEmpty) {
      return 'No car registered';
    }
    return formatCarInfo(cars.first);
  }

  /// Get scans count (placeholder for future implementation)
  Future<int> getScansCount(String uid) async {
    try {
      // TODO: Implement scans count logic when scans collection is available
      // For now, return 0
      return 0;
    } catch (e) {
      _logEvent(event: 'get_scans_count_error', detail: e.toString());
      return 0;
    }
  }

  /// Get chats count (placeholder for future implementation)
  Future<int> getChatsCount(String uid) async {
    try {
      // TODO: Implement chats count logic when chats collection is available
      // For now, return 0
      return 0;
    } catch (e) {
      _logEvent(event: 'get_chats_count_error', detail: e.toString());
      return 0;
    }
  }

  void _logEvent({
    required String event,
    String? detail,
  }) {
    developer.log(
      'DashboardService $event${detail != null ? ': $detail' : ''}',
      name: 'DashboardService',
    );
  }
}

