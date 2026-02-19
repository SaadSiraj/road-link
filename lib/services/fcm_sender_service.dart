import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

class FCMSenderService {
  // TODO: Replace with your project ID from Firebase Console
  static const String _projectId = 'platechat2';

  // TODO: Securely store or provide the service account JSON.
  // CRITICAL: Storing this in the app is a security risk.
  static const String _serviceAccountJson = '''
{
  "type": "service_account",
  "project_id": "platechat2",
  "private_key_id": "YOUR_PRIVATE_KEY_ID",
  "private_key": "YOUR_PRIVATE_KEY",
  "client_email": "firebase-adminsdk-xxxxx@platechat2.iam.gserviceaccount.com",
  "client_id": "YOUR_CLIENT_ID",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certificates",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-xxxxx%40platechat2.iam.gserviceaccount.com"
}
''';

  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/firebase.messaging',
  ];

  Future<String> _getAccessToken() async {
    final accountCredentials = ServiceAccountCredentials.fromJson(
      _serviceAccountJson,
    );
    final client = await clientViaServiceAccount(accountCredentials, _scopes);
    final accessToken = client.credentials.accessToken.data;
    client.close();
    return accessToken;
  }

  Future<bool> sendNotification({
    required String recipientToken,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      final url =
          'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': recipientToken,
            'notification': {'title': title, 'body': body},
            'data': data,
            'android': {
              'priority': 'high',
              'notification': {
                'channel_id': 'roadlink_chat',
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              },
            },
            'apns': {
              'payload': {
                'aps': {'sound': 'default', 'badge': 1},
              },
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('FCM Send Error: ${response.body}');
        return false;
      }
    } catch (e) {
      print('FCM Service Error: $e');
      return false;
    }
  }
}
