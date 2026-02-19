import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:roadlink/core/utils/size_utils.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/shared/app_text.dart';
import 'plate_capture_view.dart';

/// Custom 2:1 aspect ratio preset for license plates.
class _PlateAspectRatioPreset implements CropAspectRatioPresetData {
  @override
  (int, int)? get data => (2, 1);

  @override
  String get name => '2:1 (plate)';
}

/// Preview the captured plate image: view, crop, then Search (OCR + return plate).
class PlatePreviewView extends StatefulWidget {
  final File imageFile;

  const PlatePreviewView({super.key, required this.imageFile});

  @override
  State<PlatePreviewView> createState() => _PlatePreviewViewState();
}

class _PlatePreviewViewState extends State<PlatePreviewView> {
  File? _currentFile;
  bool _isSearching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentFile = widget.imageFile;
  }

  Future<void> _cropImage() async {
    if (_currentFile == null || !_currentFile!.existsSync()) return;
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: _currentFile!.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop image',
            toolbarColor: AppColors.scaffoldBackground,
            toolbarWidgetColor: AppColors.textPrimary,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            showCropGrid: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio5x3,
              CropAspectRatioPreset.ratio5x4,
              CropAspectRatioPreset.ratio7x5,
              CropAspectRatioPreset.ratio16x9,  
              _PlateAspectRatioPreset(), // 2:1 plate
            ],
          ),
          IOSUiSettings(
            title: 'Crop image',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
              _PlateAspectRatioPreset(),
            ],
          ),
        ],
      );
      if (cropped != null && mounted) {
        setState(() {
          _currentFile = File(cropped.path);
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Crop failed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Crop failed: ${e.toString().split('\n').first}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _searchPlate() async {
    if (_currentFile == null || !_currentFile!.existsSync() || _isSearching) return;
    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final plate = await _runOcrAndValidate(_currentFile!);
      if (!mounted) return;
      if (plate != null && plate.isNotEmpty) {
        Navigator.of(context).pop(plate);
      } else {
        setState(() {
          _isSearching = false;
          _error = 'Could not read plate. Try cropping or retake.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not read plate from image. Try cropping the plate area.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _error = 'Could not read plate';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString().split('\n').first}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<String?> _runOcrAndValidate(File imageFile) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final processedFile = await PlateImagePreprocess.preprocess(imageFile);
      final inputImage = InputImage.fromFile(processedFile);
      final recognizedText = await textRecognizer.processImage(inputImage);
      textRecognizer.close();
      final plate = PlateUtils.extractPlateFromRecognizedText(recognizedText);
      if (plate != null && plate.length >= 3) return plate;
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.close, color: AppColors.textPrimary, size: 24.fSize),
        ),
        title: AppText(
          'Plate preview',
          size: 18.fSize,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _currentFile != null && _currentFile!.existsSync()
                ? _buildImagePreview()
                : _buildPlaceholder(),
          ),
          if (_error != null) _buildErrorBanner(),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.file(
            _currentFile!,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _buildPlaceholder(),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_not_supported, size: 64.adaptSize, color: AppColors.textTertiary),
          Gap.v(16),
          AppText('No image', size: 16.fSize, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 12.v),
      color: AppColors.error.withOpacity(0.15),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22.fSize),
          Gap.h(12),
          Expanded(
            child: AppText(_error!, size: 14.fSize, color: AppColors.error),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: EdgeInsets.fromLTRB(24.h, 20.v, 24.h, 24.v + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isSearching ? null : _cropImage,
              icon: Icon(Icons.crop, size: 20.fSize, color: AppColors.primaryBlue),
              label: AppText('Crop', size: 16.fSize, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: BorderSide(color: AppColors.primaryBlue),
                padding: EdgeInsets.symmetric(vertical: 14.v),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.adaptSize)),
              ),
            ),
          ),
          Gap.h(16),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _isSearching ? null : _searchPlate,
              icon: _isSearching
                  ? SizedBox(
                      width: 20.adaptSize,
                      height: 20.adaptSize,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(Icons.search, size: 20.fSize, color: Colors.white),
              label: AppText(
                _isSearching ? 'Reading...' : 'Search',
                size: 16.fSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: EdgeInsets.symmetric(vertical: 14.v),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.adaptSize)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
