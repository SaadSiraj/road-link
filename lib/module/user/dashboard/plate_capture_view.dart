import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

import 'plate_preview_view.dart';

// ─── Scan Status ─────────────────────────────────────────────────────────────

enum _ScanStatus { scanning, processing, detected }

// ─── Design Tokens ───────────────────────────────────────────────────────────

class _C {
  static const bg      = Color(0xFF0A0A0F);
  static const surface = Color(0xFF111118);
  static const blue    = Color(0xFF60A5FA);
  static const green   = Color(0xFF4ADE80);
  static const amber   = Color(0xFFFBBF24);
  static const white70 = Color(0xB3FFFFFF);
  static const white55 = Color(0x8CFFFFFF);
  static const white06 = Color(0x0FFFFFFF);
  static const white15 = Color(0x26FFFFFF);
}

// ─── PlateCaptureView ────────────────────────────────────────────────────────

/// Organised plate scanner:
///   • Top bar  –  back + title
///   • Camera card (~55 %) with dark overlay, scan box, corner brackets, scan line
///   • Bottom panel – status badge, 3 tips, cancel button
class PlateCaptureView extends StatefulWidget {
  const PlateCaptureView({super.key});

  @override
  State<PlateCaptureView> createState() => _PlateCaptureViewState();
}

class _PlateCaptureViewState extends State<PlateCaptureView>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // Camera
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  String? _error;
  bool _isProcessingFrame = false;
  Timer? _liveScanTimer;

  // UI
  _ScanStatus _scanStatus = _ScanStatus.scanning;

  // Border pulse: white ↔ blue
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // Scan line travels top → bottom inside box
  late final AnimationController _scanLineCtrl;
  late final Animation<double> _scanLineAnim;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lockOrientation();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseAnim =
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _scanLineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _scanLineAnim =
        CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut);

    _initCameraWithPermission();
  }

  @override
  void dispose() {
    _liveScanTimer?.cancel();
    _pulseCtrl.dispose();
    _scanLineCtrl.dispose();
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

  void _lockOrientation() => SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp]);

  void _restoreOrientation() => SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

  // ── Camera ─────────────────────────────────────────────────────────────────

  Future<void> _initCameraWithPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(
          () => _error = 'Camera permission is required to scan plates.');
      return;
    }
    await _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = 'No camera found on this device.');
        return;
      }
      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );
      _controller = CameraController(camera, ResolutionPreset.high,
          enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _error = null;
      });
      _startLiveScanning();
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = 'Camera error: ${e.toString().split('\n').first}');
      }
    }
  }

  // ── Live scan ──────────────────────────────────────────────────────────────

  void _startLiveScanning() {
    _liveScanTimer?.cancel();
    if (mounted) setState(() => _scanStatus = _ScanStatus.scanning);
    _liveScanTimer = Timer.periodic(
        const Duration(milliseconds: 2500), (_) => _runLiveScan());
  }

  Future<void> _runLiveScan() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessingFrame ||
        !mounted) return;
    _isProcessingFrame = true;
    if (mounted) setState(() => _scanStatus = _ScanStatus.processing);
    try {
      final xFile = await _controller!.takePicture();
      if (!mounted) return;
      final file = File(xFile.path);
      final plate = await _extractPlateFromImage(file);
      if (!mounted) return;
      if (plate != null &&
          plate.isNotEmpty &&
          PlateUtils.isValidPlate(plate)) {
        _liveScanTimer?.cancel();
        if (mounted) setState(() => _scanStatus = _ScanStatus.detected);
        await Future.delayed(const Duration(milliseconds: 450));
        _isProcessingFrame = false;
        _openPreviewAndPop(file, plate);
        return;
      }
      if (mounted) setState(() => _scanStatus = _ScanStatus.scanning);
    } catch (_) {
      if (mounted) setState(() => _scanStatus = _ScanStatus.scanning);
    }
    if (mounted) _isProcessingFrame = false;
  }

  Future<String?> _extractPlateFromImage(File imageFile) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final processed = await PlateImagePreprocess.preprocess(imageFile);
      final result =
          await recognizer.processImage(InputImage.fromFile(processed));
      recognizer.close();
      return PlateUtils.extractPlateFromRecognizedText(result);
    } catch (_) {
      recognizer.close();
      return null;
    }
  }

  Future<void> _openPreviewAndPop(File imageFile, String? plate) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => PlatePreviewView(
            imageFile: imageFile, preExtractedPlate: plate),
      ),
    );
    if (!mounted) return;
    if (result != null) Navigator.of(context).pop(result);
    if (mounted && _isInitialized && _controller != null) {
      _startLiveScanning();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _TopBar(onBack: () => Navigator.of(context).pop()),

            // Camera card ~55%
            Expanded(
              flex: 55,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: _CameraCard(
                  controller: _controller,
                  isInitialized: _isInitialized,
                  error: _error,
                  scanStatus: _scanStatus,
                  pulseAnim: _pulseAnim,
                  scanLineAnim: _scanLineAnim,
                ),
              ),
            ),

            // Bottom panel ~45%
            Expanded(
              flex: 45,
              child: _BottomPanel(
                scanStatus: _scanStatus,
                onCancel: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: _C.bg,
        border: Border(
          bottom:
              BorderSide(color: Colors.white.withOpacity(0.07), width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _C.white70, size: 20),
          ),
          const Expanded(
            child: Text(
              'Scan Number Plate',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// ─── Camera Card ──────────────────────────────────────────────────────────────

class _CameraCard extends StatelessWidget {
  final CameraController? controller;
  final bool isInitialized;
  final String? error;
  final _ScanStatus scanStatus;
  final Animation<double> pulseAnim;
  final Animation<double> scanLineAnim;

  const _CameraCard({
    required this.controller,
    required this.isInitialized,
    required this.error,
    required this.scanStatus,
    required this.pulseAnim,
    required this.scanLineAnim,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: _C.surface,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (error != null)
              _ErrorState(message: error!)
            else if (isInitialized && controller != null)
              _CameraPreview(controller: controller!)
            else
              const _LoadingState(),
            if (error == null)
              _ScanOverlay(
                scanStatus: scanStatus,
                pulseAnim: pulseAnim,
                scanLineAnim: scanLineAnim,
              ),
          ],
        ),
      ),
    );
  }
}

class _CameraPreview extends StatelessWidget {
  final CameraController controller;
  const _CameraPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.previewSize!.height,
        height: controller.value.previewSize!.width,
        child: CameraPreview(controller),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
          color: Colors.white54, strokeWidth: 2),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined,
                size: 52, color: Colors.white38),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white60, fontSize: 14, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

