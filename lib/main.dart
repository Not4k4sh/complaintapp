import 'package:complaint_app/controller/home_provider.dart';
import 'package:complaint_app/screens/home_screen.dart';
import 'package:complaint_app/screens/register_complaint_screen.dart';
import 'package:complaint_app/screens/splash_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Screens
import 'package:complaint_app/screens/signin_screen.dart';
import 'package:complaint_app/screens/signup_screen.dart';
import 'package:complaint_app/screens/user_home_screen.dart';
import 'package:complaint_app/screens/admin_home_screen.dart';
import 'package:complaint_app/screens/officer_home_screen.dart';

// Services
import 'package:complaint_app/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}

// Local notifications instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Background message handler
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔥 Handling a background message: ${message.notification?.title}');
}

// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   print("Handling background message: ${message.messageId}");
// }

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {


  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (context) => HomeProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Complaint Management System',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: 
        //SignInScreen(),
        // HomeScreen(),
        // UserHomeScreen(),
        // OfficerHomeScreen(),
        SplashScreen(),
        // RegisterComplaintScreen(),
        // routes: {
        //   '/signin': (context) => SignInScreen(),
        //   '/signup': (context) => SignUpScreen(),
        //   '/userHome': (context) => UserHomeScreen(),
        //   '/adminHome': (context) => AdminHomeScreen(),
        //   '/officerHome': (context) => OfficerHomeScreen(),
        // },
      ),
    );
  }
}

// Wrapper to check authentication state
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return SignInScreen(); // No user logged in → Show sign-in page
        }

        return FutureBuilder(
          future: getUserRole(snapshot.data!.uid),
          builder: (context, AsyncSnapshot<String?> roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (roleSnapshot.hasError || !roleSnapshot.hasData) {
              return Scaffold(body: Center(child: Text("Error loading user role.")));
            }

            String role = roleSnapshot.data!;

            if (role == "user") {
              return UserHomeScreen();
            } else if (role == "admin") {
              return AdminHomeScreen();
            } else if (role == "officer") {
              return OfficerHomeScreen();
            } else {
              return SignInScreen();
            }
          },
        );
      },
    );
  }

  Future<String?> getUserRole(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return userDoc['role'];
    } catch (e) {
      print("Error fetching user role: $e");
      return null;
    }
  }
}
