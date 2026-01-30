import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/shared_preferences_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _service = AuthService();
  final TextEditingController phoneController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;
  String? verificationId;
  UserModel? user;
  String phoneNumber = '';

  Future<void> checkUserAndSendOtp(
    String phone,
    VoidCallback onSuccess, {
    Function(String)? onError,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Check if user already exists
      final userExists = await _service.checkUserExists(phone);
      if (userExists) {
        isLoading = false;
        errorMessage = 'User already exists. Please login.';
        notifyListeners();
        onError?.call('User already exists. Please login.');
        return;
      }

      // If user doesn't exist, proceed with sending OTP
      await sendOtp(phone, onSuccess, onError: onError);
    } catch (e) {
      isLoading = false;
      errorMessage = 'An error occurred. Please try again.';
      notifyListeners();
      onError?.call('An error occurred. Please try again.');
    }
  }

  Future<void> signInAndSendOtp(
    String phone,
    VoidCallback onSuccess, {
    Function(String)? onError,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Check if user exists (for sign-in, user must exist)
      final userExists = await _service.checkUserExists(phone);
      if (!userExists) {
        isLoading = false;
        errorMessage = 'User does not exist. Please register first.';
        notifyListeners();
        onError?.call('User does not exist. Please register first.');
        return;
      }

      // If user exists, proceed with sending OTP
      await sendOtp(phone, onSuccess, onError: onError);
    } catch (e) {
      isLoading = false;
      errorMessage = 'An error occurred. Please try again.';
      notifyListeners();
      onError?.call('An error occurred. Please try again.');
    }
  }

  Future<void> sendOtp(
    String phone,
    VoidCallback onSuccess, {
    Function(String)? onError,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    await _service.sendOtp(
      phone: phone,
      onCodeSent: (id) {
        verificationId = id;
        isLoading = false;
        notifyListeners();
        onSuccess();
      },
      onError: (error) {
        errorMessage = error;
        isLoading = false;
        notifyListeners();
        onError?.call(error);
      },
    );
  }

  void setPhoneNumber(String phone) {
    phoneNumber = phone;
    notifyListeners();
  }

  void verifyOtp(String otp, VoidCallback onSuccess) async {
    _service.logRegistrationEvent(
      phone: phoneNumber,
      event: 'otp_verify_attempt',
    );
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await _service.verifyOtp(
        verificationId: verificationId!,
        otp: otp,
      );

      final currentUser = FirebaseAuth.instance.currentUser;
      user = UserModel(
        uid: currentUser?.uid ?? '',
        phoneNumber: phoneNumber,
        isVerified: true,
        name: currentUser?.displayName,
      );

      isLoading = false;
      notifyListeners();
      onSuccess();
    } catch (e) {
      _service.logRegistrationEvent(
        phone: phoneNumber,
        event: 'otp_verify_error',
        detail: e.toString(),
      );
      errorMessage = 'Invalid OTP';
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeProfile({
    required String fullName,
    File? profileImage,
    VoidCallback? onSuccess,
    Function(String)? onError,
  }) async {
    _service.logRegistrationEvent(
      phone: phoneNumber,
      event: 'complete_profile_attempt',
    );
    if (fullName.trim().isEmpty) {
      _service.logRegistrationEvent(
        phone: phoneNumber,
        event: 'complete_profile_validation_error',
        detail: 'full name missing',
      );
      onError?.call('Full name is required.');
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _service.logRegistrationEvent(
        phone: phoneNumber,
        event: 'complete_profile_user_missing',
      );
      onError?.call('User is not signed in.');
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // For now we only store the user's name. Profile photo upload will be added later.
      const String photoUrl = '';

      await _service.saveUserProfile(
        uid: currentUser.uid,
        phone: phoneNumber,
        fullName: fullName,
        photoUrl: photoUrl,
      );

      user = UserModel(
        uid: currentUser.uid,
        phoneNumber: phoneNumber,
        isVerified: true,
        name: fullName,
        photoUrl: photoUrl,
      );

      // Save login state to SharedPreferences (new users are not admin by default)
      await SharedPreferencesService.saveLoginState(
        isLoggedIn: true,
        isAdmin: false,
        userId: currentUser.uid,
      );

      _service.logRegistrationEvent(
        phone: phoneNumber,
        event: 'profile_completed',
      );

      onSuccess?.call();
    } catch (e) {
      errorMessage = e.toString();
      _service.logRegistrationEvent(
        phone: phoneNumber,
        event: 'complete_profile_error',
        detail: e.toString(),
      );
      onError?.call(e.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }
}
