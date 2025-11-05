import 'package:complaint_app/screens/admin_home_screen.dart';
import 'package:complaint_app/screens/signin_screen.dart';
import 'package:complaint_app/screens/user_home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    navigateToAuthCheck();
  }

  // Future<void> navigateToAuthCheck() async {
  //   await Future.delayed(Duration(seconds: 3)); // Delay for 3 seconds
  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(builder: (context) => AuthCheck()),
  //   );
  // }

  void navigateToAuthCheck() {
    Future.delayed(Duration(seconds: 3), () async {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('role');
      if (role == 'user') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UserHomeScreen()),
        );
      } else if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminHomeScreen()),
        );
      } else if (role == 'officer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SignInScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SignInScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator());
  }
}
