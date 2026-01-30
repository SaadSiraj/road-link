import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../services/admin_service.dart';

class CarListItem {
  final String userId;
  final String userName;
  final String carId;
  final String plateNumber;
  final String make;
  final String model;
  final String year;
  final String color;
  final String status;
  final DateTime? createdAt;

  CarListItem({
    required this.userId,
    required this.userName,
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

  factory CarListItem.fromMap(Map<String, dynamic> map) {
    Timestamp? timestamp = map['createdAt'] as Timestamp?;
    return CarListItem(
      userId: map['userId'] as String,
      userName: map['userName'] as String? ?? 'Unknown',
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

class CarsListViewModel extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  bool isLoading = false;
  String? errorMessage;
  List<CarListItem> allCars = [];
  String selectedFilter = 'All';

  List<CarListItem> get filteredCars {
    if (selectedFilter == 'All') {
      return allCars;
    }
    
    final filterStatus = selectedFilter.toLowerCase();
    return allCars.where((car) => car.status.toLowerCase() == filterStatus).toList();
  }

  /// Load all cars
  Future<void> loadCars() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final carsData = await _adminService.getAllCars();
      allCars = carsData.map((map) => CarListItem.fromMap(map)).toList();
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load cars. Please try again.';
      allCars = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Set filter
  void setFilter(String filter) {
    selectedFilter = filter;
    notifyListeners();
  }

  /// Refresh cars list
  Future<void> refresh() async {
    await loadCars();
  }
}

