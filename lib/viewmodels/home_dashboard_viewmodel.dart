import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/car_service.dart';
import '../services/chat_service.dart';
import '../services/dashboard_service.dart';

/// Result of plate search for UX messaging.
enum PlateSearchStatus { notFound, ownCar, success, error }

class PlateSearchResult {
  final PlateSearchStatus status;
  final Map<String, dynamic>? carData;
  final String? message;

  const PlateSearchResult._({required this.status, this.carData, this.message});
  factory PlateSearchResult.notFound(String plate) =>
      PlateSearchResult._(status: PlateSearchStatus.notFound, message: 'Car with plate "$plate" not found');
  factory PlateSearchResult.ownCar(Map<String, dynamic> carData) =>
      PlateSearchResult._(status: PlateSearchStatus.ownCar, carData: carData);
  factory PlateSearchResult.success(Map<String, dynamic> carData) =>
      PlateSearchResult._(status: PlateSearchStatus.success, carData: carData);
  factory PlateSearchResult.error(String msg) =>
      PlateSearchResult._(status: PlateSearchStatus.error, message: msg);
}

/// Result of starting a chat: navigation args for chat detail.
class StartChatResult {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;

  const StartChatResult({
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
  });
}

class HomeDashboardViewModel extends ChangeNotifier {
  final DashboardService _dashboardService = DashboardService();
  final CarService _carService = CarService();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _scansCount = 0;
  int _chatsCount = 0;
  int _selectedCarIndex = 0;
  List<Map<String, dynamic>> _approvedCars = [];
  bool _isSearchingPlate = false;
  bool _isStartingChat = false;
  bool _isManualEntry = false;

  int get scansCount => _scansCount;
  int get chatsCount => _chatsCount;
  int get selectedCarIndex => _selectedCarIndex;
  List<Map<String, dynamic>> get approvedCars => _approvedCars;
  bool get isSearchingPlate => _isSearchingPlate;
  bool get isStartingChat => _isStartingChat;
  bool get isManualEntry => _isManualEntry;

  void setManualEntry(bool value) {
    if (_isManualEntry != value) {
      _isManualEntry = value;
      notifyListeners();
    }
  }

  /// Time-based greeting (e.g. "Good morning").
  String get greeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    return 'Good night';
  }
  
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

  /// Log that user tapped "Register Car" (analytics).
  void logCarRegistrationTap() {
    final uid = currentUserId;
    if (uid != null) _carService.logCarRegistrationButtonTap(uid);
  }

  /// Search for a car by plate number. Returns result for UX (notFound, ownCar, success, error).
  /// Sets [isSearchingPlate] during the request.
  Future<PlateSearchResult> searchCarByPlate(String plate) async {
    final trimmed = plate.trim().toUpperCase();
    if (trimmed.isEmpty) return PlateSearchResult.error('Please enter a plate number');

    _isSearchingPlate = true;
    notifyListeners();

    try {
      final carData = await _carService.searchCarByPlateNumber(trimmed);
      _isSearchingPlate = false;
      notifyListeners();

      final uid = currentUserId;
      if (uid != null) {
        await _dashboardService.incrementScansCount(uid);
        await _loadCounts(uid);
      }

      if (carData == null) return PlateSearchResult.notFound(trimmed);

      final ownerId = carData['ownerId'] as String?;
      if (ownerId == _chatService.currentUserId) return PlateSearchResult.ownCar(carData);

      return PlateSearchResult.success(carData);
    } catch (e) {
      _isSearchingPlate = false;
      notifyListeners();
      return PlateSearchResult.error('Error searching: ${e.toString()}');
    }
  }

  /// Start or get conversation with [ownerId]. If [carData] is provided, sends car
  /// details as the first message. Returns nav args on success.
  Future<StartChatResult?> startChat(String ownerId, {Map<String, dynamic>? carData}) async {
    if (ownerId.isEmpty || ownerId == currentUserId) return null;

    _isStartingChat = true;
    notifyListeners();

    try {
      final conversation = await _chatService.getOrCreateConversation(otherUserId: ownerId);
      final profile = await _chatService.getUserProfile(ownerId);

      if (conversation == null) {
        _isStartingChat = false;
        notifyListeners();
        return null;
      }

      if (carData != null && carData.isNotEmpty) {
        final firstMessage = _formatCarInfoAsMessage(carData);
        await _chatService.sendMessage(
          conversationId: conversation.id,
          text: firstMessage,
        );
      }

      _isStartingChat = false;
      notifyListeners();

      return StartChatResult(
        conversationId: conversation.id,
        otherUserId: ownerId,
        otherUserName: profile['name'] ?? 'Car Owner',
        otherUserPhotoUrl: profile['photoUrl'],
      );
    } catch (_) {
      _isStartingChat = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Format car data as a short message for the first chat message.
  static String _formatCarInfoAsMessage(Map<String, dynamic> car) {
    final plate = (car['plateNumber'] ?? 'N/A').toString().toUpperCase();
    final make = car['make'] ?? 'Unknown';
    final model = car['model'] ?? 'Unknown';
    final year = car['year']?.toString() ?? 'N/A';
    final color = car['color'] ?? 'Unknown';
    return '🚗 I found your car: $plate — $make $model ($year, $color)';
  }
}

