import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:roadlink/core/utils/size_utils.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/routes/routes_name.dart';
import '../../../core/shared/app_text.dart';
import '../../../viewmodels/car_registration_viewmodel.dart';
import '../../../viewmodels/home_dashboard_viewmodel.dart'
    show HomeDashboardViewModel, PlateSearchResult, PlateSearchStatus;
import '../../auth/register/car_registration_view.dart';
import '../chat/chat_detail_args.dart';
import 'car_details_popup.dart';
import 'plate_capture_view.dart';

class HomeDashboardView extends StatefulWidget {
  const HomeDashboardView({super.key});

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _plateNumberController = TextEditingController();
  bool _isRefreshing = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Defer VM init to after first frame so context is valid when notifyListeners runs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<HomeDashboardViewModel>(context, listen: false).initialize();
    });
  }

  @override
  void dispose() {
    _plateNumberController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Refresh data
    final viewModel = Provider.of<HomeDashboardViewModel>(
      context,
      listen: false,
    );
    await viewModel.refresh();

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeDashboardViewModel>(
      builder: (context, viewModel, child) {
        if (!context.mounted) return const SizedBox.shrink();
        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppColors.primaryBlue,
              backgroundColor: AppColors.cardBackground,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.h,
                    vertical: 24.v,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, viewModel),
                      Divider(color: AppColors.border, thickness: 1),
                      Gap.v(24),
                      _buildUserSection(context, viewModel),
                      Gap.v(24),
                      _buildMetricsSection(viewModel),
                      Gap.v(24),
                      _buildScanCard(context, viewModel),
                      Gap.v(32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, HomeDashboardViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          'Platoscan',
          size: 24.fSize,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryBlue,
        ),
        Row(
          children: [
            Gap.h(12),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, RouteNames.profile),
              child: _buildProfilePicture(context, viewModel),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserSection(
    BuildContext context,
    HomeDashboardViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          viewModel.greeting,
          size: 14.fSize,
          color: AppColors.textSecondary,
        ),
        Gap.v(8),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  _buildUserName(context, viewModel),
                  Gap.h(12),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.h,
                      vertical: 4.v,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12.adaptSize),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6.adaptSize,
                          height: 6.adaptSize,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Gap.h(6),
                        AppText(
                          'Online',
                          size: 12.fSize,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Gap.h(12),
            ScaleTransition(
              scale: _scaleAnimation,
              child: GestureDetector(
                onTapDown: (_) {
                  HapticFeedback.lightImpact();
                  _animationController.forward();
                },
                onTapUp: (_) => _animationController.reverse(),
                onTapCancel: () => _animationController.reverse(),
                onTap: () {
                  viewModel.logCarRegistrationTap();
                  _showCarRegistrationBottomSheet(context);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.h,
                    vertical: 8.v,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryBlue, Color(0xFF1E40AF)],
                    ),
                    borderRadius: BorderRadius.circular(8.adaptSize),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.directions_car,
                        size: 16.fSize,
                        color: Colors.white,
                      ),
                      Gap.h(6),
                      AppText(
                        'Register Car',
                        size: 12.fSize,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Gap.v(12),
        _buildCarInfo(context, viewModel),
      ],
    );
  }

  /// Build user name widget
  Widget _buildUserName(
    BuildContext context,
    HomeDashboardViewModel viewModel,
  ) {
    final userStream = viewModel.getUserStream();

    if (userStream == null) {
      return AppText(
        viewModel.fallbackName,
        size: 28.fSize,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userStream,
      builder: (context, snapshot) {
        if (!context.mounted) return const SizedBox.shrink();
        final displayName = viewModel.getUserName(snapshot.data);

        return AppText(
          displayName,
          size: 28.fSize,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        );
      },
    );
  }

  /// Build car info widget
  Widget _buildCarInfo(BuildContext context, HomeDashboardViewModel viewModel) {
    final carsStream = viewModel.getApprovedCarsStream();

    if (carsStream == null) {
      return Row(
        children: [
          Icon(
            Icons.directions_car,
            size: 18.fSize,
            color: AppColors.textSecondary,
          ),
          Gap.h(8),
          AppText(
            'No car registered',
            size: 14.fSize,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ],
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: carsStream,
      builder: (context, snapshot) {
        if (!context.mounted) return const SizedBox.shrink();
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              Icon(
                Icons.directions_car,
                size: 18.fSize,
                color: AppColors.textSecondary,
              ),
              Gap.h(8),
              AppText(
                'Loading...',
                size: 14.fSize,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ],
          );
        }

        // Update viewModel with current cars
        final carInfo = viewModel.getCarInfo(snapshot.data);
        final approvedCars = viewModel.approvedCars;
        final hasMultipleCars = approvedCars.length > 1;

        return Row(
          children: [
            Icon(
              Icons.directions_car,
              size: 18.fSize,
              color: AppColors.textSecondary,
            ),
            Gap.h(8),
            Expanded(
              child: AppText(
                carInfo,
                size: 14.fSize,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (hasMultipleCars) ...[
              Gap.h(8),
              _buildCarDropdown(context, viewModel, approvedCars),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMetricsSection(HomeDashboardViewModel viewModel) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child:
          _isRefreshing
              ? _buildMetricsLoading()
              : Row(
                key: const ValueKey('metrics'),
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      value: viewModel.scansCount,
                      label: 'Scans',
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0x4A1A56DB), Color(0x4A00E676)],
                      ),
                      icon: Icons.qr_code_scanner,
                    ),
                  ),
                  Gap.h(16),
                  Expanded(
                    child: _buildMetricCard(
                      value: viewModel.chatsCount,
                      label: 'Chats',
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0x4A7C3AED), Color(0x4AF472D0)],
                      ),
                      icon: Icons.chat_bubble_outline,
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildScanCard(
    BuildContext context,
    HomeDashboardViewModel viewModel,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.adaptSize),
      decoration: BoxDecoration(
        color: AppColors.primaryBlueDark,
        borderRadius: BorderRadius.circular(20.adaptSize),
      ),
      child: Column(
        children: [
          Container(
            width: 60.adaptSize,
            height: 60.adaptSize,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.white, width: 1),
              color: Colors.white.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.qr_code_scanner,
              size: 24.fSize,
              color: AppColors.white,
            ),
          ),
          Gap.v(20),
          AppText(
            'Scan Car Plate',
            size: 22.fSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          Gap.v(8),
          AppText(
            'Point your camera at any car plate \nto connect with the driver.',
            size: 14.fSize,
            align: TextAlign.center,
            color: AppColors.white,
          ),
          Gap.v(20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.adaptSize),
            ),
            padding: EdgeInsets.all(4.adaptSize),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleOption(
                  context: context,
                  label: 'Scan',
                  icon: Icons.qr_code_scanner,
                  isSelected: !viewModel.isManualEntry,
                  onTap: () => viewModel.setManualEntry(false),
                ),
                Gap.h(8),
                _buildToggleOption(
                  context: context,
                  label: 'Enter',
                  icon: Icons.edit,
                  isSelected: viewModel.isManualEntry,
                  onTap: () {
                    viewModel.setManualEntry(true);
                    _showPlateNumberDialog(context);
                  },
                ),
              ],
            ),
          ),

          Gap.v(24),

          /// Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _handleStartScanning();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryBlue,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 16.v),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.adaptSize),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.center_focus_weak, size: 20.fSize),
                  Gap.h(8),
                  Text(
                    'Start Scanning',
                    style: TextStyle(
                      fontSize: 16.fSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build metric card widget
  Widget _buildMetricCard({
    required int value,
    required String label,
    required Gradient gradient,
    required IconData icon,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: value.toDouble()),
      curve: Curves.easeOutQuart,
      builder: (context, animatedValue, child) {
        return Container(
          padding: EdgeInsets.all(20.adaptSize),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20.adaptSize),
            boxShadow: [
              BoxShadow(
                color: (gradient as LinearGradient).colors.first.withOpacity(
                  0.3,
                ),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8.adaptSize),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10.adaptSize),
                ),
                child: Icon(icon, size: 20.fSize, color: Colors.white),
              ),
              Gap.v(16),
              AppText(
                '${animatedValue.toInt()}',
                size: 32.fSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              Gap.v(2),
              AppText(
                label,
                size: 14.fSize,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build metrics loading shimmer
  Widget _buildMetricsLoading() {
    return Row(
      key: const ValueKey('loading'),
      children: [
        Expanded(child: _buildShimmerCard()),
        Gap.h(16),
        Expanded(child: _buildShimmerCard()),
      ],
    );
  }

  /// Build shimmer card
  Widget _buildShimmerCard() {
    return Container(
      padding: EdgeInsets.all(20.adaptSize),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.adaptSize),
      ),
      child: Column(
        children: [
          Container(
            width: 80.h,
            height: 40.v,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(8.adaptSize),
            ),
          ),
          Gap.v(8),
          Container(
            width: 60.h,
            height: 20.v,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(8.adaptSize),
            ),
          ),
        ],
      ),
    );
  }

  /// Build profile picture widget
  Widget _buildProfilePicture(
    BuildContext context,
    HomeDashboardViewModel viewModel,
  ) {
    final userStream = viewModel.getUserStream();

    if (userStream == null) {
      return Container(
        width: 40.adaptSize,
        height: 40.adaptSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: ClipOval(
          child: Image.asset(
            AppImages.userAvatar,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.cardBackground,
                child: Icon(
                  Icons.person,
                  color: AppColors.textSecondary,
                  size: 24.fSize,
                ),
              );
            },
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userStream,
      builder: (context, snapshot) {
        if (!context.mounted) return const SizedBox.shrink();
        final photoUrl = viewModel.getUserPhotoUrl(snapshot.data);

        return Container(
          width: 40.adaptSize,
          height: 40.adaptSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: ClipOval(
            child:
                (photoUrl != null && photoUrl.isNotEmpty)
                    ? CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color: AppColors.cardBackground,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryBlue,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            color: AppColors.cardBackground,
                            child: Icon(
                              Icons.person,
                              color: AppColors.textSecondary,
                              size: 24.fSize,
                            ),
                          ),
                    )
                    : Image.asset(
                      AppImages.userAvatar,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.cardBackground,
                          child: Icon(
                            Icons.person,
                            color: AppColors.textSecondary,
                            size: 24.fSize,
                          ),
                        );
                      },
                    ),
          ),
        );
      },
    );
  }

  /// Build car dropdown menu
  Widget _buildCarDropdown(
    BuildContext context,
    HomeDashboardViewModel viewModel,
    List<Map<String, dynamic>> cars,
  ) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.v),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6.adaptSize),
          border: Border.all(
            color: AppColors.primaryBlue.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swap_horiz,
              size: 16.fSize,
              color: AppColors.primaryBlue,
            ),
            Gap.h(4),
            AppText(
              'Change',
              size: 12.fSize,
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.adaptSize),
      ),
      itemBuilder: (context) {
        return cars.asMap().entries.map((entry) {
          final index = entry.key;
          final car = entry.value;
          final carInfo = viewModel.getFormattedCarInfo(car);
          final isSelected = index == viewModel.selectedCarIndex;

          return PopupMenuItem<String>(
            value: index.toString(),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  size: 18.fSize,
                  color:
                      isSelected
                          ? AppColors.primaryBlue
                          : AppColors.textSecondary,
                ),
                Gap.h(12),
                Expanded(
                  child: AppText(
                    carInfo,
                    size: 14.fSize,
                    color:
                        isSelected
                            ? AppColors.primaryBlue
                            : AppColors.background,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      onSelected: (value) {
        final index = int.tryParse(value);
        if (index != null) {
          viewModel.selectCar(index);
        }
      },
    );
  }

  /// Build toggle option widget
  Widget _buildToggleOption({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.v),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8.adaptSize),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18.fSize,
              color: isSelected ? AppColors.primaryBlueDark : AppColors.white,
            ),
            Gap.h(6),
            AppText(
              label,
              size: 14.fSize,
              color: isSelected ? AppColors.primaryBlueDark : AppColors.white,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStartScanning() async {
    HapticFeedback.mediumImpact();
    if (!context.mounted) return;
    final plate = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const PlateCaptureView()),
    );
    if (!context.mounted || plate == null || plate.isEmpty) return;
    final vm = Provider.of<HomeDashboardViewModel>(context, listen: false);
    final result = await vm.searchCarByPlate(plate);
    if (!context.mounted) return;
    _handlePlateSearchResult(context, result);
  }

  /// Show plate number entry dialog; uses VM for search and loading state.
  void _showPlateNumberDialog(BuildContext context) {
    _plateNumberController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => Consumer<HomeDashboardViewModel>(
            builder: (_, vm, __) {
              final searching = vm.isSearchingPlate;
              return Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: EdgeInsets.symmetric(
                  horizontal: 24.h,
                  vertical: 48.v,
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 420,
                    minWidth: 320,
                    maxHeight:
                        MediaQuery.of(dialogContext).size.height -
                        MediaQuery.of(dialogContext).viewInsets.bottom -
                        96,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(28.adaptSize),
                    border: Border.all(
                      color: AppColors.primaryBlue.withOpacity(0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(0.08),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 28.h,
                        vertical: 28.v,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header with icon and title
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(14.adaptSize),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primaryBlue.withOpacity(0.25),
                                      AppColors.primaryBlue.withOpacity(0.12),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    16.adaptSize,
                                  ),
                                  border: Border.all(
                                    color: AppColors.primaryBlue.withOpacity(
                                      0.3,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.search_rounded,
                                  color: AppColors.primaryBlue,
                                  size: 32.fSize,
                                ),
                              ),
                              Gap.h(18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText(
                                      'Plate Number Search',
                                      size: 24.fSize,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    Gap.v(4),
                                    AppText(
                                      'Enter the vehicle registration to look up car details',
                                      size: 14.fSize,
                                      color: AppColors.textSecondary,
                                      maxLines: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Gap.v(28),
                          // Plate label
                          AppText(
                            'Plate Number',
                            size: 14.fSize,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                          Gap.v(10),
                          // Metallic plate with type-on plate input
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _plateNumberController,
                            builder:
                                (_, value, __) => _MetallicPlateField(
                                  controller: _plateNumberController,
                                  hintText: 'e.g. ABC 1234',

                                  enabled: !searching,
                                  onSubmitted: (v) {
                                    if (!searching && v.trim().isNotEmpty) {
                                      _submitPlateSearch(
                                        context,
                                        dialogContext,
                                        v.trim(),
                                        vm,
                                      );
                                    }
                                  },
                                ),
                          ),
                          if (searching) ...[
                            Gap.v(24),
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 20.v,
                                horizontal: 24.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(
                                  16.adaptSize,
                                ),
                                border: Border.all(
                                  color: AppColors.primaryBlue.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 28.adaptSize,
                                    height: 28.adaptSize,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                  Gap.h(16),
                                  AppText(
                                    'Searching for vehicle...',
                                    size: 16.fSize,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          Gap.v(28),
                          // Actions
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed:
                                      searching
                                          ? null
                                          : () => Navigator.pop(dialogContext),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textSecondary,
                                    side: BorderSide(
                                      color:
                                          searching
                                              ? AppColors.border.withOpacity(
                                                0.5,
                                              )
                                              : AppColors.border,
                                      width: 1.5,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16.v,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        14.adaptSize,
                                      ),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: AppText(
                                    'Cancel',
                                    size: 17.fSize,
                                    color:
                                        searching
                                            ? AppColors.textSecondary
                                                .withOpacity(0.5)
                                            : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Gap.h(14),
                              Expanded(
                                flex: 2,
                                child: FilledButton(
                                  onPressed:
                                      searching
                                          ? null
                                          : () {
                                            final text =
                                                _plateNumberController.text
                                                    .trim();
                                            if (text.isNotEmpty) {
                                              _submitPlateSearch(
                                                context,
                                                dialogContext,
                                                text,
                                                vm,
                                              );
                                            }
                                          },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: AppColors
                                        .primaryBlue
                                        .withOpacity(0.35),
                                    disabledForegroundColor: Colors.white
                                        .withOpacity(0.6),
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16.v,
                                    ),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        14.adaptSize,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_rounded,
                                        size: 22.fSize,
                                        color:
                                            searching
                                                ? Colors.white.withOpacity(0.6)
                                                : Colors.white,
                                      ),
                                      Gap.h(10),
                                      AppText(
                                        'Search',
                                        size: 17.fSize,
                                        color:
                                            searching
                                                ? Colors.white.withOpacity(0.6)
                                                : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  Future<void> _submitPlateSearch(
    BuildContext context,
    BuildContext dialogContext,
    String plate,
    HomeDashboardViewModel vm,
  ) async {
    HapticFeedback.mediumImpact();
    final result = await vm.searchCarByPlate(plate);
    if (!mounted) return;
    Navigator.pop(dialogContext);
    _handlePlateSearchResult(context, result);
  }

  void _handlePlateSearchResult(
    BuildContext context,
    PlateSearchResult result,
  ) {
    HapticFeedback.lightImpact();
    switch (result.status) {
      case PlateSearchStatus.success:
        _showCarDetailsPopup(result.carData!, isOwnCar: false);
        break;
      case PlateSearchStatus.ownCar:
        if (result.carData != null) {
          _showCarDetailsPopup(result.carData!, isOwnCar: true);
        }
        break;
      case PlateSearchStatus.notFound:
      case PlateSearchStatus.error:
        _showSnackBar(
          context,
          result.message ?? 'Something went wrong',
          isError: true,
        );
        break;
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    Color? color,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              color: Colors.white,
              size: 20.fSize,
            ),
            Gap.h(12),
            Expanded(child: AppText(message, color: Colors.white)),
          ],
        ),
        backgroundColor:
            color ?? (isError ? AppColors.error : AppColors.primaryBlue),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.adaptSize),
        ),
        margin: EdgeInsets.all(16.adaptSize),
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  /// Show car details popup; when [isOwnCar] true, shows OK button instead of Start Chat.
  void _showCarDetailsPopup(
    Map<String, dynamic> carData, {
    bool isOwnCar = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => CarDetailsPopup(
            carData: carData,
            isOwnCar: isOwnCar,
            onStartChat: () {
              Navigator.pop(context);
              _handleStartChat(carData);
            },
            onClose: () => Navigator.pop(context),
          ),
    );
  }

  /// Start chat with car owner via VM; shows loading then navigates or error.
  Future<void> _handleStartChat(Map<String, dynamic> carData) async {
    final ownerId = carData['ownerId'] as String?;
    if (ownerId == null) {
      _showSnackBar(context, 'Owner information not found', isError: true);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => Center(
            child: Container(
              padding: EdgeInsets.all(24.adaptSize),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16.adaptSize),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryBlue),
                  Gap.v(16),
                  AppText('Starting chat...', color: AppColors.textPrimary),
                ],
              ),
            ),
          ),
    );

    final vm = Provider.of<HomeDashboardViewModel>(context, listen: false);
    try {
      final result = await vm.startChat(ownerId, carData: carData);
      if (!mounted) return;
      Navigator.pop(context);
      if (result == null) {
        _showSnackBar(context, 'Unable to create conversation', isError: true);
        return;
      }
      Navigator.pushNamed(
        context,
        RouteNames.chatDetail,
        arguments: ChatDetailArgs(
          conversationId: result.conversationId,
          otherUserId: result.otherUserId,
          otherUserName: result.otherUserName,
          otherUserPhotoUrl: result.otherUserPhotoUrl,
        ),
      );
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        _showSnackBar(
          context,
          'Error starting chat: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  void _showCarRegistrationBottomSheet(BuildContext context) {
    final viewModel = Provider.of<CarRegistrationViewModel>(
      context,
      listen: false,
    );
    final parentContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => Container(
            height: MediaQuery.of(sheetContext).size.height * 0.9,
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.adaptSize),
                topRight: Radius.circular(20.adaptSize),
              ),
            ),
            child: Column(
              children: [
                /// Handle bar
                Container(
                  margin: EdgeInsets.only(top: 12.v),
                  width: 40.adaptSize,
                  height: 4.adaptSize,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2.adaptSize),
                  ),
                ),

                /// Header
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.h,
                    vertical: 16.v,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        'Register Car',
                        size: 20.fSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      IconButton(
                        onPressed: () {
                          viewModel.resetForm();
                          Navigator.pop(sheetContext);
                        },
                        icon: Icon(
                          Icons.close,
                          color: AppColors.textPrimary,
                          size: 24.fSize,
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(color: AppColors.border, height: 1),

                /// Car Registration Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24.adaptSize),
                    child: Consumer<CarRegistrationViewModel>(
                      builder: (context, vm, child) {
                        return CarRegistrationContent(
                          onNext: () {
                            Navigator.pop(sheetContext);
                            final status = vm.lastRegistrationStatus;
                            final isPending = status == 'pending';
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              SnackBar(
                                content: AppText(
                                  isPending
                                      ? 'your car is goes to admin pending approvel'
                                      : 'Car registered successfully!',
                                  color: AppColors.white,
                                ),
                                backgroundColor:
                                    isPending
                                        ? Colors.orange
                                        : AppColors.success,
                                duration: const Duration(seconds: 3),
                                behavior: SnackBarBehavior.floating,
                                margin: EdgeInsets.only(
                                  top: MediaQuery.of(context).padding.top + 16,
                                  left: 16,
                                  right: 16,
                                ),
                              ),
                            );
                          },
                          onBack: () {
                            viewModel.resetForm();
                            Navigator.pop(sheetContext);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
    ).whenComplete(() {
      // Reset form when bottom sheet is dismissed
      viewModel.resetForm();
    });
  }
}

/// Metallic licence plate look with text field on top for manual plate entry.
class _MetallicPlateField extends StatelessWidget {
  const _MetallicPlateField({
    required this.controller,
    required this.hintText,
    required this.enabled,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final bool enabled;
  final void Function(String) onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72.v,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.adaptSize),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.12),
            blurRadius: 2,
            offset: const Offset(-1, -1),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
          colors: [
            const Color(0xFFE8E8E8),
            const Color(0xFFD0D4D8),
            const Color(0xFFB8BEC4),
            const Color(0xFFA0A8B0),
            const Color(0xFF88909A),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5.adaptSize),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Subtle shine streak (reflective metallic)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 28.v,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.35),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Text field on top of plate
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 12.v),
              child: TextField(
                controller: controller,
                enabled: enabled,

                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                style: TextStyle(
                  fontSize: 28.fSize,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                  letterSpacing: 4,
                  height: 1.2,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                    fontSize: 18.fSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A).withOpacity(0.35),
                    letterSpacing: 2,
                  ),
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.h,
                    vertical: 14.v,
                  ),
                ),
                onSubmitted: onSubmitted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
