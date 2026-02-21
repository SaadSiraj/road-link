import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:roadlink/core/utils/size_utils.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/shared/app_text.dart';
import 'plate_capture_view.dart';

/// Preview: captured image, extracted plate, Rescan / Next. Next shows confirm dialog then returns plate.
class PlatePreviewView extends StatefulWidget {
  final File imageFile;
  /// If set, this plate was already extracted from the scan box in the capture screen.
  final String? preExtractedPlate;

  const PlatePreviewView({
    super.key,
    required this.imageFile,
    this.preExtractedPlate,
  });

  @override
  State<PlatePreviewView> createState() => _PlatePreviewViewState();
}

class _PlatePreviewViewState extends State<PlatePreviewView> {
  File? _currentFile;
  bool _isSearching = false;
  String? _error;
  /// Cleared when user crops (so we re-run OCR on Search).
  String? _preExtractedPlate;

  @override
  void initState() {
    super.initState();
    _currentFile = widget.imageFile;
    _preExtractedPlate = widget.preExtractedPlate;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.preExtractedPlate != null && widget.preExtractedPlate!.isNotEmpty) {
        _showConfirmAndSearch();
      } else {
        _runOcrThenConfirm();
      }
    });
  }

  void _showConfirmAndSearch() {
    final initialPlate = _preExtractedPlate ?? '';
    if (initialPlate.isEmpty) {
      _runOcrThenConfirm();
      return;
    }
    debugPrint('[PlatePreview] Opening confirm dialog with initial plate: $initialPlate');
    final controller = TextEditingController(text: initialPlate);
    controller.selection = TextSelection.collapsed(offset: initialPlate.length);
    final navigator = Navigator.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car, color: AppColors.primaryBlue),
            SizedBox(width: 12.h),
            Flexible(
              child: AppText('Confirm plate', size: 18.fSize, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.4),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText('Edit if needed, then search.', size: 14.fSize, color: AppColors.textSecondary),
                Gap.v(12),
                TextField(
                  controller: controller,
                  style: TextStyle(
                    fontSize: 18.fSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Plate number',
                    filled: true,
                    fillColor: AppColors.primaryBlue.withOpacity(0.12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryBlue.withOpacity(0.4)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryBlue.withOpacity(0.4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.5),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 14.v),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('[PlatePreview] Retake tapped.');
              Navigator.pop(ctx);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                controller.dispose();
                if (mounted) navigator.pop(null);
              });
            },
            child: AppText('Retake', size: 16.fSize, color: AppColors.textSecondary),
          ),
          ElevatedButton(
            onPressed: () {
              final edited = controller.text.trim();
              debugPrint('[PlatePreview] Next tapped. Plate: $edited');
              Navigator.pop(ctx);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                controller.dispose();
                if (mounted) navigator.pop(edited.isNotEmpty ? edited : null);
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
            child: AppText('Next', size: 16.fSize, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _runOcrThenConfirm() async {
    if (_currentFile == null || !_currentFile!.existsSync() || _isSearching) return;
    setState(() { _isSearching = true; _error = null; });
    try {
      final plate = await _runOcrAndValidate(_currentFile!);
      if (!mounted) return;
      setState(() { _isSearching = false; if (plate != null) _preExtractedPlate = plate; });
      if (plate != null && plate.isNotEmpty && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showConfirmAndSearch();
        });
      } else {
        setState(() => _error = 'Could not read plate.');
      }
    } catch (_) {
      if (mounted) setState(() { _isSearching = false; _error = 'Could not read plate.'; });
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
      body: SafeArea(
        child: _isSearching && _preExtractedPlate == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    Gap.v(16),
                    AppText('Reading plate…', size: 14.fSize, color: AppColors.textSecondary),
                  ],
                ),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.adaptSize),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 48.adaptSize, color: AppColors.error),
                          Gap.v(16),
                          AppText(_error!, size: 14.fSize, color: AppColors.error, align: TextAlign.center),
                          Gap.v(20),
                          TextButton.icon(
                            onPressed: () => Navigator.of(context).pop(null),
                            icon: Icon(Icons.camera_alt_outlined, size: 20.fSize, color: AppColors.primaryBlue),
                            label: AppText('Retake', size: 16.fSize, color: AppColors.primaryBlue),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
      ),
    );
  }
}
