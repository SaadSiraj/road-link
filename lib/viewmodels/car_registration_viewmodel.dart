import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/car_service.dart';

class CarRegistrationViewModel extends ChangeNotifier {
  final CarService _carService = CarService();
  final TextEditingController plateNumberController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;
  String? selectedMake;
  String? selectedModel;
  String? selectedYear;
  String? selectedColor;
  String? lastRegistrationStatus; // 'pending' or 'approved'

  void setMake(String? make) {
    selectedMake = make;
    // Reset model when make changes
    selectedModel = null;
    notifyListeners();
  }

  void setModel(String? model) {
    selectedModel = model;
    notifyListeners();
  }

  void setYear(String? year) {
    selectedYear = year;
    notifyListeners();
  }

  void setColor(String? color) {
    selectedColor = color;
    notifyListeners();
  }

  bool get isFormValid {
    return plateNumberController.text.trim().isNotEmpty &&
        selectedMake != null &&
        selectedMake!.isNotEmpty &&
        selectedModel != null &&
        selectedModel!.isNotEmpty &&
        selectedYear != null &&
        selectedYear!.isNotEmpty &&
        selectedColor != null &&
        selectedColor!.isNotEmpty;
  }

  String? validateForm() {
    final plateNumber = plateNumberController.text.trim();
    
    // Plate number validation
    if (plateNumber.isEmpty) {
      return 'Plate number is required';
    }
    
    if (plateNumber.length < 3) {
      return 'Plate number must be at least 3 characters';
    }
    
    if (plateNumber.length > 20) {
      return 'Plate number must not exceed 20 characters';
    }
    
    // Make validation
    if (selectedMake == null || selectedMake!.isEmpty) {
      return 'Car make is required';
    }
    
    // Model validation
    if (selectedModel == null || selectedModel!.isEmpty) {
      return 'Car model is required';
    }
    
    // Year validation
    if (selectedYear == null || selectedYear!.isEmpty) {
      return 'Car year is required';
    }
    
    // Color validation
    if (selectedColor == null || selectedColor!.isEmpty) {
      return 'Car color is required';
    }

    return null;
  }

  String? validatePlateNumber([String? value]) {
    final plateNumber = value?.trim() ?? plateNumberController.text.trim();
    
    if (plateNumber.isEmpty) {
      return 'Plate number is required';
    }
    
    if (plateNumber.length < 3) {
      return 'Plate number must be at least 3 characters';
    }
    
    if (plateNumber.length > 20) {
      return 'Plate number must not exceed 20 characters';
    }
    
    // Check for invalid characters (only alphanumeric and spaces/hyphens allowed)
    if (!RegExp(r'^[A-Za-z0-9\s-]+$').hasMatch(plateNumber)) {
      return 'Plate number can only contain letters, numbers, spaces, and hyphens';
    }
    
    return null;
  }

  Future<void> saveCarData({
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    final validationError = validateForm();
    if (validationError != null) {
      onError(validationError);
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      onError('User is not signed in');
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Check car count to determine if this will be pending
      final carCount = await _carService.getCarCount(currentUser.uid);
      final willBePending = carCount >= 2;
      lastRegistrationStatus = willBePending ? 'pending' : 'approved';

      await _carService.saveCarData(
        uid: currentUser.uid,
        plateNumber: plateNumberController.text.trim(),
        make: selectedMake!,
        model: selectedModel!,
        year: selectedYear!,
        color: selectedColor!,
      );

      isLoading = false;
      errorMessage = null;
      // Reset form after successful save
      resetForm();
      notifyListeners();
      
      onSuccess();
    } catch (e) {
      isLoading = false;
      final errorMsg = e.toString();
      
      // Extract clean error message
      if (errorMsg.contains('already registered')) {
        errorMessage = 'This plate number is already registered.';
      } else {
        errorMessage = 'Failed to save car data. Please try again.';
      }
      
      notifyListeners();
      onError(errorMessage!);
    }
  }

  void resetForm() {
    plateNumberController.clear();
    selectedMake = null;
    selectedModel = null;
    selectedYear = null;
    selectedColor = null;
    errorMessage = null;
    isLoading = false;
    lastRegistrationStatus = null;
  }

  @override
  void dispose() {
    plateNumberController.dispose();
    super.dispose();
  }
}

