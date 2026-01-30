import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../services/admin_service.dart';

class UserCar {
  final String carId;
  final String plateNumber;
  final String make;
  final String model;
  final String year;
  final String color;
  final String status;
  final DateTime? createdAt;

  UserCar({
    required this.carId,
    required this.plateNumber,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.status,
    this.createdAt,
  });

  String get carName => '$make $model';

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success; // Green
      case 'pending':
        return AppColors.warning; // Amber/Orange
      case 'rejected':
        return AppColors.error; // Red
      default:
        return Colors.grey;
    }
  }

  factory UserCar.fromMap(Map<String, dynamic> map) {
    Timestamp? timestamp = map['createdAt'] as Timestamp?;
    return UserCar(
      carId: map['carId'] as String,
      plateNumber: map['plateNumber'] as String? ?? '',
      make: map['make'] as String? ?? '',
      model: map['model'] as String? ?? '',
      year: map['year'] as String? ?? '',
      color: map['color'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: timestamp?.toDate(),
    );
  }
}

class UserDetail {
  final String userId;
  final String name;
  final String phone;
  final String photoUrl;
  final int carsCount;
  final List<UserCar> cars;
  final DateTime? createdAt;

  UserDetail({
    required this.userId,
    required this.name,
    required this.phone,
    required this.photoUrl,
    required this.carsCount,
    required this.cars,
    this.createdAt,
  });

  factory UserDetail.fromMap(Map<String, dynamic> map) {
    final carsList = map['cars'] as List<dynamic>? ?? [];
    final cars = carsList.map((car) => UserCar.fromMap(car as Map<String, dynamic>)).toList();
    
    Timestamp? timestamp = map['createdAt'] as Timestamp?;
    return UserDetail(
      userId: map['userId'] as String,
      name: map['name'] as String? ?? 'Unknown',
      phone: map['phone'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      carsCount: map['carsCount'] as int? ?? 0,
      cars: cars,
      createdAt: timestamp?.toDate(),
    );
  }
}

class UserDetailViewModel extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  bool isLoading = false;
  String? errorMessage;
  UserDetail? userDetail;

  /// Load user details
  Future<void> loadUserDetails(String userId) async {
    if (userId.isEmpty) {
      errorMessage = 'Invalid user ID';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final userData = await _adminService.getUserDetails(userId);
      
      if (userData == null) {
        errorMessage = 'User not found';
        userDetail = null;
      } else {
        userDetail = UserDetail.fromMap(userData);
        errorMessage = null;
      }
    } catch (e) {
      errorMessage = 'Failed to load user details. Please try again.';
      userDetail = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh user details
  Future<void> refresh(String userId) async {
    await loadUserDetails(userId);
  }
}

