import 'package:flutter/material.dart';

import '../../module/admin/admin_dashboard_view.dart';
import '../../module/admin/pending_registration_car_view.dart';
import '../../module/admin/user_list_view.dart';
import '../../module/admin/car_list_view.dart';
import '../../module/legal/privacy_policy_view.dart';
import '../../module/legal/terms_condition_view.dart';
import '../../module/legal/help_center_view.dart';
import '../../module/splash/splash_view.dart';
import '../../module/auth/auth_selection_view.dart';
import '../../module/auth/signin_view.dart.dart';
import '../../module/auth/register/registration_view.dart';
import '../../module/auth/register/account_details_view.dart';
import '../../module/auth/register/car_registration_view.dart';
import '../../module/auth/register/verify_code_view.dart';
import '../../module/auth/register/complete_profile_view.dart';
import '../../module/user/dashboard/home_dashboard_view.dart';
import '../../module/user/dashboard/plate_capture_view.dart';
import '../../module/user/chat/chat_detail_args.dart';
import '../../module/user/chat/chat_detail_view.dart';
import '../../module/user/base_navigation/base_navigation_view.dart';
import '../../module/user/onboarding/onboarding_view.dart';
import '../../module/user/profile/profile_view.dart';
import '../../module/user/profile/registrations_view.dart';
import '../../module/user/profile/edit_profile_view.dart';
import '../../module/user/profile/privacy_permissions_view.dart';
import '../shared/app_text.dart';
import 'routes_name.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    WidgetBuilder builder;

    switch (settings.name) {
      // Splash
      case RouteNames.splash:
        builder = (_) => const SplashView();
        break;
      case RouteNames.onboarding:
        builder = (_) => const OnboardingView();
        break;
      
      // Auth
      case RouteNames.authSelection:
        builder = (_) => const AuthSelectionView();
        break;
      case RouteNames.signIn:
        builder = (_) => const SignInView();
        break;
      case RouteNames.registration:
        builder = (_) => const RegistrationView();
        break;

      // Registration Flow (Individual routes - kept for backward compatibility)
      case RouteNames.accountDetails:
        builder = (_) => const AccountDetailsView();
        break;
      case RouteNames.carRegistration:
        builder = (_) => const CarRegistrationView();
        break;
      case RouteNames.verifyCode:
        builder = (_) => const VerifyCodeView();
        break;
      case RouteNames.completeProfile:
        builder = (_) => const CompleteProfileView();
        break;

      // Dashboard
      case RouteNames.homeDashboard:
        builder = (_) => const HomeDashboardView();
        break;
      case RouteNames.plateCapture:
        builder = (_) => const PlateCaptureView();
        break;
      case RouteNames.baseNavigation:
        builder = (_) => const BaseNavigation();
        break;

      // Chat
      case RouteNames.chatDetail:
        final chatArgs = ChatDetailArgs.fromDynamic(settings.arguments);
        builder = (_) => ChatDetailView(args: chatArgs);
        break;

      // Profile
      case RouteNames.profile:
        builder = (_) => const ProfileView();
        break;
      case RouteNames.registrations:
        builder = (_) => const RegistrationsView();
        break;
      case RouteNames.editProfile:
        builder = (_) => const EditProfileView();
        break;
      case RouteNames.privacyPermissions:
        builder = (_) => const PrivacyPermissionsView();
        break;
      case RouteNames.termsCondition:
        builder = (_) => const TermsConditionView();
        break;
      case RouteNames.privacyPolicy:
        builder = (_) => const PrivacyPolicyView();
        break;
      case RouteNames.helpCenter:
        builder = (_) => const HelpCenterView();
        break;

      // Admin
      case RouteNames.adminDashboard:
        builder = (_) => const AdminDashboardView();
        break;
      case RouteNames.pendingCarRequests:
        builder = (_) => const PendingCarRequestsView();
        break;
      case RouteNames.usersManagement:
        builder = (_) => const UsersListView();
        break;
      case RouteNames.carsManagement:
        builder = (_) => const CarsListView();
        break;

      default:
        builder =
            (_) => const Scaffold(
              body: Center(child: AppText("🚫 No route defined")),
            );
    }

    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      settings: settings,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Slide from right
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  /// 🟢 Push new screen
  static Future<dynamic> push(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  /// 🟡 Replace current screen
  static Future<dynamic> pushReplacement(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// 🔴 Clear all and go to new screen
  static Future<dynamic> pushAndRemoveUntil(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (Route<dynamic> route) => false,
      arguments: arguments,
    );
  }

  /// ⬅️ Pop screen
  static void pop(BuildContext context, [Object? result]) {
    Navigator.pop(context, result);
  }
}
