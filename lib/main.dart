import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/routes/app_router.dart';
import 'core/routes/routes_name.dart';
import 'core/utils/size_utils.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/car_registration_viewmodel.dart';
import 'viewmodels/admin_dashboard_viewmodel.dart';
import 'viewmodels/pending_car_requests_viewmodel.dart';
import 'viewmodels/users_list_viewmodel.dart';
import 'viewmodels/user_detail_viewmodel.dart';
import 'viewmodels/cars_list_viewmodel.dart';
import 'viewmodels/home_dashboard_viewmodel.dart';
import 'viewmodels/chat_home_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>(
          create: (_) => AuthViewModel(),
        ),
        ChangeNotifierProvider<CarRegistrationViewModel>(
          create: (_) => CarRegistrationViewModel(),
        ),
        ChangeNotifierProvider<AdminDashboardViewModel>(
          create: (_) => AdminDashboardViewModel(),
        ),
        ChangeNotifierProvider<PendingCarRequestsViewModel>(
          create: (_) => PendingCarRequestsViewModel(),
        ),
        ChangeNotifierProvider<UsersListViewModel>(
          create: (_) => UsersListViewModel(),
        ),
        ChangeNotifierProvider<UserDetailViewModel>(
          create: (_) => UserDetailViewModel(),
        ),
        ChangeNotifierProvider<CarsListViewModel>(
          create: (_) => CarsListViewModel(),
        ),
        ChangeNotifierProvider<HomeDashboardViewModel>(
          create: (_) => HomeDashboardViewModel()..initialize(),
        ),
        ChangeNotifierProvider<ChatHomeViewModel>(
          create: (_) => ChatHomeViewModel(),
        ),
      ],
      child: Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,

            /// 👇 Your existing routing system
            initialRoute: RouteNames.splash,
            onGenerateRoute: AppRouter.generateRoute,
          );
        },
      ),
    );
  }
}
