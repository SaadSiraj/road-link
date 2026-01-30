import 'package:flutter/material.dart';

import '../services/admin_service.dart';

class AdminDashboardViewModel extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  bool isLoading = false;
  String? errorMessage;

  // Dashboard statistics
  int totalUsers = 0;
  int totalCars = 0;
  int pendingRequests = 0;
  int approvedCars = 0;
  int rejectedCars = 0;

  /// Load all dashboard statistics
  Future<void> loadDashboardStats() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final stats = await _adminService.getDashboardStats();
      
      totalUsers = stats['totalUsers'] ?? 0;
      totalCars = stats['totalCars'] ?? 0;
      pendingRequests = stats['pendingRequests'] ?? 0;
      approvedCars = stats['approvedCars'] ?? 0;
      rejectedCars = stats['rejectedCars'] ?? 0;

      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load dashboard data. Please try again.';
      // Reset to 0 on error
      totalUsers = 0;
      totalCars = 0;
      pendingRequests = 0;
      approvedCars = 0;
      rejectedCars = 0;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh dashboard data
  Future<void> refresh() async {
    await loadDashboardStats();
  }
}

