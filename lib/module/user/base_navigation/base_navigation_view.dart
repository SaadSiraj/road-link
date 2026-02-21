import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:roadlink/core/utils/size_utils.dart';
import 'package:roadlink/module/user/dashboard/home_dashboard_view.dart';
import 'package:roadlink/module/user/chat/chat_home_view.dart';
import 'package:roadlink/module/user/dashboard/plate_capture_view.dart';
import 'package:roadlink/module/user/dashboard/car_details_popup.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/routes/routes_name.dart';
import '../../../core/shared/app_dialog.dart';
import '../../../core/shared/app_text.dart';
import '../../../core/shared/loading_dialogue.dart';
import '../../../services/chat_service.dart';
import '../../../viewmodels/chat_home_viewmodel.dart';
import '../../../viewmodels/home_dashboard_viewmodel.dart'
    show HomeDashboardViewModel, PlateSearchResult, PlateSearchStatus;
import '../chat/chat_detail_args.dart';

class BaseNavigation extends StatefulWidget {
  const BaseNavigation({super.key});

  @override
  State<BaseNavigation> createState() => _BaseNavigationState();
}

class _BaseNavigationState extends State<BaseNavigation> with WidgetsBindingObserver {
  int selectedIndex = 0;
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    // Start chat list stream as soon as user enters the app so unread badges update in real time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ChatHomeViewModel>().initialize();
    });
  }

  static final List<Widget> _pages = [
    HomeDashboardView(key: ValueKey('nav_home')),
    SizedBox.shrink(key: ValueKey('nav_fab_slot')),
    ChatHomeView(key: ValueKey('nav_chat')),
  ];

  List<Widget> get pages => _pages;

  void onTabTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  /// Same flow as Home screen "Start Scanning": open plate capture → search → show result.
  Future<void> _handleCenterCameraTap() async {
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    final plate = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const PlateCaptureView()),
    );
    if (!mounted || plate == null || plate.isEmpty) return;
    setState(() => selectedIndex = 0);
    final vm = Provider.of<HomeDashboardViewModel>(context, listen: false);
    final result = await LoadingDialog.run(
      context,
      message: 'Searching...',
      future: () async {
        await Future.delayed(const Duration(milliseconds: 80));
        if (!mounted) return PlateSearchResult.error('Cancelled');
        return vm.searchCarByPlate(plate);
      }(),
    );
    if (!mounted) return;
    _handlePlateSearchResult(context, result);
  }

  void _handlePlateSearchResult(BuildContext context, PlateSearchResult result) {
    HapticFeedback.lightImpact();
    switch (result.status) {
      case PlateSearchStatus.success:
        _showCarDetailsPopup(context, result.carData!, isOwnCar: false);
        break;
      case PlateSearchStatus.ownCar:
        if (result.carData != null) {
          _showCarDetailsPopup(context, result.carData!, isOwnCar: true);
        }
        break;
      case PlateSearchStatus.notFound:
      case PlateSearchStatus.error:
        _showSnackBar(context, result.message ?? 'Something went wrong', isError: true);
        break;
    }
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
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
            Expanded(
              child: AppText(message, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.adaptSize),
        ),
        margin: EdgeInsets.all(16.adaptSize),
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  void _showCarDetailsPopup(BuildContext context, Map<String, dynamic> carData, {bool isOwnCar = false}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CarDetailsPopup(
        carData: carData,
        isOwnCar: isOwnCar,
        onStartChat: () {
          Navigator.pop(ctx);
          _handleStartChat(context, carData);
        },
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }

  Future<void> _handleStartChat(BuildContext context, Map<String, dynamic> carData) async {
    final ownerId = carData['ownerId'] as String?;
    if (ownerId == null) {
      _showSnackBar(context, 'Owner information not found', isError: true);
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
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
        _showSnackBar(context, 'Error starting chat: ${e.toString()}', isError: true);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (selectedIndex != 0) {
      // If not on home tab, go back to home instead of exiting
      setState(() {
        selectedIndex = 0;
      });
      return false;
    }

    // Show exit confirmation dialog
    return await showBlurDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Exit App',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to exit?',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Exit',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: pages[selectedIndex],

        // Floating camera button – same flow as Home "Start Scanning"
        floatingActionButton: FloatingActionButton(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          backgroundColor: AppColors.primaryBlue,
          onPressed: _handleCenterCameraTap,
          child: const Icon(Icons.camera_alt, size: 28, color: AppColors.white),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        bottomNavigationBar: BottomAppBar(
          height: 80.h,
          color: const Color(0xFF0B1220),
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: SizedBox(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(AppImages.homeIcon, 0),
                const SizedBox(width: 40), // Space for FAB
                _navItem(AppImages.chatIcon, 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(String imagePath, int index) {
    final bool isActive = selectedIndex == index;
    return IconButton(
      onPressed: () => onTabTapped(index),
      icon: Image.asset(
        imagePath,
        width: 26.adaptSize,
        height: 26.adaptSize,
        color: isActive ? const Color(0xFF2563EB) : Colors.grey,
      ),
    );
  }
}