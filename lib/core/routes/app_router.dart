import 'package:flutter/material.dart';

import '../../module/auth/sign_in.dart';
import '../shared/widgets/app_text.dart';
import 'routes_name.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    WidgetBuilder builder;

    switch (settings.name) {
      case RouteNames.signIn:
        builder = (_) => const SignInView();
        break;
      // case RouteNames.resetPassword:
      //   builder = (_) => const ResetPasswordView();
      //   break;
      // case RouteNames.home:
      //   builder = (_) => const HomeView();
      //   break;
      // case RouteNames.myTools:
      //   builder = (_) => const MyToolsView();
      //   break;
      // case RouteNames.onboarding:
      //   builder = (_) => const OnboardingView();
      //   break;
      // case RouteNames.register:
      //   builder = (_) => const RegisterView();
      // break;
      // case RouteNames.authDecision:
      //   builder = (_) => const AuthDecisionView();
      //   break;
      // case RouteNames.signUpWithPhone:
      //   builder = (_) => const SignupWithPhoneScreen();
      //   break;
      // case RouteNames.login:
      //   builder = (_) => const LoginView(); // Replace with LoginView later
      //   break;
      // case RouteNames.home:
      //   builder = (_) => const HomeView();
      //   break;

      // case RouteNames.parcelDelivery:
      //   builder = (_) => const ParcelDeliveryView();
      //   break;
      // case RouteNames.signUp:
      //   builder = (_) => const SignupView();
      //   break;
      // case RouteNames.otp:
      //   builder = (_) => const OtpScreen();
      //   break;

      // Add other routes here...

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
