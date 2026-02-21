import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/shared/app_text.dart';
import '../../../core/utils/size_utils.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CarDetailsPopup — matches the onboarding design language:
//   • Light scaffold background (not dark)
//   • Blue glow accent, grid card pattern
//   • Prominent car illustration + plate badge
//   • Nicer, lighter info boxes with subtle borders
// ─────────────────────────────────────────────────────────────────────────────

class CarDetailsPopup extends StatelessWidget {
  final Map<String, dynamic> carData;
  final VoidCallback onStartChat;
  final VoidCallback onClose;

  /// When true, shows OK button instead of Start Chat.
  final bool isOwnCar;

  /// Optional notice shown above the car card.
  final String? message;

  const CarDetailsPopup({
    super.key,
    required this.carData,
    required this.onStartChat,
    required this.onClose,
    this.isOwnCar = false,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 24.h),
      child: _PopupShell(
        carData: carData,
        onStartChat: onStartChat,
        onClose: onClose,
        isOwnCar: isOwnCar,
        message: message,
      ),
    );
  }
}

// ─── Shell ────────────────────────────────────────────────────────────────────

class _PopupShell extends StatelessWidget {
  final Map<String, dynamic> carData;
  final VoidCallback onStartChat;
  final VoidCallback onClose;
  final bool isOwnCar;
  final String? message;

