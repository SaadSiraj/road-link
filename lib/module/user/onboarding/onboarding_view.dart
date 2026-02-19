import 'dart:core';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/shared/app_text.dart';
import '../../../core/utils/size_utils.dart';
import '../../../core/routes/routes_name.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      badge: 'PLATO SCAN',
      title: 'Connect Through\nYour Plate',
      subtitle:
          'Register your car and start conversations with any vehicle owner — instantly, securely.',
      accentLabel: 'ABC 1234',
      step: 0,
    ),
    OnboardingPage(
      badge: 'SCAN & FIND',
      title: 'Scan Any Plate\nIn Seconds',
      subtitle:
          'Point your camera at any licence plate. Our ML-powered scanner reads and identifies it instantly.',
      accentLabel: 'SCANNING...',
      step: 1,
    ),
    OnboardingPage(
      badge: 'PRIVACY FIRST',
      title: 'Safe, Private\nMessaging',
      subtitle:
          'Your personal details stay protected. Only plate-based identity — full control over your privacy.',
      accentLabel: 'SECURE',
      step: 2,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    } else {
      _goToAuth();
    }
  }

  void _goToAuth() {
    // Finished onboarding → go to registration flow
    Navigator.pushReplacementNamed(context, RouteNames.authSelection);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Stack(
        children: [
          // Ambient background glow - Responsive sizing
          Positioned(
            top: (-120).h,
            left: (-80).h,
            child: _GlowBlob(
              color: AppColors.primaryBlue.withOpacity(0.18),
              size: 380.h,
            ),
          ),
          Positioned(
            bottom: 60.h,
            right: (-100).h,
            child: _GlowBlob(
              color: AppColors.primaryBlueDark.withOpacity(0.12),
              size: 300.h,
            ),
          ),

          // Grid texture overlay
          Positioned.fill(child: _GridOverlay()),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top bar - Responsive padding
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.h,
                    vertical: 20.h,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo mark
                      Row(
                        children: [
                          Container(
                            width: 32.h,
                            height: 32.h,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              borderRadius: 8.r,
                            ),
                            child: Icon(
                              Icons.directions_car_rounded,
                              color: Colors.white,
                              size: 18.fSize,
                            ),
                          ),
                          Gap.h(10),
                          AppText(
                            'Welcome to Platoscan',
                            size: 16.fSize,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ],
                      ),
                      // Skip button
                      if (_currentPage < _pages.length - 1)
                        GestureDetector(
                          onTap: _goToAuth,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.h,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: 20.r,
                              border: Border.all(
                                color: AppColors.border,
                                width: 1,
                              ),
                            ),
                            child: AppText(
                              'Skip',
                              size: 13.fSize,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _OnboardingPageWidget(
                        page: _pages[index],
                        fadeAnimation: _fadeAnimation,
                        slideAnimation: _slideAnimation,
                        isActive: index == _currentPage,
                      );
                    },
                  ),
                ),

                // Bottom section - Responsive padding
                Padding(
                  padding: EdgeInsets.fromLTRB(24.h, 0, 24.h, 36.h),
                  child: Column(
                    children: [
                      // Step indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (i) {
                          final isActive = i == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: EdgeInsets.symmetric(horizontal: 4.h),
                            width: isActive ? 28.h : 8.h,
                            height: 8.h,
                            decoration: BoxDecoration(
                              color:
                                  isActive
                                      ? AppColors.primaryBlue
                                      : AppColors.border,
                              borderRadius: 4.r,
                            ),
                          );
                        }),
                      ),

                      Gap.v(32),

                      // CTA Button
                      GestureDetector(
                        onTap: _nextPage,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          height: 58.h,
                          decoration: BoxDecoration(
                            gradient: AppColors.splashGradient,
                            borderRadius: 16.r,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withOpacity(0.35),
                                blurRadius: 20.h,
                                offset: Offset(0, 8.h),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppText(
                                _currentPage == _pages.length - 1
                                    ? 'Get Started'
                                    : 'Continue',
                                size: 16.fSize,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                                letterSpacing: 0.3,
                              ),
                              Gap.h(10),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 18.fSize,
                              ),
                            ],
                          ),
                        ),
                      ),

                      Gap.v(20),

                      // // Already have account
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.center,
                      //   children: [
                      //     AppText(
                      //       'Already have an account? ',
                      //       size: 13.fSize,
                      //       color: AppColors.textSecondary,
                      //     ),
                      //     GestureDetector(
                      //       onTap: () {
                      //         Navigator.pushReplacementNamed(
                      //           context,
                      //           RouteNames.signIn,
                      //         );
                      //       },
                      //       child: AppText(
                      //         'Sign In',
                      //         size: 13.fSize,
                      //         color: AppColors.primaryBlue,
                      //         fontWeight: FontWeight.w600,
                      //         decoration: TextDecoration.underline,
                      //         decorationColor: AppColors.primaryBlue,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────

