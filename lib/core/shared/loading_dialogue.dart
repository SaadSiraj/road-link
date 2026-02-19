import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/shared/app_text.dart';
import '../../../core/utils/size_utils.dart';

// ═══════════════════════════════════════════════════════════════
//  LoadingDialog — PlateChat reusable loading overlay
//
//  USAGE:
//    LoadingDialog.show(context);
//    LoadingDialog.show(context, message: 'Scanning plate...');
//    LoadingDialog.hide(context);
//    await LoadingDialog.run(context, future: myFuture(), message: 'Saving...');
// ═══════════════════════════════════════════════════════════════

class LoadingDialog {
  LoadingDialog._();

  static void show(
    BuildContext context, {
    String message = 'Please wait...',
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.transparent,
      builder: (_) => _LoadingDialogWidget(message: message),
    );
  }

  static void hide(BuildContext context) {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  static Future<T> run<T>(
    BuildContext context, {
    required Future<T> future,
    String message = 'Please wait...',
  }) async {
    show(context, message: message);
    try {
      final result = await future;
      if (context.mounted) hide(context);
      return result;
    } catch (e) {
      if (context.mounted) hide(context);
      rethrow;
    }
  }
}

// ─────────────────────────────────────────────
// Root widget — full screen stack so we control
// both the background and the card independently
// ─────────────────────────────────────────────

class _LoadingDialogWidget extends StatefulWidget {
  final String message;
  const _LoadingDialogWidget({required this.message});

  @override
  State<_LoadingDialogWidget> createState() => _LoadingDialogWidgetState();
}

class _LoadingDialogWidgetState extends State<_LoadingDialogWidget>
    with TickerProviderStateMixin {
  // Entrance
  late final AnimationController _entranceCtrl;
  late final Animation<double> _scaleFade;

  // Ring 1 — fast CW
  late final AnimationController _ring1Ctrl;
  // Ring 2 — medium CCW
  late final AnimationController _ring2Ctrl;
  // Ring 3 — slow CW
  late final AnimationController _ring3Ctrl;

  // Inner plate pulse
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // Shimmer text
  late final AnimationController _shimmerCtrl;
  late final Animation<double> _shimmerAnim;

  // Dots
  late final AnimationController _dotCtrl;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _scaleFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOutBack,
    );

