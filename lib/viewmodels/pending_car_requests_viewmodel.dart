import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/admin_service.dart';

class PendingCarRequest {
  final String userId;
  final String userName;
  final String userPhone;
  final String carId;
  final String plateNumber;
  final String make;
  final String model;
  final String year;
  final String color;
  final String status;
  final DateTime? createdAt;
  final List<String> imageUrls;

  PendingCarRequest({
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.carId,
    required this.plateNumber,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.status,
    this.createdAt,
    this.imageUrls = const [],
  });

  String get carName => '$make $model';

  String get formattedDate {
    if (createdAt == null) return 'Unknown date';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = createdAt!.day.toString().padLeft(2, '0');
    final month = months[createdAt!.month - 1];
    final year = createdAt!.year.toString();
    return '$day $month $year';
  }

  factory PendingCarRequest.fromMap(Map<String, dynamic> map) {
    Timestamp? timestamp = map['createdAt'] as Timestamp?;
    return PendingCarRequest(
      userId: map['userId'] as String,
      userName: map['userName'] as String? ?? 'Unknown',
      userPhone: map['userPhone'] as String? ?? '',
      carId: map['carId'] as String,
      plateNumber: map['plateNumber'] as String? ?? '',
      make: map['make'] as String? ?? '',
      model: map['model'] as String? ?? '',
      year: map['year'] as String? ?? '',
      color: map['color'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: timestamp?.toDate(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
    );
  }
}

class PendingCarRequestsViewModel extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  bool isLoading = false;
  String? errorMessage;
  List<PendingCarRequest> pendingRequests = [];

  /// Load all pending car requests
  Future<void> loadPendingRequests() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final requests = await _adminService.getPendingCarRequests();
      pendingRequests =
          requests.map((map) => PendingCarRequest.fromMap(map)).toList();
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load pending requests. Please try again.';
      pendingRequests = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh pending requests
  Future<void> refresh() async {
    await loadPendingRequests();
  }

  /// Approve a car request
  Future<bool> approveRequest({
    required String userId,
    required String carId,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _adminService.approveCarRequest(userId: userId, carId: carId);

      // Remove the approved request from the list
      pendingRequests.removeWhere(
        (request) => request.userId == userId && request.carId == carId,
      );

      isLoading = false;
      errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = 'Failed to approve request. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Reject a car request
  Future<bool> rejectRequest({
    required String userId,
    required String carId,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _adminService.rejectCarRequest(userId: userId, carId: carId);

      // Remove the rejected request from the list
      pendingRequests.removeWhere(
        (request) => request.userId == userId && request.carId == carId,
      );

      isLoading = false;
      errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = 'Failed to reject request. Please try again.';
      notifyListeners();
      return false;
    }
  }
}
