import 'dart:io';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/routes/routes_name.dart';
import '../module/user/chat/chat_detail_args.dart';

/// Top-level handler required by Firebase for background messages.
/// Runs in a separate isolate; init plugin here and show notification.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final data = message.data;
  if (data.isEmpty) return;
  final conversationId = data['conversationId'] as String?;
  final otherUserId = data['otherUserId'] as String?;
  final otherUserName = data['otherUserName'] as String? ?? 'New message';
  final otherUserPhotoUrl = data['otherUserPhotoUrl'] as String?;
  final body = data['body'] as String? ?? '';
  final title = data['title'] as String? ?? otherUserName;
  if (conversationId == null || conversationId.isEmpty) return;

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
  );
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(initSettings);

  if (Platform.isAndroid) {
    const cid = 'roadlink_chat';
    const cname = 'Chat messages';
    final channel = AndroidNotificationChannel(
      cid,
      cname,
      description: 'New chat messages',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  const androidDetails = AndroidNotificationDetails(
    'roadlink_chat',
    'Chat messages',
    channelDescription: 'New chat messages',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
    icon: '@mipmap/ic_launcher',
  );
  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
  final payload = jsonEncode({
    'conversationId': conversationId,
    'otherUserId': otherUserId ?? '',
    'otherUserName': otherUserName ?? 'Unknown',
    'otherUserPhotoUrl': otherUserPhotoUrl ?? '',
  });
  await plugin.show(
    conversationId.hashCode.abs() % 100000,
    title,
    body,
    details,
    payload: payload,
  );
}

/// FCM and local notifications for chat with professional UX:
/// - Token saved to Firestore for server-side targeting
/// - No notification when user is already in that conversation
/// - Tap opens the specific chat
/// - Dedicated chat notification channel (Android)
class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState>? _navigatorKey;
  static String? _currentConversationId;

  static const String _channelId = 'roadlink_chat';
  static const String _channelName = 'Chat messages';

  /// Call from [ChatDetailView] when entering a conversation so we don't
  /// show a notification for the chat the user is already viewing.
  static void setCurrentConversationId(String? conversationId) {
    _currentConversationId = conversationId;
  }

  static String? get currentConversationId => _currentConversationId;

  /// Initialize FCM and local notifications. Call once after [Firebase.initializeApp].
  static Future<void> init({
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    _navigatorKey = navigatorKey;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (Platform.isAndroid) {
      final channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'New chat messages',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }

    await _requestPermission();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _messaging.getToken().then(_onToken);
    _messaging.onTokenRefresh.listen(_onToken);
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
  }

  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;
    if (Platform.isIOS &&
        settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
    }
  }

  static Future<void> _onToken(String? token) async {
    if (token == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    final data = message.data;
    final notification = message.notification;

    if (data.isEmpty && notification == null) return;

    final conversationId = data['conversationId'] as String?;
    if (conversationId == null || conversationId.isEmpty) return;

    // Don't show notification if user is already in this conversation
    if (_currentConversationId == conversationId) return;

    final title =
        notification?.title ?? data['title'] as String? ?? 'New message';
    final body = notification?.body ?? data['body'] as String? ?? '';
    final otherUserId = data['otherUserId'] as String? ?? '';
    final otherUserName = data['otherUserName'] as String? ?? 'Unknown';
    final otherUserPhotoUrl = data['otherUserPhotoUrl'] as String? ?? '';

    await showLocalNotification(
      id: conversationId.hashCode.abs() % 100000,
      title: title,
      body: body,
      payload: jsonEncode({
        'conversationId': conversationId,
        'otherUserId': otherUserId,
        'otherUserName': otherUserName,
        'otherUserPhotoUrl': otherUserPhotoUrl,
      }),
    );
  }

  static void _onMessageOpenedApp(RemoteMessage message) {
    _navigateFromPayload(message.data);
  }

  static void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      _navigateToChat(
        conversationId: map['conversationId'] as String? ?? '',
        otherUserId: map['otherUserId'] as String? ?? '',
        otherUserName: map['otherUserName'] as String? ?? 'Unknown',
        otherUserPhotoUrl: map['otherUserPhotoUrl'] as String?,
      );
    } catch (_) {}
  }

  static void _navigateFromPayload(Map<String, dynamic> data) {
    final conversationId = data['conversationId'] as String?;
    if (conversationId == null || conversationId.isEmpty) return;
    _navigateToChat(
      conversationId: conversationId,
      otherUserId: data['otherUserId'] as String? ?? '',
      otherUserName: data['otherUserName'] as String? ?? 'Unknown',
      otherUserPhotoUrl: data['otherUserPhotoUrl'] as String?,
    );
  }

  static void _navigateToChat({
    required String conversationId,
    required String otherUserId,
    required String otherUserName,
    String? otherUserPhotoUrl,
  }) {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) return;
    final args = ChatDetailArgs(
      conversationId: conversationId,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      otherUserPhotoUrl: otherUserPhotoUrl,
    );
    navigator.pushNamed(RouteNames.chatDetail, arguments: args);
  }

  /// Handle initial message when app was opened from a notification (terminated).
  static Future<void> handleInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message == null) return;
    _navigateFromPayload(message.data);
  }

  /// Call after login/registration so the new user's device gets its token saved.
  static Future<void> refreshTokenAndSave() async {
    final token = await _messaging.getToken();
    if (token != null) await _onToken(token);
  }

  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'New chat messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _localNotifications.show(id, title, body, details, payload: payload);
  }
}
