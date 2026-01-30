import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/dashboard_service.dart';

class HomeDashboardViewModel extends ChangeNotifier {
  final DashboardService _dashboardService = DashboardService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _scansCount = 0;
  int _chatsCount = 0;
  int _selectedCarIndex = 0;
  List<Map<String, dynamic>> _approvedCars = [];

  int get scansCount => _scansCount;
  int get chatsCount => _chatsCount;
  int get selectedCarIndex => _selectedCarIndex;
  List<Map<String, dynamic>> get approvedCars => _approvedCars;
  
  Map<String, dynamic>? get selectedCar {
    if (_approvedCars.isEmpty || _selectedCarIndex >= _approvedCars.length) {
      return null;
    }
    return _approvedCars[_selectedCarIndex];
  }

  String get fallbackName {
    final displayName = _auth.currentUser?.displayName?.trim();
    return (displayName?.isNotEmpty ?? false) ? displayName! : 'User';
  }

  String? get currentUserId => _auth.currentUser?.uid;

  /// Get user data stream
  Stream<DocumentSnapshot<Map<String, dynamic>>>? getUserStream() {
    return _dashboardService.getUserStream(currentUserId);
  }

  /// Get approved cars stream
  Stream<QuerySnapshot<Map<String, dynamic>>>? getApprovedCarsStream() {
    return _dashboardService.getApprovedCarsStream(currentUserId);
  }

  /// Get user photo URL from user document
  String? getUserPhotoUrl(DocumentSnapshot<Map<String, dynamic>>? userDoc) {
    return _dashboardService.getUserPhotoUrl(userDoc);
  }

  /// Get user name from user document
  String getUserName(DocumentSnapshot<Map<String, dynamic>>? userDoc) {
    return _dashboardService.getUserName(userDoc, fallbackName);
  }

  /// Get car info from cars snapshot
  String getCarInfo(QuerySnapshot<Map<String, dynamic>>? carsSnapshot) {
    // Update approved cars list
    _approvedCars = _dashboardService.getAllApprovedCars(carsSnapshot);
    
    // Reset selected index if it's out of bounds
    if (_selectedCarIndex >= _approvedCars.length) {
      _selectedCarIndex = 0;
    }
    
    if (_approvedCars.isEmpty) {
      return 'No car registered';
    }
    
    return _dashboardService.formatCarInfo(_approvedCars[_selectedCarIndex]);
  }

  /// Change selected car
  void selectCar(int index) {
    if (index >= 0 && index < _approvedCars.length) {
      _selectedCarIndex = index;
      notifyListeners();
    }
  }

  /// Get formatted car info for a specific car
  String getFormattedCarInfo(Map<String, dynamic> carData) {
    return _dashboardService.formatCarInfo(carData);
  }

  /// Initialize and load counts
  Future<void> initialize() async {
    final uid = currentUserId;
    if (uid != null) {
      await _loadCounts(uid);
    }
  }

  /// Load scans and chats counts
  Future<void> _loadCounts(String uid) async {
    try {
      final scans = await _dashboardService.getScansCount(uid);
      final chats = await _dashboardService.getChatsCount(uid);
      _scansCount = scans;
      _chatsCount = chats;
      notifyListeners();
    } catch (e) {
      // Keep default values (0)
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    final uid = currentUserId;
    if (uid != null) {
      await _loadCounts(uid);
    }
  }
}

