import 'package:flutter/material.dart';
import 'package:roadlink/core/utils/size_utils.dart';
import 'package:roadlink/module/user/dashboard/home_dashboard_view.dart';
import 'package:roadlink/module/user/chat/chat_home_view.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/shared/app_dialog.dart';

class BaseNavigation extends StatefulWidget {
  const BaseNavigation({super.key});

  @override
  State<BaseNavigation> createState() => _BaseNavigationState();
}

class _BaseNavigationState extends State<BaseNavigation> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    HomeDashboardView(),
    HomeDashboardView(),
    ChatHomeView(),
  ];

  void onTabTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
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

        // Floating camera button
        floatingActionButton: FloatingActionButton(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          backgroundColor: AppColors.primaryBlue,
          onPressed: () => onTabTapped(1),
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