    _ring1Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _ring2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _ring3Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1.8, end: 2.8).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );

    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _ring1Ctrl.dispose();
    _ring2Ctrl.dispose();
    _ring3Ctrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // ── Full-screen background matching scaffold ──
          Positioned.fill(
            child: Stack(
              children: [
                // Base dark color
                Container(color: AppColors.scaffoldBackground.withOpacity(0.88)),

                // Glow top-left (same as onboarding)
                Positioned(
                  top: -140,
                  left: -100,
                  child: _GlowBlob(
                    color: AppColors.primaryBlue.withOpacity(0.22),
                    size: 420,
                  ),
                ),

                // Glow bottom-right
                Positioned(
                  bottom: -80,
                  right: -120,
                  child: _GlowBlob(
                    color: AppColors.primaryBlueDark.withOpacity(0.16),
                    size: 340,
                  ),
                ),

                // Grid texture
                Positioned.fill(child: _GridOverlay()),
              ],
            ),
          ),

          // ── Centered card ──
          Center(
            child: FadeTransition(
              opacity: _scaleFade,
              child: ScaleTransition(
                scale: _scaleFade,
                child: _LoadingCard(
                  ring1: _ring1Ctrl,
                  ring2: _ring2Ctrl,
                  ring3: _ring3Ctrl,
                  pulse: _pulseAnim,
                  shimmer: _shimmerAnim,
                  dots: _dotCtrl,
                  message: widget.message,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// The card
// ─────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  final AnimationController ring1;
  final AnimationController ring2;
  final AnimationController ring3;
  final Animation<double> pulse;
  final Animation<double> shimmer;
  final AnimationController dots;
  final String message;

  const _LoadingCard({
    required this.ring1,
    required this.ring2,
    required this.ring3,
    required this.pulse,
    required this.shimmer,
    required this.dots,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260.h,
      padding: EdgeInsets.fromLTRB(28.h, 36.v, 28.h, 30.v),
      decoration: BoxDecoration(
        // Slightly lighter than scaffold so it pops
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(28.adaptSize),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.18),
          width: 1,
        ),
        boxShadow: [
          // Deep shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.50),
            blurRadius: 60,
            offset: const Offset(0, 24),
          ),
          // Blue ambient glow
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.12),
            blurRadius: 80,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Triple-ring spinner
          _TripleRingSpinner(
            ring1: ring1,
            ring2: ring2,
            ring3: ring3,
            pulse: pulse,
          ),

          Gap.v(26),

          // Divider line accent
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.primaryBlue.withOpacity(0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          Gap.v(18),

          // Shimmer label
          _ShimmerLabel(shimmerAnim: shimmer),

          Gap.v(10),

          // Message + dots
          _MessageDots(message: message, dotCtrl: dots),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Triple ring spinner
// ─────────────────────────────────────────────

class _TripleRingSpinner extends StatelessWidget {
  final AnimationController ring1; // fast CW
  final AnimationController ring2; // medium CCW
  final AnimationController ring3; // slow CW
  final Animation<double> pulse;

  const _TripleRingSpinner({
    required this.ring1,
    required this.ring2,
    required this.ring3,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final outerSize = 130.adaptSize;
    final midSize   = 100.adaptSize;
    final innerSize = 72.adaptSize;
    final plateSize = 58.adaptSize;

    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Ring 3 — slow CW arc (faintest, biggest)
          AnimatedBuilder(
            animation: ring3,
            builder: (_, __) => Transform.rotate(
              angle: ring3.value * 2 * math.pi,
              child: CustomPaint(
                size: Size(outerSize, outerSize),
                painter: _ArcRingPainter(
                  color: AppColors.primaryBlue.withOpacity(0.20),
                  strokeWidth: 1.5,
                  arcFraction: 0.30,
                  dashCount: 1,
                ),
              ),
            ),
          ),

          // ── Ring 2 — medium CCW arc
          AnimatedBuilder(
            animation: ring2,
            builder: (_, __) => Transform.rotate(
              angle: -ring2.value * 2 * math.pi,
              child: CustomPaint(
                size: Size(midSize, midSize),
                painter: _ArcRingPainter(
                  color: AppColors.primaryBlue.withOpacity(0.45),
                  strokeWidth: 2.0,
                  arcFraction: 0.45,
                  dashCount: 1,
                ),
              ),
            ),
          ),

          // ── Ring 1 — fast CW full arc with glow
          AnimatedBuilder(
            animation: ring1,
            builder: (_, __) => Transform.rotate(
              angle: ring1.value * 2 * math.pi,
              child: CustomPaint(
                size: Size(innerSize, innerSize),
                painter: _GlowArcPainter(),
              ),
            ),
          ),

          // ── Pulsing plate center ──
          ScaleTransition(
            scale: pulse,
            child: Container(
              width: plateSize,
              height: plateSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF1F2E45), Color(0xFF111A2D)],
                  radius: 0.85,
                ),
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.25),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(child: _CenterPlate()),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Center "PC" plate badge
// ─────────────────────────────────────────────

class _CenterPlate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.h, vertical: 5.v),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3A50), Color(0xFF18243A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(5.adaptSize),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.60),
          width: 1.5,
        ),
      ),
      child: AppText(
        'PC',
        size: 13.fSize,
        fontWeight: FontWeight.w900,
        color: AppColors.white,
        letterSpacing: 3.5,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shimmer "PLATOSCAN" label
// ─────────────────────────────────────────────

class _ShimmerLabel extends StatelessWidget {
  final Animation<double> shimmerAnim;

  const _ShimmerLabel({required this.shimmerAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmerAnim,
      builder: (_, __) => ShaderMask(
        shaderCallback: (rect) => LinearGradient(
          begin: Alignment(shimmerAnim.value - 1.0, 0),
          end: Alignment(shimmerAnim.value, 0),
          colors: [
            AppColors.textTertiary,
            AppColors.primaryBlueLight,
            AppColors.textTertiary,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect),
        blendMode: BlendMode.srcIn,
        child: AppText(
          'P L A T O S C A N',
          size: 11.fSize,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          letterSpacing: 2.0,
          align: TextAlign.center,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Message + staggered dots
// ─────────────────────────────────────────────

class _MessageDots extends StatelessWidget {
  final String message;
  final AnimationController dotCtrl;

  const _MessageDots({required this.message, required this.dotCtrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: AppText(
            message,
            size: 13.fSize,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            align: TextAlign.center,
            height: 1.5,
          ),
        ),
        Gap.h(4),
        _Dots(controller: dotCtrl),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  final AnimationController controller;

  const _Dots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: controller,
          builder: (_, __) {
            final t = ((controller.value + i * 0.28) % 1.0);
            final p = t < 0.5 ? t * 2.0 : (1.0 - t) * 2.0;
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 2.h),
              width: 4.adaptSize,
              height: 4.adaptSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withOpacity(
                  (0.30 + 0.70 * p).clamp(0.30, 1.0),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────
// CustomPainters
// ─────────────────────────────────────────────

/// Draws a single arc that looks like a spinner ring
class _ArcRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double arcFraction; // 0.0–1.0 of full circle
  final int dashCount;

  _ArcRingPainter({
    required this.color,
    required this.strokeWidth,
    required this.arcFraction,
    this.dashCount = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;
    final sweepAngle = 2 * math.pi * arcFraction;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcRingPainter old) =>
      old.color != color || old.arcFraction != arcFraction;
}

/// Fast ring with a bright leading edge glow
class _GlowArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Dim trail
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + 0.4,
      2 * math.pi * 0.72,
      false,
      Paint()
        ..color = AppColors.primaryBlue.withOpacity(0.22)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Bright leading tip
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      0.55,
      false,
      Paint()
        ..color = AppColors.primaryBlue
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Hot white tip dot
    final tipX = center.dx + radius * math.cos(-math.pi / 2);
    final tipY = center.dy + radius * math.sin(-math.pi / 2);
    canvas.drawCircle(
      Offset(tipX, tipY),
      3.5,
      Paint()
        ..color = AppColors.primaryBlueLight
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      Offset(tipX, tipY),
      2,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ─────────────────────────────────────────────
// Background helpers (same as onboarding)
// ─────────────────────────────────────────────

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _GridOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withOpacity(0.30)
      ..strokeWidth = 0.5;

    const spacing = 48.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}