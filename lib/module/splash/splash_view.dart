import 'package:flutter/material.dart';
import 'package:roadlink/core/utils/size_utils.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/routes_name.dart';
import '../../../core/shared/app_text.dart';
import '../../../services/shared_preferences_service.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  // Logo scale + fade
  late AnimationController _logoController;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;

  // Tagline fade (delayed)
  late AnimationController _taglineController;
  late Animation<double> _taglineFade;
  late Animation<Offset> _taglineSlide;

  // Plate shimmer
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;

  // Bottom loader dots
  late AnimationController _dotController;

  @override
  void initState() {
    super.initState();

    // ── Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoFade = CurvedAnimation(parent: _logoController, curve: Curves.easeOut);
    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    // ── Tagline animation (starts after logo)
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _taglineFade = CurvedAnimation(
      parent: _taglineController,
      curve: Curves.easeOut,
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOut),
    );

    // ── Shimmer on the plate strip
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // ── Dot pulse for loader
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Start sequence
    _logoController.forward().then((_) {
      _taglineController.forward();
    });

    _checkLoginAndNavigate();
  }

  Future<void> _checkLoginAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final isLoggedIn = await SharedPreferencesService.isLoggedIn();
    if (isLoggedIn) {
      final isAdmin = await SharedPreferencesService.isAdmin();
      if (isAdmin) {
        Navigator.pushReplacementNamed(context, RouteNames.adminDashboard);
      } else {
        Navigator.pushReplacementNamed(context, RouteNames.baseNavigation);
      }
    } else {
      // First-time / logged-out users go to onboarding
      Navigator.pushReplacementNamed(context, RouteNames.onboarding);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _taglineController.dispose();
    _shimmerController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Stack(
        children: [
          // ── Background grid texture
          Positioned.fill(child: _GridOverlay()),

          // ── Ambient glow top-left
          Positioned(
            top: -140,
            left: -100,
            child: _GlowBlob(
              color: AppColors.primaryBlue.withOpacity(0.20),
              size: 420,
            ),
          ),

          // ── Ambient glow bottom-right
          Positioned(
            bottom: -100,
            right: -120,
            child: _GlowBlob(
              color: AppColors.primaryBlueDark.withOpacity(0.14),
              size: 340,
            ),
          ),

          // ── Main centered content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo mark
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(opacity: _logoFade, child: _LogoMark()),
                ),

                SizedBox(height: 28.adaptSize),

                // App name + tagline
                SlideTransition(
                  position: _taglineSlide,
                  child: FadeTransition(
                    opacity: _taglineFade,
                    child: Column(
                      children: [
                        // "Platoscan" name with plate accent
                        _AnimatedPlateStrip(shimmerAnim: _shimmerAnim),

                        SizedBox(height: 12.adaptSize),

                        // Tagline
                        AppText(
                          'Plate-to-plate communication',
                          size: 14.fSize,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.3,
                          fontWeight: FontWeight.w400,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom loader
          Positioned(
            bottom: 52,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _taglineFade,
              child: Column(
                children: [
                  _PulseDots(controller: _dotController),
                  SizedBox(height: 14.adaptSize),
                  AppText(
                    'Powered by Anthropic · v1.0.0',
                    size: 11.fSize,
                    color: AppColors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Logo mark widget
// ─────────────────────────────────────────────

class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow ring
        Container(
          width: 112.adaptSize,
          height: 112.adaptSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryBlue.withOpacity(0.12),
            border: Border.all(
              color: AppColors.primaryBlue.withOpacity(0.25),
              width: 1.5,
            ),
          ),
        ),
        // Inner circle
        Container(
          width: 88.adaptSize,
          height: 88.adaptSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.splashGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.45),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.directions_car_rounded,
            size: 42.adaptSize,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// App name with shimmering plate accent
// ─────────────────────────────────────────────

class _AnimatedPlateStrip extends StatelessWidget {
  final Animation<double> shimmerAnim;

  const _AnimatedPlateStrip({required this.shimmerAnim});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        AppText(
          'Plate',
          size: 34.fSize,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.8,
        ),
        SizedBox(width: 6.adaptSize),
        // "Chat" inside a mini plate-style badge with shimmer
        AnimatedBuilder(
          animation: shimmerAnim,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.7),
                  width: 1.5,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: const [Color(0xFF2A3441), Color(0xFF1E2A38)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ShaderMask(
                shaderCallback: (rect) {
                  return LinearGradient(
                    begin: Alignment(shimmerAnim.value - 1, 0),
                    end: Alignment(shimmerAnim.value, 0),
                    colors: [
                      AppColors.textPrimary,
                      Colors.white,
                      AppColors.textPrimary,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.srcIn,
                child: AppText(
                  'SCAN',
                  size: 22.fSize,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: 4,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Pulsing dots loader
// ─────────────────────────────────────────────

class _PulseDots extends StatelessWidget {
  final AnimationController controller;

  const _PulseDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            // Stagger each dot
            final delay = i * 0.25;
            final t = ((controller.value + delay) % 1.0);
            final opacity = (0.3 + 0.7 * (t < 0.5 ? t * 2 : (1.0 - t) * 2))
                .clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withOpacity(opacity),
              ),
            );
          },
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────
// Background helpers
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
    final paint =
        Paint()
          ..color = AppColors.border.withOpacity(0.35)
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
