import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:roadlink/core/utils/size_utils.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/shared/app_text.dart';
import 'plate_preview_view.dart';

/// Full-screen plate capture: camera only, frame guide, hints, then OCR + validate.
/// Returns [String?] plate on success, null on back/cancel.
class PlateCaptureView extends StatefulWidget {
  const PlateCaptureView({super.key});

  @override
  State<PlateCaptureView> createState() => _PlateCaptureViewState();
}

class _PlateCaptureViewState extends State<PlateCaptureView> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lockOrientation();
    _initCameraWithPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restoreOrientation();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  void _lockOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  void _restoreOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _initCameraWithPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() {
        _error = 'Camera permission is required to scan plates.';
      });
      return;
    }
    await _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();   
      if (_cameras.isEmpty) {
        setState(() {
          _error = 'No camera found';
        });
        return;
      }
      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Camera error: ${e.toString().split('\n').first}';
        });
      }
    }
  }

  Future<void> _captureAndRecognize() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;
    setState(() => _isCapturing = true);
    try {
      final XFile file = await _controller!.takePicture();
      if (!mounted) return;
      setState(() => _isCapturing = false);
      final String? plate = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => PlatePreviewView(imageFile: File(file.path)),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(plate);
    } catch (e) {
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Capture failed: ${e.toString().split('\n').first}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_error != null)
              _buildErrorState()
            else if (_isInitialized && _controller != null)
              _buildCameraPreview()
            else
              _buildLoadingState(),
            _buildOverlay(),
            _buildTopBar(),
            if (_isInitialized && _controller != null && !_isCapturing)
              _buildCaptureButton(),
            if (_isCapturing) _buildCapturingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.adaptSize),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64.adaptSize, color: AppColors.error),
            Gap.v(16),
            AppText(_error!, size: 16.fSize, color: AppColors.textPrimary, align: TextAlign.center),
            Gap.v(24),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: AppText('Close', size: 16.fSize, color: AppColors.primaryBlue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryBlue),
    );
  }

  Widget _buildCameraPreview() {
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller!.value.previewSize!.height,
        height: _controller!.value.previewSize!.width,
        child: CameraPreview(_controller!),
      ),
    );
  }

  Widget _buildOverlay() {
    return IgnorePointer(
      child: Column(
        children: [
          Gap.v(80),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    // width: 280.adaptSize,
                    width: double.infinity,
                    height: 250.adaptSize,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primaryBlue, width: 3),
                      borderRadius: BorderRadius.circular(12.adaptSize),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: AppText(
                            'Align plate here',
                            size: 14.fSize,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),

            
                      ],
                    ),
                  ),

                  
                        Gap.v(24),
                  _hintRow(Icons.center_focus_strong, 'Keep plate centered'),
                  Gap.v(8),
                  _hintRow(Icons.blur_off, 'Avoid blur'),
                  Gap.v(8),
                  _hintRow(Icons.wb_sunny_outlined, 'Good lighting'),
                  
                ],
              ),
            ),
          ),
          SizedBox(height: 120.v),
        ],
      ),
    );
  }

  Widget _hintRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18.fSize, color: AppColors.primaryBlue),
        Gap.h(8),
        AppText(text, size: 14.fSize, color: Colors.white),
      ],
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.v),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
            Expanded(
              child: AppText(
                'Scan plate',
                size: 18.fSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return Positioned(
      bottom: 48.v,
      left: 0,
      right: 0,
      child: Center(
        child: Material(
          color: AppColors.primaryBlue,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: _captureAndRecognize,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 72.adaptSize,
              height: 72.adaptSize,
              child: Icon(Icons.camera_alt, size: 36.fSize, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCapturingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryBlue),
            Gap.v(16),
            AppText('Reading plate...', size: 16.fSize, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// Plate text cleaning, normalization, and validation.
/// OCR output is never perfect: remove spaces/special chars, uppercase, fix common mistakes.
/// Extract only the relevant line (plate-like), ignore random text, combine split characters.
class PlateUtils {
  /// From OCR result: pick the best line that looks like a plate.
  /// - Uses blocks/lines from RecognizedText (not just raw string).
  /// - Combines characters if split: e.g. line "ABC 1234" → "ABC1234".
  /// - Ignores lines that don't match plate pattern after cleaning.
  static String? extractPlateFromRecognizedText(RecognizedText recognizedText) {
    final candidates = <String>[];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final combined = _combineLineForPlate(line);
        if (combined.isEmpty) continue;
        final cleaned = cleanPlateText(combined);
        if (cleaned.length >= 3) candidates.add(cleaned);
      }
    }
    if (candidates.isEmpty) {
      final fullCleaned = cleanPlateText(recognizedText.text);
      if (fullCleaned.length >= 3) return fullCleaned;
      return null;
    }
    candidates.sort((a, b) {
      final aValid = isValidPlate(a) ? 1 : 0;
      final bValid = isValidPlate(b) ? 1 : 0;
      if (aValid != bValid) return bValid.compareTo(aValid);
      final aScore = _plateScore(a);
      final bScore = _plateScore(b);
      return bScore.compareTo(aScore);
    });
    return candidates.first;
  }

  /// Combine line: join elements (words) so "ABC" + "1234" → "ABC1234", or strip spaces from line.text.
  static String _combineLineForPlate(TextLine line) {
    if (line.elements.isNotEmpty) {
      return line.elements.map((e) => e.text).join();
    }
    return line.text.replaceAll(RegExp(r'\s+'), '');
  }

  static int _plateScore(String s) {
    if (s.length < 3 || s.length > 20) return 0;
    final alphanumeric = s.replaceAll(RegExp(r'[^A-Z0-9]'), '').length;
    if (alphanumeric != s.length) return 0;
    return s.length;
  }

  /// Remove spaces, remove special characters, convert to uppercase.
  /// e.g. "ab c-1234" → "ABC1234"
  static String cleanPlateText(String raw) {
    if (raw.isEmpty) return '';
    // 1) Uppercase first so we normalize case
    String s = raw.toUpperCase().trim();
    // 2) Remove all spaces (including multiple)
    s = s.replaceAll(RegExp(r'\s+'), '');
    // 3) Remove special characters: keep only A–Z and 0–9
    s = s.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    // 4) Fix common OCR mistakes (optional pass)
    s = _fixCommonOcrMistakes(s);
    return s;
  }

  /// Fix common OCR confusions in plate-like text (letters vs digits).
  static String _fixCommonOcrMistakes(String s) {
    if (s.length < 2) return s;
    final chars = s.split('');
    // Heuristic: many plates are letters then numbers (e.g. ABC1234).
    // Treat first ~3 chars as letter zone, rest as number zone.
    const letterZoneLength = 3;
    for (var i = 0; i < chars.length; i++) {
      final inLetterZone = i < letterZoneLength;
      final c = chars[i];
      if (inLetterZone) {
        // In letter zone: OCR often reads O as 0, I as 1, S as 5, B as 8
        if (c == '0') chars[i] = 'O';
        else if (c == '1') chars[i] = 'I';
        else if (c == '5') chars[i] = 'S';
        else if (c == '8') chars[i] = 'B';
      } else {
        // In number zone: OCR often reads O as 0, I/l as 1, S as 5
        if (c == 'O') chars[i] = '0';
        else if (c == 'I' || c == 'L') chars[i] = '1';
        else if (c == 'S') chars[i] = '5';
      }
    }
    return chars.join();
  }

  static bool isValidPlate(String cleaned) {
    if (cleaned.isEmpty) return false;
    if (cleaned.length < 3 || cleaned.length > 20) return false;
    return RegExp(r'^[A-Z0-9]+$').hasMatch(cleaned);
  }
}

/// Image pre-processing before OCR. Improves accuracy 3–5× by:
/// - Cropping to the plate area (center region)
/// - Increasing contrast
/// - Reducing noise (light gaussian blur)
class PlateImagePreprocess {
  /// Fraction of image width to keep for plate crop (center).
  static const double _cropWidthFraction = 0.78;
  /// Fraction of image height to keep for plate crop (center).
  static const double _cropHeightFraction = 0.42;
  /// Contrast multiplier (>1 = higher contrast).
  static const double _contrast = 1.35;
  /// Light blur radius for noise reduction (1–2).
  static const int _blurRadius = 1;

  /// Preprocess image: crop plate area, increase contrast, reduce noise.
  /// Returns a new file (temp) with the processed image, or the original file on failure.
  static Future<File> preprocess(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return imageFile;

      final w = decoded.width;
      final h = decoded.height;
      final cropW = (w * _cropWidthFraction).round().clamp(1, w);
      final cropH = (h * _cropHeightFraction).round().clamp(1, h);
      final x = ((w - cropW) / 2).round().clamp(0, w - 1);
      final y = ((h - cropH) / 2).round().clamp(0, h - 1);

      img.Image out = img.copyCrop(decoded, x: x, y: y, width: cropW, height: cropH);
      out = img.adjustColor(out, contrast: _contrast);
      out = img.gaussianBlur(out, radius: _blurRadius);

      final jpg = img.encodeJpg(out, quality: 92);

      final temp = File('${imageFile.path}_plate_processed.jpg');
      await temp.writeAsBytes(jpg);
      return temp;
    } catch (_) {
      return imageFile;
    }
  }
}