// ─── Scan Overlay ─────────────────────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  final _ScanStatus scanStatus;
  final Animation<double> pulseAnim;
  final Animation<double> scanLineAnim;

  const _ScanOverlay({
    required this.scanStatus,
    required this.pulseAnim,
    required this.scanLineAnim,
  });

  Color _borderColor(double t) {
    switch (scanStatus) {
      case _ScanStatus.detected:
        return _C.green;
      case _ScanStatus.processing:
        return _C.amber;
      case _ScanStatus.scanning:
        return Color.lerp(Colors.white, _C.blue, t)!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([pulseAnim, scanLineAnim]),
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final bw = (w * 0.84).clamp(220.0, 340.0);
            final bh = (bw / 2.3).clamp(96.0, 148.0);
            final left = (w - bw) / 2;
            final top = (h - bh) / 2;
            final rect = Rect.fromLTWH(left, top, bw, bh);
            final rRect =
                RRect.fromRectAndRadius(rect, const Radius.circular(10));
            final borderColor = _borderColor(pulseAnim.value);
            final scanY = rect.top + scanLineAnim.value * (rect.height - 2);

            return CustomPaint(
              size: Size(w, h),
              painter: _ScanBoxPainter(
                boxRect: rRect,
                borderColor: borderColor,
                borderWidth:
                    scanStatus == _ScanStatus.detected ? 3.0 : 2.2,
                darkOpacity: 0.68,
                scanLineY:
                    scanStatus != _ScanStatus.detected ? scanY : null,
                scanLineLeft: rect.left,
                scanLineWidth: rect.width,
                showDetectedFill:
                    scanStatus == _ScanStatus.detected,
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Custom Painter ───────────────────────────────────────────────────────────

class _ScanBoxPainter extends CustomPainter {
  final RRect boxRect;
  final double darkOpacity;
  final Color borderColor;
  final double borderWidth;
  final double? scanLineY;
  final double scanLineLeft;
  final double scanLineWidth;
  final bool showDetectedFill;

  _ScanBoxPainter({
    required this.boxRect,
    required this.borderColor,
    required this.borderWidth,
    this.darkOpacity = 0.68,
    this.scanLineY,
    required this.scanLineLeft,
    required this.scanLineWidth,
    this.showDetectedFill = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dark vignette with cutout
    final full = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()..addRRect(boxRect);
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, hole),
      Paint()..color = Colors.black.withOpacity(darkOpacity),
    );

    // 2. Detected green fill
    if (showDetectedFill) {
      canvas.drawRRect(
          boxRect, Paint()..color = _C.green.withOpacity(0.07));
    }

    // 3. Border
    canvas.drawRRect(
      boxRect,
      Paint()
        ..color = borderColor
        ..strokeWidth = borderWidth
        ..style = PaintingStyle.stroke,
    );

    // 4. Corner brackets
    _drawCorners(canvas);

    // 5. Animated scan line (clipped to box)
    if (scanLineY != null) {
      canvas.save();
      canvas.clipRRect(boxRect);
      final lineRect = Rect.fromLTWH(
          scanLineLeft, scanLineY!, scanLineWidth, 2.5);
      canvas.drawRect(
        lineRect,
        Paint()
          ..shader = LinearGradient(colors: [
            Colors.transparent,
            _C.blue.withOpacity(0.5),
            _C.blue.withOpacity(0.85),
            _C.blue.withOpacity(0.5),
            Colors.transparent,
          ], stops: const [
            0.0, 0.15, 0.5, 0.85, 1.0
          ]).createShader(lineRect),
      );
      canvas.restore();
    }
  }

  void _drawCorners(Canvas canvas) {
    final r = boxRect.outerRect;
    const len = 22.0;
    const rad = 10.0;
    final p = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth + 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void l(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), p);

    // TL
    l(r.left + rad, r.top, r.left + len, r.top);
    l(r.left, r.top + rad, r.left, r.top + len);
    // TR
    l(r.right - len, r.top, r.right - rad, r.top);
    l(r.right, r.top + rad, r.right, r.top + len);
    // BL
    l(r.left + rad, r.bottom, r.left + len, r.bottom);
    l(r.left, r.bottom - len, r.left, r.bottom - rad);
    // BR
    l(r.right - len, r.bottom, r.right - rad, r.bottom);
    l(r.right, r.bottom - len, r.right, r.bottom - rad);
  }

  @override
  bool shouldRepaint(covariant _ScanBoxPainter old) =>
      old.borderColor != borderColor ||
      old.borderWidth != borderWidth ||
      old.scanLineY != scanLineY ||
      old.showDetectedFill != showDetectedFill;
}

// ─── Bottom Panel ─────────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  final _ScanStatus scanStatus;
  final VoidCallback onCancel;

  const _BottomPanel({required this.scanStatus, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      color: _C.bg,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusBadge(status: scanStatus),
            const SizedBox(height: 14),
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _InstructionRow(
                  icon: Icons.crop_free_rounded,
                  text: 'Position the number plate inside the box',
                ),
                SizedBox(height: 10),
                _InstructionRow(
                  icon: Icons.light_mode_outlined,
                  text: 'Ensure good lighting for best results',
                ),
                SizedBox(height: 10),
                _InstructionRow(
                  icon: Icons.stay_current_portrait_outlined,
                  text: 'Hold your phone steady and close',
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _C.white15),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  foregroundColor: _C.white70,
                  overlayColor: Colors.white,
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _C.white70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final _ScanStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final Widget leading;

    switch (status) {
      case _ScanStatus.detected:
        color = _C.green;
        label = 'Plate detected!';
        leading = const Icon(Icons.check_circle_outline_rounded,
            size: 15, color: _C.green);
        break;
      case _ScanStatus.processing:
        color = _C.amber;
        label = 'Analysing…';
        leading = const SizedBox(
          width: 13,
          height: 13,
          child: CircularProgressIndicator(
              color: _C.amber, strokeWidth: 2),
        );
        break;
      case _ScanStatus.scanning:
        color = _C.blue;
        label = 'Scanning for number plate';
        leading = const SizedBox(
          width: 13,
          height: 13,
          child: CircularProgressIndicator(
              color: _C.blue, strokeWidth: 2),
        );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(status),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Instruction Row ──────────────────────────────────────────────────────────

class _InstructionRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InstructionRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _C.white06,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 18, color: Colors.white54),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _C.white55,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── PlateUtils ───────────────────────────────────────────────────────────────

class PlateUtils {
  static String? extractPlateFromRecognizedText(
      RecognizedText recognizedText) {
    final candidates = <String>[];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final raw = line.elements.isNotEmpty
            ? line.elements.map((e) => e.text).join()
            : line.text.replaceAll(RegExp(r'\s+'), '');
        final cleaned = cleanPlateText(raw);
        if (cleaned.length >= 3) candidates.add(cleaned);
      }
    }
    if (candidates.isEmpty) {
      final f = cleanPlateText(recognizedText.text);
      return f.length >= 3 ? f : null;
    }
    candidates.sort((a, b) {
      final diff =
          (isValidPlate(b) ? 1 : 0) - (isValidPlate(a) ? 1 : 0);
      if (diff != 0) return diff;
      return _score(b) - _score(a);
    });
    return candidates.first;
  }

  static int _score(String s) {
    if (s.length < 3 || s.length > 20) return 0;
    return RegExp(r'^[A-Z0-9]+$').hasMatch(s) ? s.length : 0;
  }

  static String cleanPlateText(String raw) {
    if (raw.isEmpty) return '';
    String s = raw.toUpperCase().trim();
    s = s.replaceAll(RegExp(r'\s+'), '');
    s = s.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return _fixOcr(s);
  }

  static String _fixOcr(String s) {
    if (s.length < 2) return s;
    final chars = s.split('');
    for (var i = 0; i < chars.length; i++) {
      final c = chars[i];
      if (i < 3) {
        if (c == '0') chars[i] = 'O';
        else if (c == '1') chars[i] = 'I';
        else if (c == '5') chars[i] = 'S';
        else if (c == '8') chars[i] = 'B';
      } else {
        if (c == 'O') chars[i] = '0';
        else if (c == 'I' || c == 'L') chars[i] = '1';
        else if (c == 'S') chars[i] = '5';
      }
    }
    return chars.join();
  }

  static bool isValidPlate(String s) =>
      s.length >= 3 &&
      s.length <= 20 &&
      RegExp(r'^[A-Z0-9]+$').hasMatch(s);
}

// ─── PlateImagePreprocess ─────────────────────────────────────────────────────

class PlateImagePreprocess {
  static Future<File> preprocess(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return imageFile;

      final w = decoded.width;
      final h = decoded.height;
      final cropW = (w * 0.78).round().clamp(1, w);
      final cropH = (h * 0.42).round().clamp(1, h);
      final x = ((w - cropW) / 2).round().clamp(0, w - 1);
      final y = ((h - cropH) / 2).round().clamp(0, h - 1);

      img.Image out =
          img.copyCrop(decoded, x: x, y: y, width: cropW, height: cropH);
      out = img.adjustColor(out, contrast: 1.35);
      out = img.gaussianBlur(out, radius: 1);

      final temp = File('${imageFile.path}_processed.jpg');
      await temp.writeAsBytes(img.encodeJpg(out, quality: 92));
      return temp;
    } catch (_) {
      return imageFile;
    }
  }
} 