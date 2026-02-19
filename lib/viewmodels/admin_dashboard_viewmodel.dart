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

  // Filter
  String selectedFilter = 'All Time';
  final List<String> filters = ['Today', 'This Week', 'This Month', 'All Time'];

  /// Set filter and reload data
  void setFilter(String filter) {
    if (selectedFilter != filter) {
      selectedFilter = filter;
      loadDashboardStats();
    }
  }

  /// Load all dashboard statistics
  Future<void> loadDashboardStats() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      DateTime? startDate;
      final now = DateTime.now();

      switch (selectedFilter) {
        case 'Today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'This Week':
          // Start of the week (Monday)
          startDate = DateTime(
            now.year,
            now.month,
            now.day - (now.weekday - 1),
          );
          break;
        case 'This Month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'All Time':
        default:
          startDate = null;
          break;
      }

      final stats = await _adminService.getDashboardStats(startDate: startDate);

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
