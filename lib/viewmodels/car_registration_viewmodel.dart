import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

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
    final plateError = validatePlateNumber();
    if (plateError != null) return plateError;

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

  // Image Handling
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  List<XFile> get selectedImages => _selectedImages;

  Future<bool> _ensureGalleryPermission() async {
    // iOS is handled by image_picker, Android needs explicit request.
    var status = await Permission.photos.request();
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    if (!status.isGranted) {
      errorMessage = 'Photo permission is required to pick images.';
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<bool> _ensureCameraPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      errorMessage = 'Camera permission is required to take photos.';
      notifyListeners();
      return false;
    }
    return true;
  }

  /// Pick multiple images from gallery.
  Future<void> pickImages() async {
    if (_selectedImages.length >= 5) {
      errorMessage = 'You can only upload up to 5 images';
      notifyListeners();
      return;
    }

    try {
      if (!await _ensureGalleryPermission()) return;
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 70,
        maxWidth: 1024,
      );

      if (images.isNotEmpty) {
        final availableSlots = 5 - _selectedImages.length;
        if (images.length > availableSlots) {
          _selectedImages.addAll(images.take(availableSlots));
          errorMessage =
              'Only the first $availableSlots images were added to respect the limit of 5.';
        } else {
          _selectedImages.addAll(images);
          errorMessage = null;
        }
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Failed to pick images: $e';
      notifyListeners();
    }
  }

  /// Take a single photo with camera.
  Future<void> takePhoto() async {
    if (_selectedImages.length >= 5) {
      errorMessage = 'You can only upload up to 5 images';
      notifyListeners();
      return;
    }

    try {
      if (!await _ensureCameraPermission()) return;
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1024,
      );

      if (image != null) {
        _selectedImages.add(image);
        errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Failed to take photo: $e';
      notifyListeners();
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      _selectedImages.removeAt(index);
      notifyListeners();
    }
  }

  Future<List<String>> _uploadImages(String uid) async {
    List<String> downloadUrls = [];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < _selectedImages.length; i++) {
      try {
        final file = File(_selectedImages[i].path);
        // Create a unique path for each image
        final ref = FirebaseStorage.instance
            .ref()
            .child('car_images')
            .child(uid)
            .child('$timestamp')
            .child('image_$i.jpg');

        final uploadTask = await ref.putFile(file);
        final url = await uploadTask.ref.getDownloadURL();
        downloadUrls.add(url);
      } catch (e) {
        debugPrint('Error uploading image $i: $e');
        // Continue uploading other images even if one fails
      }
    }
    return downloadUrls;
  }

  Future<void> saveCarData({
    required VoidCallback onSuccess,
    required Function(String) onError,
    void Function(Map<String, dynamic> carData)? onAlreadyRegisteredByOther,
    VoidCallback? onAlreadyRegisteredBySelf,
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
      final plate = plateNumberController.text.trim();
      final make = selectedMake!;
      final model = selectedModel!;
      final year = selectedYear!;
      final color = selectedColor!;

      final existingCar = await _carService.searchCarByPlateNumber(plate);

      if (existingCar != null &&
          _carMatchesAllParams(existingCar, make, model, year, color)) {
        final ownerId = existingCar['ownerId'] as String?;
        isLoading = false;
        notifyListeners();
        if (ownerId != null && ownerId != currentUser.uid) {
          onAlreadyRegisteredByOther?.call(existingCar);
          return;
        }
        onAlreadyRegisteredBySelf?.call();
        return;
      }

      // Check car count to determine status
      final carCount = await _carService.getCarCount(currentUser.uid);
      lastRegistrationStatus = carCount >= 2 ? 'pending' : 'approved';

      // Upload Images
      final imageUrls = await _uploadImages(currentUser.uid);

      await _carService.saveCarData(
        uid: currentUser.uid,
        plateNumber: plate,
        make: make,
        model: model,
        year: year,
        color: color,
        imageUrls: imageUrls,
      );

      isLoading = false;
      errorMessage = null;
      resetForm();
      notifyListeners();
      onSuccess();
    } catch (e) {
      isLoading = false;
      final errorMsg = e.toString();
      if (errorMsg.contains('already registered')) {
        notifyListeners();
        onAlreadyRegisteredBySelf?.call();
        return;
      }
      errorMessage = 'Failed to save car data. Please try again.';
      notifyListeners();
      onError(errorMessage!);
    }
  }

  /// Returns true if existing car has same make, model, year, color (plate already matched by search).
  bool _carMatchesAllParams(
    Map<String, dynamic> existingCar,
    String make,
    String model,
    String year,
    String color,
  ) {
    final existingMake = (existingCar['make'] as String? ?? '').trim();
    final existingModel = (existingCar['model'] as String? ?? '').trim();
    final existingYear = (existingCar['year']?.toString() ?? '').trim();
    final existingColor = (existingCar['color'] as String? ?? '').trim();
    return existingMake.toLowerCase() == make.trim().toLowerCase() &&
        existingModel.toLowerCase() == model.trim().toLowerCase() &&
        existingYear == year.trim() &&
        existingColor.toLowerCase() == color.trim().toLowerCase();
  }

  void resetForm() {
    plateNumberController.clear();
    selectedMake = null;
    selectedModel = null;
    selectedYear = null;
    selectedColor = null;
    _selectedImages = [];
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