class OnboardingPage {
  final String badge;
  final String title;
  final String subtitle;
  final String accentLabel;
  final int step;

  const OnboardingPage({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.accentLabel,
    required this.step,
  });
}

// ─────────────────────────────────────────────
// Page widget
// ─────────────────────────────────────────────

class _OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final bool isActive;

  const _OnboardingPageWidget({
    required this.page,
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.h),
      child: FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Gap.v(20),

              // Visual illustration area
              Expanded(
                flex: 5,
                child: Center(child: _IllustrationCard(page: page)),
              ),

              Gap.v(36),

              // Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.12),
                  borderRadius: 6.r,
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                  ),
                ),
                child: AppText(
                  page.badge,
                  size: 11.fSize,
                  color: AppColors.primaryBlueLight,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),

              Gap.v(16),

              // Title
              AppText(
                page.title,
                size: 32.fSize,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.15,
                letterSpacing: -0.8,
              ),

              Gap.v(14),

              // Subtitle
              AppText(
                page.subtitle,
                size: 15.fSize,
                color: AppColors.textSecondary,
                height: 1.6,
                letterSpacing: 0.1,
              ),

              Gap.v(28),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Illustration cards per page
// ─────────────────────────────────────────────

class _IllustrationCard extends StatelessWidget {
  final OnboardingPage page;

  const _IllustrationCard({required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: 320.h),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: 28.r,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: ClipRRect(
        borderRadius: 28.r,
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(child: _CardGridPattern()),

            // Content per page
            Center(child: _pageContent()),
          ],
        ),
      ),
    );
  }

  Widget _pageContent() {
    switch (page.step) {
      case 0:
        return _Page1Visual();
      case 1:
        return _Page2Visual();
      case 2:
        return _Page3Visual();
      default:
        return const SizedBox();
    }
  }
}

// Page 1: Plate + chat bubbles
class _Page1Visual extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Licence plate
          _LicencePlate(text: 'ABC 1234'),
          Gap.v(28),

          // Chat bubbles
          _ChatBubble(text: 'Hey, you left your lights on!', isSent: false),
          Gap.v(10),
          _ChatBubble(text: 'Thanks! On my way 🙏', isSent: true),
        ],
      ),
    );
  }
}

