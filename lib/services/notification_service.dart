import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<String?> getAccessToken() async {
  final jsonString = await rootBundle.loadString('assets/service_account.json');
  final jsonData = json.decode(jsonString);

  final client = http.Client();
  final credentials = ServiceAccountCredentials.fromJson(jsonData);

  final authClient = await clientViaServiceAccount(
    credentials,
    ['https://www.googleapis.com/auth/firebase.messaging'],
  );

  return authClient.credentials.accessToken.data;
}


 Future<void> sendFCMNotification(String token, String title, String body) async {
  String? accessToken = await getAccessToken();
  if (accessToken == null) return;

  print("fff $token");

  final url = "https://fcm.googleapis.com/v1/projects/hello-b441f/messages:send";
  
  final payload = {
    "message": {
      "token": token, // Receiver's FCM Token
      "notification": {
        "title": title,
        "body": body
      },
      "android": {
        "priority": "high"
      },
      "apns": {
        "payload": {
          "aps": {
            "content-available": 1
          }
        }
      }
    }
  };

  final response = await http.post(
    Uri.parse(url),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $accessToken",
    },
    body: json.encode(payload),
  );

  if (response.statusCode == 200) {
    print("Notification Sent Successfully!");
  } else {
    print("Failed to Send Notification: ${response.body}");
  }
}

