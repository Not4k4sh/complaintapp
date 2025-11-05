

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_home_screen.dart';
import 'admin_home_screen.dart';
import 'officer_home_screen.dart';
import 'signin_screen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  TextEditingController _nameController = TextEditingController();
  String _selectedRole = 'user'; // Default role
  String selectedDepartment = 'Transport Department';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();

      try {
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (_selectedRole == 'officer') {
          // Save user role to Firestore
          await _firestore
              .collection('officers')
              .doc(userCredential.user!.uid)
              .set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'role': _selectedRole,
            'createdAt': FieldValue.serverTimestamp(),
            "department": selectedDepartment,
            "officer_id": userCredential.user!.uid
          });
          await saveFcmToken("officers", userCredential.user!.uid);

          prefs.setString("role", _selectedRole);

          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => OfficerHomeScreen()));
        }

        if (_selectedRole == "user") {
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'role': _selectedRole,
            'createdAt': FieldValue.serverTimestamp(),
            "department": selectedDepartment,
            "user_id": userCredential.user!.uid
          });
          await saveFcmToken("users", userCredential.user!.uid);
          prefs.setString("role", _selectedRole);

          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => UserHomeScreen()));
        }

        if (_selectedRole == "admin") {
          await _firestore
              .collection('admins')
              .doc(userCredential.user!.uid)
              .set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'role': _selectedRole,
            'createdAt': FieldValue.serverTimestamp(),
            "department": selectedDepartment
          });
          prefs.setString("role", _selectedRole);

          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => AdminHomeScreen()));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sign-up failed: ${e.toString()}"),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> saveFcmToken(String collectionName, String docId) async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(docId)
          .update({
        'fcmToken': token,
      });
    }
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
            child: SingleChildScrollView(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0),
                  child: Container(
                    padding: EdgeInsets.all(30),
                    width: MediaQuery.of(context).size.width > 600
                        ? 500
                        : MediaQuery.of(context).size.width * 0.9,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_add_outlined,
                            size: 60,
                            color: Color(0xFF6A11CB),
                          ),
                          SizedBox(height: 15),
                          Text(
                            "Create Account",
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2B2B2B),
                            ),
                          ),
                          Text(
                            "Sign up to get started",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 35),
                          _buildTextField(
                            controller: _nameController,
                            label: "Name",
                            icon: Icons.person,
                            keyboardType: TextInputType.text,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Name is required";
                              }

                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          _buildTextField(
                            controller: _emailController,
                            label: "Email",
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Email is required";
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return "Enter a valid email address";
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          _buildTextField(
                            controller: _passwordController,
                            label: "Password",
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Password is required";
                              }
                              if (value.length < 6) {
                                return "Password must be at least 6 characters";
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            label: "Confirm Password",
                            icon: Icons.lock_outline,
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please confirm your password";
                              }
                              if (value != _passwordController.text) {
                                return "Passwords don't match";
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          _buildRoleSelector(),
                          SizedBox(height: 20),
                          _selectedRole == "officer"
                              ? _buildDepartmentSelector()
                              : SizedBox.shrink(),
                          SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signUp,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Color(0xFF6A11CB),
                                disabledForegroundColor:
                                    Colors.white.withOpacity(0.38),
                                disabledBackgroundColor:
                                    Colors.grey.withOpacity(0.12),
                                elevation: 5,
                                shadowColor: Color(0xFF6A11CB).withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      "SIGN UP",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account?",
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => SignInScreen()),
                                  );
                                },
                                child: Text(
                                  "Sign In",
                                  style: GoogleFonts.poppins(
                                    color: Color(0xFFFF5E98),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: Colors.grey.shade700,
          fontSize: 15,
        ),
        prefixIcon: Icon(
          icon,
          color: Color(0xFF6A11CB),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey.shade100,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF6A11CB), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      ),
    );
  }

  Widget _buildDepartmentSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select Department",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: selectedDepartment,
            items: [
              // DropdownMenuItem(
              //     value: "Health Department", child: Text("Health Department")),
              DropdownMenuItem(
                  value: "Transport Department",
                  child: Text("Transport Department")),
              // DropdownMenuItem(
              //     value: "Public Works Department (PWD)",
              //     child: Text("Public Works Department (PWD)")),
              // DropdownMenuItem(
              //     value: "Municipal Corporation",
              //     child: Text("Municipal Corporation")),
              DropdownMenuItem(
                  value: "Water Authority", child: Text("Water Authority")),
              DropdownMenuItem(
                  value: "Electricity Board", child: Text("Electricity Board")),
            ],
            onChanged: (value) {
              setState(() {
                selectedDepartment = value!;
              });
            },
            validator: (value) => value == null ? "Please select a role" : null,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.assignment_ind_outlined,
                color: Color(0xFF6A11CB),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.transparent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF6A11CB), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            ),
            icon: Icon(
              Icons.arrow_drop_down_circle_outlined,
              color: Color(0xFF6A11CB),
            ),
            dropdownColor: Colors.white,
            isExpanded: true,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select Role",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedRole,
            items: [
              DropdownMenuItem(value: "user", child: Text("User")),
              DropdownMenuItem(value: "officer", child: Text("Officer")),
              DropdownMenuItem(value: "admin", child: Text("Admin")),
            ],
            onChanged: (value) {
              setState(() {
                _selectedRole = value!;
              });
            },
            validator: (value) => value == null ? "Please select a role" : null,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.assignment_ind_outlined,
                color: Color(0xFF6A11CB),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.transparent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF6A11CB), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            ),
            icon: Icon(
              Icons.arrow_drop_down_circle_outlined,
              color: Color(0xFF6A11CB),
            ),
            dropdownColor: Colors.white,
            isExpanded: true,
          ),
        ),
      ],
    );
  }
}
