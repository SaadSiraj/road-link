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

class _SplashViewState extends State<SplashView>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    _checkLoginAndNavigate();
  }

  Future<void> _checkLoginAndNavigate() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check if user is logged in
    final isLoggedIn = await SharedPreferencesService.isLoggedIn();

    if (isLoggedIn) {
      // Check if user is admin
      final isAdmin = await SharedPreferencesService.isAdmin();

      if (isAdmin) {
        // Navigate to admin dashboard
        Navigator.pushReplacementNamed(context, RouteNames.adminDashboard);
      } else {
        // Navigate to base navigation (user dashboard)
        Navigator.pushReplacementNamed(context, RouteNames.baseNavigation);
      }
    } else {
      // User not logged in, go to auth selection
      Navigator.pushReplacementNamed(context, RouteNames.authSelection);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _animation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// App Logo
                Container(
                  width: 100.adaptSize,
                  height: 100.adaptSize,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    size: 50,
                    color: AppColors.primaryBlue,
                  ),
                ),

                Gap.v(16),

                /// App Name
                AppText(
                  'Car',
                  size: 28.fSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),

                Gap.v(8),

                /// Loading Indicator
                const CircularProgressIndicator(
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
