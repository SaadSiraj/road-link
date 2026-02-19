import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'core/routes/app_router.dart';
import 'core/routes/routes_name.dart';
import 'core/utils/size_utils.dart';
import 'services/chat_service.dart';
import 'services/fcm_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/car_registration_viewmodel.dart';
import 'viewmodels/admin_dashboard_viewmodel.dart';
import 'viewmodels/pending_car_requests_viewmodel.dart';
import 'viewmodels/users_list_viewmodel.dart';
import 'viewmodels/user_detail_viewmodel.dart';
import 'viewmodels/cars_list_viewmodel.dart';
import 'viewmodels/home_dashboard_viewmodel.dart';
import 'viewmodels/chat_home_viewmodel.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp(navigatorKey: navigatorKey));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.navigatorKey});

  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateOnlineStatus(true);
    _initFCM();
  }

  Future<void> _initFCM() async {
    final key = widget.navigatorKey;
    if (key == null) return;
    await FCMService.init(navigatorKey: key);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FCMService.handleInitialMessage();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Set user offline when app closes
    _updateOnlineStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground
        _updateOnlineStatus(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is in background or closed
        _updateOnlineStatus(false);
        break;
    }
  }

  void _updateOnlineStatus(bool isOnline) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _chatService.updateOnlineStatus(isOnline);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>(create: (_) => AuthViewModel()),
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
          create: (_) => HomeDashboardViewModel(),
        ),
        ChangeNotifierProvider<ChatHomeViewModel>(
          create: (_) => ChatHomeViewModel(),
        ),
      ],
      child: Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Platoscan',
            navigatorKey: widget.navigatorKey,
            initialRoute: RouteNames.splash,
            onGenerateRoute: AppRouter.generateRoute,
          );
        },
      ),
    );
  }
}
