// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'signin_screen.dart';
// import 'signup_screen.dart';
// import 'user_home_screen.dart';
// import 'admin_home_screen.dart';
// import 'officer_home_screen.dart';

// class HomeScreen extends StatelessWidget {
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.blueAccent, Colors.purpleAccent],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   "Welcome to Complaint Management",
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 SizedBox(height: 30),
//                 _buildButton(context, "Sign In", Icons.login, SignInScreen()),
//                 SizedBox(height: 15),
//                 _buildButton(context, "Sign Up", Icons.app_registration, SignUpScreen()),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildButton(BuildContext context, String text, IconData icon, Widget screen) {
//     return ElevatedButton.icon(
//       style: ElevatedButton.styleFrom(
//         padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(30),
//         ),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//       ),
//       icon: Icon(icon, color: Colors.blueAccent),
//       label: Text(text, style: TextStyle(fontSize: 18)),
//       onPressed: () {
//         Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
//       },
//     );
//   }
// }
   

   import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'signin_screen.dart';
import 'signup_screen.dart';
import 'user_home_screen.dart';
import 'admin_home_screen.dart';
import 'officer_home_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6A11CB),
              Color(0xFF2575FC),
              Color(0xFFFF5E98),
            ],
            stops: [0.1, 0.5, 0.9],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogo(),
                    SizedBox(height: 40),
                    _buildWelcomeText(),
                    SizedBox(height: 50),
                    _buildButton(
                      context, 
                      "Sign In", 
                      Icons.login_rounded, 
                      SignInScreen(),
                      Color(0xFF6A11CB),
                    ),
                    SizedBox(height: 20),
                    _buildButton(
                      context, 
                      "Sign Up", 
                      Icons.person_add_alt_rounded, 
                      SignUpScreen(),
                      Color(0xFFFF5E98),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.support_agent_rounded,
          size: 70,
          color: Color(0xFF6A11CB),
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          "Complaint Management",
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12),
        Text(
          "Efficiently manage and track complaints with our comprehensive system",
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildButton(BuildContext context, String text, IconData icon, Widget screen, Color color) {
    return Container(
      width: MediaQuery.of(context).size.width > 600 ? 400 : double.infinity,
      height: 60,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          foregroundColor: color,
          backgroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        icon: Icon(
          icon,
          color: color,
          size: 24,
        ),
        label: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => screen,
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);
                return SlideTransition(position: offsetAnimation, child: child);
              },
              transitionDuration: Duration(milliseconds: 500),
            ),
          );
        },
      ),
    );
  }
}