  const _PopupShell({
    required this.carData,
    required this.onStartChat,
    required this.onClose,
    required this.isOwnCar,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final plateNumber =
        (carData['plateNumber'] ?? 'N/A').toString().toUpperCase();
    final make       = carData['make']  ?? 'Unknown';
    final model      = carData['model'] ?? 'Unknown';
    final year       = (carData['year'] ?? 'N/A').toString();
    final color      = carData['color'] ?? 'Unknown';
    final imageUrls  = (carData['imageUrls'] as List?)
        ?.whereType<String>()
        .where((u) => u.isNotEmpty)
        .toList() ?? [];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(28.adaptSize),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.12),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.adaptSize),
        child: Stack(
          children: [
            Positioned.fill(child: _GridPattern()),
            Positioned(
              top: -60,
              left: -60,
              child: _GlowBlob(
                color: (isOwnCar ? AppColors.primaryBlue : AppColors.primaryBlue)
                    .withOpacity(0.08),
                size: 240,
              ),
            ),

            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Header(onClose: onClose, isOwnCar: isOwnCar),

                  Padding(
                    padding: EdgeInsets.fromLTRB(20.h, 0, 20.h, 24.h),
                    child: Column(
                      children: [
                        // Own-car notice (takes priority) or custom message
                        if (isOwnCar) ...[
                          _OwnCarNotice(),
                          Gap.v(16),
                        ] else if (message != null && message!.isNotEmpty) ...[
                          _InfoBanner(message: message!),
                          Gap.v(16),
                        ],

                        // Real photos if available, otherwise illustrated card
                        if (imageUrls.isNotEmpty)
                          _CarPhotoCarousel(imageUrls: imageUrls)
                        else
                          _CarIllustrationCard(
                            make: make,
                            model: model,
                            year: year,
                            color: color,
                            plateNumber: plateNumber,
                          ),

                        Gap.v(16),

                        _SpecGrid(
                          make: make,
                          model: model,
                          year: year,
                          color: color,
                        ),

                        Gap.v(16),

                        // Licence plate badge (always visible)
                        _LicencePlateBadge(plateNumber: plateNumber),

                        Gap.v(16),

                        if (!isOwnCar) ...[
                          _PrivacyNotice(),
                          Gap.v(20),
                        ] else
                          Gap.v(4),

                        _CtaButton(
                          isOwnCar: isOwnCar,
                          onClose: onClose,
                          onStartChat: onStartChat,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  final bool isOwnCar;
  const _Header({required this.onClose, this.isOwnCar = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.h, 20.h, 12.h, 20.h),
      child: Row(
        children: [
          Container(
            width: 38.h,
            height: 38.h,
            decoration: BoxDecoration(
              color: isOwnCar ? AppColors.primaryBlue : AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(10.adaptSize),
            ),
            child: Icon(
              isOwnCar ? Icons.person_rounded : Icons.directions_car_rounded,
              color: Colors.white,
              size: 20.fSize,
            ),
          ),
          Gap.h(12),
          Expanded(
            child: AppText(
              isOwnCar ? 'Your Vehicle' : 'Vehicle Found',
              size: 18.fSize,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 7.h),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20.adaptSize),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: AppText(
                'Close',
                size: 12.fSize,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Own Car Notice ───────────────────────────────────────────────────────────

class _OwnCarNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14.adaptSize),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.30),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36.h,
            height: 36.h,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_user_rounded,
              size: 18.fSize,
              color: AppColors.primaryBlue,
            ),
          ),
          Gap.h(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'This is your car',
                  size: 14.fSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
                Gap.v(2),
                AppText(
                  'You are the registered owner of this vehicle.',
                  size: 12.fSize,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Car Photo Carousel ───────────────────────────────────────────────────────

class _CarPhotoCarousel extends StatefulWidget {
  final List<String> imageUrls;
  const _CarPhotoCarousel({required this.imageUrls});

  @override
  State<_CarPhotoCarousel> createState() => _CarPhotoCarouselState();
}

class _CarPhotoCarouselState extends State<_CarPhotoCarousel> {
  int _current = 0;
  late final PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.imageUrls.length;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18.adaptSize),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 200.v,
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: total,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) => CachedNetworkImage(
                imageUrl: widget.imageUrls[i],
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (_, __) => Container(
                  color: AppColors.cardBackground,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.cardBackground,
                  child: Icon(
                    Icons.directions_car_filled_rounded,
                    size: 56.fSize,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
          if (total > 1)
            Container(
              color: AppColors.cardBackground,
              padding: EdgeInsets.symmetric(vertical: 8.v),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  total,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(horizontal: 3.h),
                    width: _current == i ? 18.h : 6.h,
                    height: 6.h,
                    decoration: BoxDecoration(
                      color: _current == i
                          ? AppColors.primaryBlue
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Car Illustration Card ────────────────────────────────────────────────────
//
// Big hero card with:
//   • Grid pattern background
//   • Ambient glow
//   • Car SVG-style icon with colour ring
//   • Plate badge below
//   • Make + model label

class _CarIllustrationCard extends StatelessWidget {
  final String make;
  final String model;
  final String year;
  final String color;
  final String plateNumber;

  const _CarIllustrationCard({
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.plateNumber,
  });

  /// Map a color string to a rough Flutter Color for the ring accent.
  Color _carColor() {
    final c = color.toLowerCase();
    if (c.contains('white')) return const Color(0xFFF0F4FF);
    if (c.contains('black')) return const Color(0xFF2D3748);
    if (c.contains('silver') || c.contains('grey') || c.contains('gray'))
      return const Color(0xFF94A3B8);
    if (c.contains('blue'))  return const Color(0xFF3B82F6);
    if (c.contains('red'))   return const Color(0xFFEF4444);
    if (c.contains('green')) return const Color(0xFF22C55E);
    if (c.contains('gold') || c.contains('yellow'))
      return const Color(0xFFF59E0B);
    if (c.contains('brown') || c.contains('bronze'))
      return const Color(0xFF92400E);
    if (c.contains('orange')) return const Color(0xFFF97316);
    if (c.contains('purple')) return const Color(0xFFA855F7);
    return AppColors.primaryBlue;
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _carColor();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.h),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(22.adaptSize),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Stack(
        children: [
          // Card grid
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22.adaptSize),
              child: _GridPattern(spacing: 28),
            ),
          ),

          Column(
            children: [
              // Car icon with glow ring
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow ring
                  Container(
                    width: 110.h,
                    height: 110.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withOpacity(0.08),
                      border: Border.all(
                        color: accentColor.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                  ),
                  // Inner circle
                  Container(
                    width: 80.h,
                    height: 80.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withOpacity(0.14),
                    ),
                    child: Icon(
                      Icons.directions_car_filled_rounded,
                      size: 44.fSize,
                      color: accentColor,
                    ),
                  ),
                ],
              ),

              Gap.v(14),

              // Make + model
              AppText(
                '$make $model',
                size: 20.fSize,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
                align: TextAlign.center,
              ),

              Gap.v(4),

              // Year + color chip row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SmallChip(label: year, icon: Icons.calendar_today_outlined),
                  Gap.h(8),
                  _SmallChip(
                    label: color,
                    icon: Icons.circle,
                    iconColor: accentColor,
                  ),
                ],
              ),

              Gap.v(18),

              // Licence plate badge
              _LicencePlateBadge(plateNumber: plateNumber),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Small Chip ───────────────────────────────────────────────────────────────

class _SmallChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? iconColor;
  const _SmallChip({required this.label, required this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(20.adaptSize),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11.fSize,
            color: iconColor ?? AppColors.textSecondary,
          ),
          Gap.h(5),
          AppText(
            label,
            size: 12.fSize,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}

// ─── Licence Plate Badge ──────────────────────────────────────────────────────

class _LicencePlateBadge extends StatelessWidget {
  final String plateNumber;
  const _LicencePlateBadge({required this.plateNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 28.h, vertical: 14.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF1a2d4a)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.adaptSize),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AppText(
        plateNumber,
        size: 26.fSize,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 6,
        align: TextAlign.center,
      ),
    );
  }
}

// ─── Spec Grid ────────────────────────────────────────────────────────────────

class _SpecGrid extends StatelessWidget {
  final String make;
  final String model;
  final String year;
  final String color;

  const _SpecGrid({
    required this.make,
    required this.model,
    required this.year,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final specs = [
      (Icons.commute_rounded,      'Make',  make),
      (Icons.drive_eta_rounded,    'Model', model),
      (Icons.calendar_today_rounded,'Year', year),
      (Icons.palette_rounded,      'Color', color),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10.h,
      mainAxisSpacing: 10.h,
      childAspectRatio: 2.4,
      children: specs
          .map((s) => _SpecTile(icon: s.$1, label: s.$2, value: s.$3))
          .toList(),
    );
  }
}

class _SpecTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SpecTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14.adaptSize),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32.h,
            height: 32.h,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.adaptSize),
            ),
            child:
                Icon(icon, size: 16.fSize, color: AppColors.primaryBlue),
          ),
          Gap.h(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(
                  label,
                  size: 10.fSize,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                AppText(
                  value,
                  size: 13.fSize,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Banner ──────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final String message;
  const _InfoBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12.adaptSize),
        border: Border.all(
            color: AppColors.primaryBlue.withOpacity(0.25), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18.fSize, color: AppColors.primaryBlue),
          Gap.h(10),
          Expanded(
            child: AppText(
              message,
              size: 13.fSize,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Privacy Notice ───────────────────────────────────────────────────────────

class _PrivacyNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 11.h),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12.adaptSize),
        border: Border.all(
            color: AppColors.primaryBlue.withOpacity(0.18), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_rounded,
              size: 16.fSize, color: AppColors.primaryBlue),
          Gap.h(8),
          Expanded(
            child: AppText(
              'Owner details are kept private for your security',
              size: 12.fSize,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CTA Button ───────────────────────────────────────────────────────────────

class _CtaButton extends StatelessWidget {
  final bool isOwnCar;
  final VoidCallback onClose;
  final VoidCallback onStartChat;
  const _CtaButton(
      {required this.isOwnCar,
      required this.onClose,
      required this.onStartChat});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isOwnCar ? onClose : onStartChat,
      child: Container(
        width: double.infinity,
        height: 56.h,
        decoration: BoxDecoration(
          gradient: AppColors.splashGradient,
          borderRadius: BorderRadius.circular(16.adaptSize),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOwnCar ? Icons.check_rounded : Icons.chat_bubble_outline_rounded,
              color: Colors.white,
              size: 18.fSize,
            ),
            Gap.h(10),
            AppText(
              isOwnCar ? 'Got it' : 'Start Chat with Owner',
              size: 15.fSize,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CarSpecContent — standalone reusable version (same onboarding style).
// ─────────────────────────────────────────────────────────────────────────────

class CarSpecContent extends StatelessWidget {
  final Map<String, dynamic> carData;
  const CarSpecContent({super.key, required this.carData});

  @override
  Widget build(BuildContext context) {
    final plateNumber =
        (carData['plateNumber'] ?? 'N/A').toString().toUpperCase();
    final make  = carData['make']  ?? 'Unknown';
    final model = carData['model'] ?? 'Unknown';
    final year  = (carData['year'] ?? 'N/A').toString();
    final color = carData['color'] ?? 'Unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CarIllustrationCard(
          make: make,
          model: model,
          year: year,
          color: color,
          plateNumber: plateNumber,
        ),
        Gap.v(16),
        _SpecGrid(make: make, model: model, year: year, color: color),
      ],
    );
  }
}

// ─── Background helpers (mirrors OnboardingView) ──────────────────────────────

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

class _GridPattern extends StatelessWidget {
  final double spacing;
  const _GridPattern({this.spacing = 40});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _GridPainter(spacing: spacing));
}

class _GridPainter extends CustomPainter {
  final double spacing;
  const _GridPainter({required this.spacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withOpacity(0.45)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.spacing != spacing;
}