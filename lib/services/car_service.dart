import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

class CarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int maxCars = 2;

  Future<int> getCarCount(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('cars')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      _logEvent(
        uid: uid,
        event: 'get_car_count_error',
        detail: e.toString(),
      );
      return 0;
    }
  }

  Future<void> saveCarData({
    required String uid,
    required String plateNumber,
    required String make,
    required String model,
    required String year,
    required String color,
  }) async {
    // Check current car count to determine status
    final carCount = await getCarCount(uid);
    
    // If user has 2 or more cars, new registration goes to pending status
    // If user has less than 2 cars, new registration is approved
    final status = carCount >= maxCars ? 'pending' : 'approved';

    // Check if plate number already exists
    final plateExists = await _checkPlateNumberExists(uid, plateNumber);
    if (plateExists) {
      throw Exception('This plate number is already registered');
    }

    // Create new car document in subcollection
    final carsCollection = _firestore
        .collection('users')
        .doc(uid)
        .collection('cars');

    final newCar = <String, dynamic>{
      'plateNumber': plateNumber,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Add car as a new document in the subcollection
    await carsCollection.add(newCar);

    _logEvent(
      uid: uid,
      event: 'car_data_saved',
      detail: '$make $model ($year) - Status: $status',
    );
  }

  Future<bool> _checkPlateNumberExists(String uid, String plateNumber) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('cars')
          .where('plateNumber', isEqualTo: plateNumber.toUpperCase().trim())
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      _logEvent(
        uid: uid,
        event: 'check_plate_exists_error',
        detail: e.toString(),
      );
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAllCars(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('cars')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Include document ID
        return data;
      }).toList();
    } catch (e) {
      _logEvent(
        uid: uid,
        event: 'get_all_cars_error',
        detail: e.toString(),
      );
      return [];
    }
  }

  Future<Map<String, dynamic>?> getCarData(String uid) async {
    try {
      final cars = await getAllCars(uid);
      // Return the first car for backward compatibility
      return cars.isNotEmpty ? cars.first : null;
    } catch (e) {
      _logEvent(
        uid: uid,
        event: 'car_data_fetch_error',
        detail: e.toString(),
      );
      return null;
    }
  }

  Future<void> deleteCar(String uid, String carId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('cars')
          .doc(carId)
          .delete();
      
      _logEvent(
        uid: uid,
        event: 'car_deleted',
        detail: carId,
      );
    } catch (e) {
      _logEvent(
        uid: uid,
        event: 'car_delete_error',
        detail: e.toString(),
      );
      rethrow;
    }
  }

  void logCarRegistrationButtonTap(String uid) {
    _logEvent(
      uid: uid,
      event: 'register_car_button_tapped',
      detail: 'from_home_screen',
    );
  }

  void _logEvent({
    required String uid,
    required String event,
    String? detail,
  }) {
    developer.log(
      'CarService $event for $uid${detail != null ? ': $detail' : ''}',
      name: 'CarService',
    );
  }
}