// Page 2: Scanner UI
class _Page2Visual extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scan frame
          Container(
            width: 220.h,
            height: 90.h,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryBlue, width: 2),
              borderRadius: 12.r,
            ),
            child: Stack(
              children: [
                // Corner accents
                ..._cornerAccents(),
                // Scanning line
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      height: 2,
                      margin: EdgeInsets.symmetric(horizontal: 8.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.primaryBlue,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Plate text inside
                Center(
                  child: AppText(
                    'XYZ 5678',
                    size: 22.fSize,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),

          Gap.v(20),

          // Status pill
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.15),
              borderRadius: 20.r,
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8.h,
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlueLight,
                    shape: BoxShape.circle,
                  ),
                ),
                Gap.h(8),
                AppText(
                  'Plate detected',
                  size: 13.fSize,
                  color: AppColors.primaryBlueLight,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),

          Gap.v(20),

          // Car info card
          Container(
            padding: EdgeInsets.all(14.h),
            decoration: BoxDecoration(
              color: AppColors.backgroundSoft,
              borderRadius: 14.r,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.directions_car_filled_rounded,
                  color: AppColors.primaryBlue,
                  size: 28.fSize,
                ),
                Gap.h(12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Toyota Camry 2022',
                      size: 13.fSize,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    AppText(
                      'Silver · XYZ 5678',
                      size: 12.fSize,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _cornerAccents() {
    final size = 16.h;
    const thickness = 2.5;
    final color = AppColors.primaryBlue;

    return [
      Positioned(
        top: -1,
        left: -1,
        child: _CornerAccent(
          top: true,
          left: true,
          size: size,
          thickness: thickness,
          color: color,
        ),
      ),
      Positioned(
        top: -1,
        right: -1,
        child: _CornerAccent(
          top: true,
          left: false,
          size: size,
          thickness: thickness,
          color: color,
        ),
      ),
      Positioned(
        bottom: -1,
        left: -1,
        child: _CornerAccent(
          top: false,
          left: true,
          size: size,
          thickness: thickness,
          color: color,
        ),
      ),
      Positioned(
        bottom: -1,
        right: -1,
        child: _CornerAccent(
          top: false,
          left: false,
          size: size,
          thickness: thickness,
          color: color,
        ),
      ),
    ];
  }
}

// Page 3: Privacy / security
class _Page3Visual extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.h),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shield icon
            Container(
              width: 80.h,
              height: 80.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withOpacity(0.12),
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.shield_rounded,
                color: AppColors.primaryBlue,
                size: 40.fSize,
              ),
            ),

            Gap.v(24),

            // Privacy feature rows
            ...[
              ('Plate-based identity only', Icons.badge_rounded),
              ('No personal data exposed', Icons.lock_outline_rounded),
              ('Block & report any user', Icons.block_rounded),
            ].map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.h,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSoft,
                    borderRadius: 12.r,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.$2, color: AppColors.success, size: 18.fSize),
                      Gap.h(10),
                      AppText(
                        item.$1,
                        size: 13.fSize,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Reusable small widgets
// ─────────────────────────────────────────────

class _LicencePlate extends StatelessWidget {
  final String text;

  const _LicencePlate({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 28.h, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A3441), Color(0xFF1E2A38)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: 10.r,
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.2),
            blurRadius: 16.h,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: AppText(
        text,
        size: 30.fSize,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
        letterSpacing: 6,
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isSent;

  const _ChatBubble({required this.text, required this.isSent});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 10.h),
        constraints: BoxConstraints(maxWidth: 220.h),
        decoration: BoxDecoration(
          color: isSent ? AppColors.primaryBlue : AppColors.backgroundSoft,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.h),
            topRight: Radius.circular(16.h),
            bottomLeft: Radius.circular(isSent ? 16.h : 4.h),
            bottomRight: Radius.circular(isSent ? 4.h : 16.h),
          ),
          border: isSent ? null : Border.all(color: AppColors.border),
        ),
        child: AppText(
          text,
          size: 13.fSize,
          color: isSent ? Colors.white : AppColors.textPrimary,
          height: 1.4,
        ),
      ),
    );
  }
}

class _CornerAccent extends StatelessWidget {
  final bool top;
  final bool left;
  final double size;
  final double thickness;
  final Color color;

  const _CornerAccent({
    required this.top,
    required this.left,
    required this.size,
    required this.thickness,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          top: top,
          left: left,
          color: color,
          thickness: thickness,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool top;
  final bool left;
  final Color color;
  final double thickness;

  _CornerPainter({
    required this.top,
    required this.left,
    required this.color,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = thickness
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;

    if (top && left) {
      path.moveTo(0, h);
      path.lineTo(0, 0);
      path.lineTo(w, 0);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(w, 0);
      path.lineTo(w, h);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, h);
      path.lineTo(w, h);
    } else {
      path.moveTo(0, h);
      path.lineTo(w, h);
      path.lineTo(w, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
// Background effects
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
          ..color = AppColors.border.withOpacity(0.4)
          ..strokeWidth = 0.5;

    final spacing = 48.h;

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

class _CardGridPattern extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CardGridPainter());
  }
}

class _CardGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.border.withOpacity(0.5)
          ..strokeWidth = 0.5;

    final spacing = 32.h;

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
