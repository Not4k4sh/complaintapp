import 'package:cloud_functions/cloud_functions.dart';

class EmailService {
  final FirebaseFunctions functions = FirebaseFunctions.instance;

  Future<void> sendEmail({
    required String recipientEmail,
    required String subject,
    required String message,
  }) async {
    try {
      HttpsCallable callable = functions.httpsCallable('sendEmail');
      await callable.call({
        'recipientEmail': recipientEmail,
        'subject': subject,
        'message': message,
      });
    } catch (e) {
      print("Error sending email: $e");
    }
  }
}