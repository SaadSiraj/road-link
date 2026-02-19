import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/admin_service.dart';

class UserListItem {
  final String userId;
  final String name;
  final String phone;
  final String photoUrl;
  final int carsCount;
  final DateTime? createdAt;

  UserListItem({
    required this.userId,
    required this.name,
    required this.phone,
    required this.photoUrl,
    required this.carsCount,
    this.createdAt,
  });

  factory UserListItem.fromMap(Map<String, dynamic> map) {
    Timestamp? timestamp = map['createdAt'] as Timestamp?;
    return UserListItem(
      userId: map['userId'] as String,
      name: map['name'] as String? ?? 'Unknown',
      phone: map['phone'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      carsCount: map['carsCount'] as int? ?? 0,
      createdAt: timestamp?.toDate(),
    );
  }
}

class UsersListViewModel extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  bool isLoading = false;
  String? errorMessage;
  List<UserListItem> users = [];

  /// Load all users
  Future<void> loadUsers() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final usersData = await _adminService.getAllUsers();
      users = usersData.map((map) => UserListItem.fromMap(map)).toList();
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load users. Please try again.';
      users = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh users list
  Future<void> refresh() async {
    await loadUsers();
  }

  /// Delete a user
  Future<bool> deleteUser(String userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _adminService.deleteUser(userId);

      // Remove user from local list
      users.removeWhere((user) => user.userId == userId);

      isLoading = false;
      errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = 'Failed to delete user. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Update a user
  Future<bool> updateUser({
    required String userId,
    required String name,
    required String phone,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _adminService.updateUser(
        userId: userId,
        data: {'name': name, 'phone': phone},
      );

      // Update user in local list
      final index = users.indexWhere((user) => user.userId == userId);
      if (index != -1) {
        final oldUser = users[index];
        users[index] = UserListItem(
          userId: oldUser.userId,
          name: name,
          phone: phone,
          photoUrl: oldUser.photoUrl,
          carsCount: oldUser.carsCount,
          createdAt: oldUser.createdAt,
        );
      }

      isLoading = false;
      errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = 'Failed to update user. Please try again.';
      notifyListeners();
      return false;
    }
  }
}
